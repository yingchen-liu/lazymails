// https://cloud.google.com/vision/docs/

const axios = require('axios');
const fuzzyset = require('fuzzyset.js');
const anchorme = require("anchorme").default

const config = require('../config');


const url = `https://vision.googleapis.com/v1/images:annotate?key=${config.apis.google.apiKey}`;
// const url = `https://cxl-services.appspot.com/proxy?url=https%3A%2F%2Fvision.googleapis.com%2Fv1%2Fimages%3Aannotate`
const categories = [{
  name: 'Normal Letters',
  sort: 'a'
}, {
  name: 'ADs',
  sort: 'g'
}, {
  name: 'Not for You',
  sort: 'd'
}, {
  name: 'ADs - Food',
  labels: ['dish', 'cuisine', 'food', 'fast food', 'recipe', 'pizza', 'drink', 'soft drink'],
  sort: 'e'
}, {
  name: 'ADs - Properties',
  labels: ['house', 'home', 'real estate', 'property', 'architecture', 'facade', 'window'],
  mainTexts: ['Woodards'],
  sort: 'f'
}, {
  name: 'Bank Statements',
  logos: ['anz', 'commonwealth'],
  mainTexts: ['ANZ', 'Commonwealth', 'Commonwealth Bank'],
  sort: 'c'
}, {
  name: 'Utility Bills',
  logos: ['vodafone', 'agl', 'tpg'],
  mainTexts: ['AGL', 'Bill', 'Vodafone', 'Origin', 'Optus', 'Telstra', 'iinet', 'TPG'],
  sort: 'b'
}];

const extractPoBox = (fullText) => {
  fullText = fullText.split('\n').join(' ');
  const reg = /po\s*?box.*?(NSW|QLD|SA|TAS|VIC|WA|ACT|JBT|NT)\w*?\s*?\d\d\d\d/gi;
  const match = reg.exec(fullText);
  
  return match ? match[0] : null;
};

const extractReceiver = (fullText) => {
  fullText = fullText.split('\n').join(' ');
  const reg = /((mr|miss|mrs) (.*?)) (unit|u)?\s?\d/gi;
  const match = reg.exec(fullText);
  
  return match ? match[1] : null;
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
  a.add('postage paid australia priority');

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

const request = (mailBase64, names, address, callback) => {
  axios.post(url, {
    requests: [{
      image: {
        content: mailBase64
      },
      features: [
        {type: 'TYPE_UNSPECIFIED', maxResults: 50},
        {type: 'LOGO_DETECTION', maxResults: 50},
        {type: 'LABEL_DETECTION', maxResults: 50},
        {type: 'IMAGE_PROPERTIES', maxResults: 50},
        {type: 'TEXT_DETECTION'}
      ],
      imageContext: {
        languageHints: ['en']
      }
    }]
  })
  .then((response) => {
    const _result = response.data.responses[0];
    const result = {
      labels: [],
      logos: [],
      category: {},
      title: {},
      mainText: [],
      text: '',
      urls: []
    };

    if (_result.hasOwnProperty('labelAnnotations')) {
      const labels = _result.labelAnnotations;
      labels.map((label) => {
        result.labels.push({
          desc: label.description,
          score: label.score
        });

        // find out category
        categories.map((category) => {
          if (category.labels && category.labels.indexOf(label.description) >= 0) {
            if (!result.category[category.name]) {
              result.category[category.name] = 0;
            }
            result.category[category.name] += label.score;
          }
        });
      });
    }

    if (_result.hasOwnProperty('logoAnnotations')) {
      const logos = _result.logoAnnotations;
      logos.map((logo) => {
        result.logos.push({
          desc: logo.description,
          score: logo.score
        });

        const logoDesc = logo.description.toLowerCase();
        const logoScore = logo.score;

        // title
        if (!result.title[logo.description]) {
          result.title[logo.description] = 0;
        }
        result.title[logo.description] += logoScore;


        // find out category
        categories.map((category) => {
          if (category.logos) {
            for (let i = 0; i < category.logos.length; i++) {
              const _logo = category.logos[i];

              if (logoDesc.indexOf(_logo) >= 0) {
                if (!result.category[category.name]) {
                  result.category[category.name] = 0;
                }
                
                result.category[category.name] += logoScore;
                
              }
            }
          }
        });
      });
    }

    if (_result.hasOwnProperty('fullTextAnnotation')) {
      const fullText = _result.fullTextAnnotation;

      var nameSimilarity = 0.0;
      var addressSimilarity = 0.0;
      var paragraphRates = [];

      // for detecting image orientation
      var lastX = [];
      var lastY = [];
      const orientationInfo = [{
        type: 'xIncrease',
        n: 0
      }, {
        type: 'xDecrease',
        n: 0
      }, {
        type: 'yIncrease',
        n: 0
      }, {
        type: 'yDecrease',
        n: 0
      }];

      const blocks = fullText.pages[0].blocks
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
            text.length >= 3 /*&& // remove too short text
            nameSimilarity <= 0.5 &&  // remove name
            addressSimilarity <= 0.5*/) { // remove address

            // console.log(text);
            const box = paragraph.boundingBox.vertices;
            const center = {
              x: (box[0].x + box[1].x + box[2].x + box[3].x) / 4,
              y: (box[0].y + box[1].y + box[2].y + box[3].y) / 4
            };
            
            // for detecting image orientation
            if (lastX.length !== 0) {
              box.map((box, i) => {
                if (box.x - lastX[i] >= 0) {
                  orientationInfo[0].n++;
                } else {
                  orientationInfo[1].n++;
                }

                if (box.y - lastY[i] >= 0) {
                  orientationInfo[2].n++;
                } else {
                  orientationInfo[3].n++;
                }
              });
            }
            box.map((box, i) => {
              lastX[i] = box.x;
              lastY[i] = box.y;
            });
            

            result.text += text + '\n';

            // http://alexcorvi.github.io/anchorme.js/
            const link = anchorme(text);
            if (link !== text) {
              const reg = /href="(.*?)"/g

              var match = reg.exec(link);
              while (match != null) {
                result.urls.push(match[1]);
                match = reg.exec(link);
              }
            }

            paragraphRates.push({
              text,
              rate: calculateArea(paragraph.boundingBox.vertices) / text.length
            })
          } else {
            // console.log('> ignored ', text)
          }
        });
      });

      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
      paragraphRates.sort((a, b) => {
        return b.rate - a.rate; // desc
      });
      for (let i = 0; i < Math.min(3, paragraphRates.length); i++) {
        result.mainText.push(paragraphRates[i]);
        const mainText = paragraphRates[i].text.toLowerCase();
        
        // find out category
        categories.map((category) => {
          if (category.mainTexts) {
            for (let i = 0; i < category.mainTexts.length; i++) {
              const _mainText = category.mainTexts[i].toLowerCase();

              if (mainText.indexOf(_mainText) >= 0) {
                if (!result.category[category.name]) {
                  result.category[category.name] = 0;
                }
                if (!result.title[category.mainTexts[i]]) {
                  result.title[category.mainTexts[i]] = 0;
                }
                result.category[category.name] += 0.3;
                result.title[category.mainTexts[i]] += 0.3;
              }
            }
          }
        });
      }

      // name and address
      result.addressSimilarity = addressSimilarity;
      result.nameSimilarity = nameSimilarity;

      if (addressSimilarity >= 0.5 || nameSimilarity >= 0.5) {
        if (result.category['Bank Statements']) {
          result.category['Bank Statements'] += 3;
        } else if (result.category['Utility Bills']) {
          result.category['Utility Bills'] += 3;
        } else {
          result.category['Normal Letters'] += 4;
        }
      }

      // po box
      result.poBox = extractPoBox(result.text);
      result.receiver = extractReceiver(result.text);
      if (result.receiver) {
        result.title[result.receiver] = 0.1;
      }
    }

    // Generate categories
    result.categories = [];
    for (category in result.category) {
      result.categories.push({
        name: category,
        score: result.category[category]
      });
    }

    if (result.poBox || result.receiver) {
      result.categories.push({
        name: 'Normal Letters',
        score: 0.1
      });
    }
    if (result.categories.length == 0) {
      result.categories.push({
        name: 'ADs',
        score: 1
      });
    }
    if (result.nameSimilarity < 0.5 && result.receiver) {
      result.categories.push({
        name: 'Not for You',
        score: 10
      });
      result.categories.push({
        name: result.receiver,
        score: 10
      });
    }

    // add sort
    result.categories.map((category) => {
      for (var i = 0; i < categories.length; i++) {
        const _category = categories[i];
        if (_category.name === category.name) {
          category.sort = _category.sort;
          break;
        }
      }

      if (!category.sort) {
        category.sort = 'zzz';
      }
    });

    console.log(result.categories)

    result.categories.sort((a, b) => {
      return b.score - a.score; // desc
    });

    // Generate titles
    result.titles = [];
    for (title in result.title) {
      result.titles.push({
        name: title,
        score: result.title[title]
      });
    }
    if (result.titles.length == 0) {
      result.titles.push({
        name: result.categories[0].name.startsWith('ADs') ? 'Advertisement' : 'Mail',
        score: 1
      });
    }
    result.titles.sort((a, b) => {
      return b.score - a.score; // desc
    });

    delete result.category;
    delete result.title;

    return callback(null, result);
  })
  .catch((error) => {
    console.error(error);
    if (error.response) {
      return callback(error.response.data.error);
    } else {
      return callback(error.message);
    }
  });
};

const requestOrientation = (mailBase64, callback) => {

  // https://cloud.google.com/vision/docs/request
  // https://github.com/mzabriskie/axios
  axios.post(url, {
    requests: [{
      image: {
        content: mailBase64
      },
      features: [
        {type: 'TEXT_DETECTION'}
      ],
      imageContext: {
        languageHints: ['en']
      }
    }]
  })
  .then((response) => {
    const _result = response.data.responses[0];

    if (_result.hasOwnProperty('fullTextAnnotation')) {
      const fullText = _result.fullTextAnnotation;

      // for detecting image orientation
      var lastX = [];
      var lastY = [];
      const orientationInfo = [{
        type: 'xIncrease',
        n: 0
      }, {
        type: 'xDecrease',
        n: 0
      }, {
        type: 'yIncrease',
        n: 0
      }, {
        type: 'yDecrease',
        n: 0
      }];

      const blocks = fullText.pages[0].blocks
      blocks.map((block) => {
        block.paragraphs.map((paragraph) => {
          const box = paragraph.boundingBox.vertices;
          
          // for detecting image orientation
          if (lastX.length !== 0) {
            box.map((box, i) => {
              if (box.x - lastX[i] >= 0) {
                orientationInfo[0].n++;
              } else {
                orientationInfo[1].n++;
              }

              if (box.y - lastY[i] >= 0) {
                orientationInfo[2].n++;
              } else {
                orientationInfo[3].n++;
              }
            });
          }
          box.map((box, i) => {
            lastX[i] = box.x;
            lastY[i] = box.y;
          });
        });
      });

      // orientation
      var rotateDeg = 0;
      orientationInfo.sort((a, b) => {
        return b.n - a.n;
      });

      switch (orientationInfo[0].type) {
        case 'yIncrease':
          rotateDeg = 0;
          break;
        case 'xIncrease':
          rotateDeg = 90;
          break;
        case 'yDecrease':
          rotateDeg = 180;
          break;
        case 'xDecrease':
          rotateDeg = 270;
          break;
        default:
          rotateDeg = 0;
          break;
      }

      return callback(null, rotateDeg);
    }
    
    return callback(null, 0);
  })
  .catch((error) => {
    console.error(error);
    if (error.response) {
      return callback(error.response.data.error);
    } else {
      return callback(error.message);
    }
  });
};


module.exports = {
  requestOrientation,
  request
};