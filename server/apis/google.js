// https://cloud.google.com/vision/docs/

const axios = require('axios');
const fuzzyset = require('fuzzyset.js');
const anchorme = require("anchorme").default

const config = require('../config');


const url = `https://vision.googleapis.com/v1/images:annotate?key=${config.apis.google.apiKey}`;
const categories = {
  ads: {
    food: ['dish', 'cuisine', 'food', 'fast food'],
    property: ['house', 'home'],

  },
  letters: {

  }
};

const calculateArea = (vertices) => {
  // http://www.mathopenref.com/coordpolygonarea.html
  return Math.abs(((vertices[0].x * vertices[1].y - vertices[0].y * vertices[1].x) + 
    (vertices[1].x * vertices[2].y - vertices[1].y * vertices[2].x) +
    (vertices[2].x * vertices[3].y - vertices[2].y * vertices[3].x) +
    (vertices[3].x * vertices[0].y - vertices[3].y * vertices[0].x)) / 2);
};

const calculateNameSimilarity = (query, names) => {

  // https://github.com/Glench/fuzzyset.js
  a = FuzzySet([], false);

  names.map((name) => {
    a.add(`${name.title} ${name.firstname} ${name.lastname}`);
    a.add(`${name.title}${name.firstname} ${name.lastname}`);
    a.add(`${name.title} ${name.firstname.substring(0, 1)} ${name.lastname}`);
    a.add(`${name.title}${name.firstname.substring(0, 1)} ${name.lastname}`);
    a.add(`${name.firstname} ${name.lastname}`);
    a.add(`${name.firstname.substring(0, 1)} ${name.lastname}`);
  });

  const results = a.get(query.toLowerCase());
  
  if (results) {
    return results.reduce((similarity, result) => {
      return Math.max(similarity, result[0]);
    }, 0);
  } else {
    return 0;
  }
};

const calculatePostageSimilarity = (query) => {
  a = FuzzySet([], false);

  a.add('postage paid australia');

  const result = a.get(query.toLowerCase());

  if (result) {
    return result[0][0];
  } else {
    return 0;
  }
};

const calculateAddressSimilarity = (query, address) => {
  a = FuzzySet([], false);

  const address1Values = [];
  address.roadType.map((roadType) => {
    address1Values.push(`unit ${address.unit} ${address.number} ${address.road} ${roadType}`);
    address1Values.push(`unit${address.unit} ${address.number} ${address.road} ${roadType}`);
    address1Values.push(`u ${address.unit} ${address.number} ${address.road} ${roadType}`);
    address1Values.push(`u${address.unit} ${address.number} ${address.road} ${roadType}`);
    address1Values.push(`unit ${address.unit}${address.number} ${address.road} ${roadType}`);
    address1Values.push(`unit${address.unit}${address.number} ${address.road} ${roadType}`);
    address1Values.push(`u ${address.unit}${address.number} ${address.road} ${roadType}`);
    address1Values.push(`u${address.unit}${address.number} ${address.road} ${roadType}`);
    address1Values.push(`${address.unit}/${address.number} ${address.road} ${roadType}`);
    address1Values.push(`${address.unit} ${address.number} ${address.road} ${roadType}`);
    address1Values.push(`${address.unit}${address.number} ${address.road} ${roadType}`);
  });

  const address2Values = [];
  address2Values.push(`${address.suburb} ${address.state} ${address.postalCode}`);

  address1Values.map((address1Value) => {
    a.add(address1Value);
    address2Values.map((address2Value) => {
      a.add(address2Value);
      a.add(`${address1Value} ${address2Value}`);
    });
  });

  const results = a.get(query.toLowerCase());
  
  if (results) {
    return results.reduce((similarity, result) => {
      return Math.max(similarity, result[0]);
    }, 0);
  } else {
    return 0;
  }
};

const request = (mail, names, address) => {
  
  // https://cloud.google.com/vision/docs/request
  // https://github.com/mzabriskie/axios
  axios.post(url, {
    requests: [{
      image: {
        content: mail
      },
      features: [{
        type: 'LABEL_DETECTION'
      }, {
        type: 'LOGO_DETECTION'
      }, {
        type: 'DOCUMENT_TEXT_DETECTION'
      }]
    }]
  })
  .then((response) => {
    const result = response.data.responses[0];

    if (result.hasOwnProperty('labelAnnotations')) {
      console.log('labels')
      labels = result.labelAnnotations;
      labels.map((label) => {
        console.log(label);
      });
    }

    if (result.hasOwnProperty('logoAnnotations')) {
      console.log('logos')
      logos = result.logoAnnotations;
      console.log(logos[0].description)
    }

    if (result.hasOwnProperty('fullTextAnnotation')) {
      console.log('fullText')
      fullText = result.fullTextAnnotation;
      console.log(fullText);

      var nameSimilarity = 0.0;
      var addressSimilarity = 0.0;
      var paragraphRates = [];

      console.log('blocks')
      blocks = fullText.pages[0].blocks
      blocks.map((block) => {
        // console.log(block)
        block.paragraphs.map((paragraph) => {

          // console.log(paragraph)
          const wordArray = paragraph.words.reduce((wordArray, word, i) => {
            const wordStr = word.symbols.reduce((wordStr, symbol) => {
              return wordStr + symbol.text + (symbol.property.detectedBreak ? ' ' : '');
            }, '');

            return wordArray.concat(wordStr);
          }, []);
          
          // name similarity
          for (let i = 2; i < wordArray.length; i++) {
            const text = `${wordArray[i - 2]}${wordArray[i - 1]}${wordArray[i]}}`;
            nameSimilarity = Math.max(nameSimilarity, calculateNameSimilarity(text, names));
          }

          const text = wordArray.join('');
          const postageSimilarity = calculatePostageSimilarity(text);
          addressSimilarity = Math.max(addressSimilarity, calculateAddressSimilarity(text, address));

          // filter useless text
          if (postageSimilarity <= 0.5 && // remove postage paid australia
            text.length >= 3 && // remove too short text
            nameSimilarity <= 0.5 &&  // remove name
            addressSimilarity <= 0.5) { // remove address

            console.log(text);

            // http://alexcorvi.github.io/anchorme.js/
            const links = anchorme(text);
            if (links !== text) {
              console.log('> url', links)
            }

            paragraphRates.push({
              text,
              rate: calculateArea(paragraph.boundingBox.vertices) / text.length
            })
          } else {
            console.log('> ignored ', text)
          }
        });
      });

      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
      paragraphRates.sort((a, b) => {
        return b.rate - a.rate; // desc
      });
      for (let i = 0; i < Math.min(3, paragraphRates.length); i++) {
        console.log('> main text', paragraphRates[i].text);
      }

      console.log('> address', addressSimilarity, 'name', nameSimilarity);
    }
    
  })
  .catch((error) => {
    console.error(error);
  });
};


module.exports = {
  request
};