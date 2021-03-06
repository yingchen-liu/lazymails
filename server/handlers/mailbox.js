/**
 * Mailbox Socket Handler
 */


const md5 = require('md5');
const fs = require("fs");
const path = require('path');
const imageSize = require('image-size');
const jimp = require('jimp');
const google = require('../apis/google');
const moment = require('moment');

const socket = require('../socket');
const db = require('../db');
const monk = require('monk');
const mailboxes = db.get('mailboxes');
const mails = db.get('mails');
const users = db.get('users');

const ROAD_TYPES = {
  'ROAD': ['rd', 'road'],
  'STREET': ['st', 'street']
}


/**
 * Connect a mailbox
 * 
 * {
 *    type: connect
 *    id: <mailbox_id>
 * }
 */
const connect = (sock, message, clients) => {
  console.log('Mailbox connected', message.id);
  
  clients.addClient(sock, message.id, 'mailbox');

  // update settings
  mailboxes.findOne({ _id: monk.id(message.id) })
    .then((mailbox) => {
      sock.sendMessage('connect');
      sock.sendMessage('update_settings', {
        settings: mailbox.settings
      });
    })
    .catch((err) => {
      console.error('Failed to get mailbox settings', err);
    });

  // notify users their that mailbox is online
  users.find({ mailbox: monk.id(message.id) })
    .then((users) => {
      users.map((user) => {
        if (clients.getSockByClientId(user.email)) {
          clients.getSockByClientId(user.email).sendMessage('mailbox_online', {});
        }
      });
    })
    .catch((err) => {
      sock.sendError(err);
    });
};

/** 
 * Receive a mail
 * 
 * {
 *    type: mail
 *    mail: {
 *      content: <mail_in_base64>
 *    },
 *    mailbox: {
 *      content: <mailbox_in_base64>
 *    },
 *    receivedAt: <mailbox_received_datetime>
 * }
 */
const receiveMail = (sock, message, clients) => {
  mailboxes.findOne({ _id: monk.id(message.id) })
    .then((mailbox) => {
      // get similar road type
      mailbox.address.roadType = ROAD_TYPES[mailbox.address.roadType];

      const code = md5(message.mail.content);
      const mailFilename = path.join(__dirname, '../mails', code + '-mail.png');
      const mailboxFilename = path.join(__dirname, '../mails', code + '-mailbox.png');

      // save images
      // https://stackoverflow.com/questions/6926016/nodejs-saving-a-base64-encoded-image-to-disk

      fs.writeFile(mailFilename, message.mail.content, 'base64', (err) => {
        if (err) return console.error(err);

        fs.writeFile(mailboxFilename, message.mailbox.content, 'base64', (err) => {
          if (err) return console.error(err);
          
          // request orientation
          google.requestOrientation(message.mail.content, (err, rotateDeg) => {
            if (err) return console.error(err);
            console.log('rotateDeg', rotateDeg);

            // https://github.com/oliver-moran/jimp

            jimp.read(mailFilename).then((lenna) => {
              lenna.rotate(rotateDeg)
                .write(mailFilename, () => {
                  // request mail info
                  const mailBase64 = fs.readFileSync(mailFilename).toString('base64');
                  google.request(mailBase64, mailbox.names, mailbox.address, (err, result) => {
                    if (err) return console.error(err);

                    console.log(JSON.stringify(result, null, 2));

                    // save to db
                    result.code = code;
                    result.mailbox = mailbox._id;
                    result.serverReceivedAt = moment();
                    result.mailboxReceivedAt = moment(message.receivedAt);
                    result.croppedPoints = message.croppedPoints;
                    result.sentTo = [];

                    mails.insert(result)
                      .then((mail) => {
                        // reply mailbox
                        sock.sendMessage('mail', {
                          mail: {
                            receivedAt: message.receivedAt
                          }
                        });

                        // notify users
                        delete mail.sentTo

                        users.find({ mailbox: monk.id(result.mailbox) })
                          .then((users) => {
                            users.map((user) => {
                              if (clients.getSockByClientId(user.email)) {
                                clients.getSockByClientId(user.email).sendMessage('mail', {
                                  info: mail,
                                  mail: {
                                    content: mailBase64,
                                    size: imageSize(mailFilename)
                                  },
                                  mailbox: {
                                    content: message.mailbox.content,
                                    size: imageSize(mailboxFilename)
                                  }
                                });
                              }
                            });
                          })
                          .catch((err) => {
                            console.error(err);
                          });
                      })
                      .catch((err) => {
                        console.error(err);
                      });
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

/**
 * Live
 * 
 * {
 *    type: live,
 *    mailbox: <mailbox_in_base64>,
 *    time: <current_datetime>
 * }
 */
const live = (sock, message, clients) => {
  if (clients.getSockByClientId(message.email)) {
    clients.getSockByClientId(message.email).sendMessage('live', {
      mailbox: message.mailbox,
      time: message.time
    });
  } else {
    // app is offline, stop live
    sock.sendMessage('stop_live', {
      email: message.email
    });
  }
};


module.exports = {
  connect,
  receiveMail,
  live
};