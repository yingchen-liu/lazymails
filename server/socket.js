// https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html

const net = require('net');
const fs = require("fs");
const md5 = require('md5');
const path = require('path');
const imageSize = require('image-size');
const jimp = require('jimp');

const google = require('./apis/google');
const config = require('./config');
const db = require('./db');
const mailboxes = db.get('mailboxes');
const mails = db.get('mails');

const SOCKET_END_SYMBOL = '[^END^]';
const ROAD_TYPES = {
  rd: ['rd', 'road'],
  st: ['st', 'street']
}


const clients = {
  mailboxes: {},
  mailboxSocksById: {},
  users: {}
};



const processMessage = (sock, message) => {
  if (message.end === 'mailbox') {
    if (message.type === 'connect') {
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

    } else if (message.type === 'mail') {
      mailboxes.findOne({ _id: message.id })
        .then((mailbox) => {
          // get similar road type
          mailbox.address.roadType = ROAD_TYPES[mailbox.address.roadType];

          const code = md5(message.mail.content);
          const mailFilename = path.join(__dirname, 'mails', code + '-mail.jpg');
          const mailboxFilename = path.join(__dirname, 'mails', code + '-mailbox.jpg');

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
                    result.mailbox = mailbox._id;
                    result.serverReceivedAt = new Date();
                    result.mailboxReceivedAt = new Date(message.receivedAt);
                    result.sentTo = [];

                    mails.insert(result)
                      .then((mail) => {

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
    }
  }
};


const connect = () => {
  net.createServer((sock) => {
    console.log(`Socket client connected: ${sock.remoteAddress}:${sock.remotePort}`);
    
    var buffer = '';
    sock.on('data', (data) => {
      buffer += data.toString();

      if (buffer.endsWith(SOCKET_END_SYMBOL)) {
        try {
          const message = JSON.parse(buffer.replace(SOCKET_END_SYMBOL, ''));
          console.log(`Received message from ${message.end} [${message.id}]`);
        
          processMessage(sock, message);

        } catch (err) {
          // send error back
          console.log(err);
        }

        buffer = '';
      }
    });
    
    sock.on('close', (data) => {
      console.log(`Socket client disconnected: ${sock.remoteAddress}:${sock.remotePort}`);
      if (clients.mailboxes[sock]) {
        console.log('Mailbox disconnected', clients.mailboxes[sock].id)
        delete clients.mailboxSocksById[clients.mailboxes[sock].id];
        delete clients.mailboxes[sock];
      }
      if (clients.users[sock]) {
        delete clients.users[sock];
      }
    });

    sock.sendMessage = (type, message) => {
      message.type = type;
      sock.write(JSON.stringify(message) + SOCKET_END_SYMBOL);
    };
    
  })
    .listen(config.socket.port, config.socket.host);
};

module.exports = {
  connect,
  clients
};