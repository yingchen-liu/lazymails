const md5 = require('md5');
const fs = require("fs");
const path = require('path');
const imageSize = require('image-size');
const jimp = require('jimp');
const google = require('../apis/google');

const socket = require('../socket');
const db = require('../db');
const mailboxes = db.get('mailboxes');
const mails = db.get('mails');
const users = db.get('users');

const ROAD_TYPES = {
  rd: ['rd', 'road'],
  st: ['st', 'street']
}

const connect = (sock, message, clients) => {
  console.log('Mailbox connected', message.id);
  
  clients.mailboxes[sock] = {
    id: message.id
  };
  clients.mailboxSocksById[message.id] = sock;

  // update settings
  mailboxes.findOne({ _id: message.id })
    .then((mailbox) => {
      sock.sendMessage('update_settings', {
        settings: mailbox.settings
      });
    })
    .catch((err) => {
      console.error('Failed to get mailbox settings', err);
    });
};

const receiveMail = (sock, message, clients) => {
  mailboxes.findOne({ _id: message.id })
    .then((mailbox) => {
      // get similar road type
      mailbox.address.roadType = ROAD_TYPES[mailbox.address.roadType];

      const code = md5(message.mail.content);
      const mailFilename = path.join(__dirname, '../mails', code + '-mail.png');
      const mailboxFilename = path.join(__dirname, '../mails', code + '-mailbox.png');

      // save images
      // https://stackoverflow.com/questions/6926016/nodejs-saving-a-base64-encoded-image-to-disk
      fs.writeFile(mailFilename, message.mail.content, 'base64', function(err) {
        if (err) return console.error(err);

        fs.writeFile(mailboxFilename, message.mailbox.content, 'base64', function(err) {
          if (err) return console.error(err);
          
          // request orientation
          google.requestOrientation(message.mail.content, (err, rotateDeg) => {
            if (err) return console.error(err);
            console.log('rotateDeg', rotateDeg);

            // https://github.com/oliver-moran/jimp
            jimp.read(mailFilename).then((lenna) => {
              lenna.rotate(rotateDeg)
                .write(mailFilename);

              // request mail info
              mailBase64 = fs.readFileSync(mailFilename).toString('base64');
              google.request(mailBase64, mailbox.names, mailbox.address, (err, result) => {
                if (err) return console.error(err);

                console.log(JSON.stringify(result, null, 2));

                // save to db
                result.mailbox = mailbox._id.toString();
                result.serverReceivedAt = new Date();
                result.mailboxReceivedAt = new Date(message.receivedAt);
                result.sentTo = [];

                mails.insert(result)
                  .then((mail) => {
                    users.find({ mailbox: result.mailbox })
                      .then((users) => {
                        // TODO: notify user for a new mail
                        console.log('Notify new mail', users);
                      })
                      .catch((err) => {
                        console.error(err);
                      });
                  })
                  .catch((err) => {
                    console.error(err);
                  });
              });
            }).catch((err) => {
              console.error(err);
            });
          });
        });
      });
    })
    .catch((err) => {
      console.error('Failed to get mailbox settings', err);
    });
};

module.exports = {
  connect,
  receiveMail
};