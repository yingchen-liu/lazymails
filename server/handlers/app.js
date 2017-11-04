const md5 = require('md5');
const moment = require('moment');
const fs = require('fs');
const path = require('path');
const imageSize = require('image-size');

const db = require('../db');
const monk = require('monk');
const mailboxes = db.get('mailboxes');
const mails = db.get('mails');
const users = db.get('users');


const report = (sock, message, clients) => {
  console.log(message)
  const update = {};
  switch (message.issueType) {
    case 'category':
      update.reportedCategory = message.reportedCategory;
      break;
    case 'photo':
      update.reportedPhoto = true;
      break;
    case 'recognition':
      update.reportedRecognition = true;
      break;
    default:
      break;
  }

  console.log(update)
  mails.update({ _id: monk.id(message.id) }, { $set: update })
    .then(() => {
      sock.sendMessage(message.type, {});
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

const register = (sock, message, clients) => {
  users.findOne({ email: message.email })
    .then((user) => {
      if (user) {
        // user already exists
        sock.sendError(message.type, new Error('Email already exists'));
      } else {

        mailboxes.findOne({ _id: monk.id(message.mailbox) })
          .then((mailbox) => {
            console.log(mailbox)
            if (mailbox) {
              users.insert({
                email: message.email,
                password: md5(message.password),
                mailbox: monk.id(message.mailbox)
              })
                .then((user) => {
                  sock.sendMessage(message.type, {});
                })
                .catch((err) => {
                  sock.sendError(message.type, err);
                });
            } else {
              // mailbox not found
              sock.sendError(message.type, new Error('Incorrect mailbox ID'));
            }
          })
          .catch((err) => {
            sock.sendError(message.type, err);
          });

        
      }
    });
};

const connect = (sock, message, clients) => {
  console.log('App connected');

  users.findOne({ email: message.email, password: md5(message.password) }, '-password')
    .then((user) => {
      if (user) {
        if (user.mailbox) {
          mailboxes.findOne({ _id: user.mailbox })
            .then((mailbox) => {
              // save the connection
              clients.addClient(sock, message.email, 'app');

              // get mailbox online status
              if (clients.getSockByClientId(user.mailbox)) {
                mailbox.isOnline = true;
              } else {
                mailbox.isOnline = false;
              }

              sock.sendMessage(message.type, {
                user,
                mailbox
              });
            })
            .catch((err) => {
              sock.sendError(message.type, err);
            });
        } else {
          sock.sendMessage(message.type, {
            user
          });
        }
      } else {
        sock.sendError(message.type, new Error('Incorrect email address or password'));
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

const checkMails = (sock, message, clients) => {
  mails.find({ serverReceivedAt: { $gte: new Date(moment(message.after).toISOString()) } })
    .then((mails) => {
      mails = mails.map((mail) => {
        delete mail.sentTo;

        const mailFilename = path.join(__dirname, '../mails', mail.code + '-mail.png');
        const mailboxFilename = path.join(__dirname, '../mails', mail.code + '-mailbox.png');
        const mailBase64 = fs.readFileSync(mailFilename).toString('base64');
        const mailboxBase64 = fs.readFileSync(mailFilename).toString('base64');

        return {
          info: mail,
          mail: {
            content: mailBase64,
            size: imageSize(mailFilename)
          },
          mailbox: {
            content: mailboxBase64,
            size: imageSize(mailboxFilename)
          }
        };
      });
      sock.sendMessage(message.type, {
        mails
      });
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const updateUser = (sock, message, clients) => {
  delete req.body.email;
  
  
  users.findOneAndUpdate({ email: clients.getClientIdByKey(sock.getClientKey()) }, { $set: message.user })
    .then((user) => {
      delete user.password;

      sock.sendMessage(message.type, {
        user
      });
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const updateMailbox = (sock, message, clients) => {
  // get the mailbox id by user email
  users.findOne({ email: clients.getClientIdByKey(sock.getClientKey()) })
    .then((user) => {
      // update mailbox
      mailboxes.findOneAndUpdate({ _id: user.mailbox }, { $set: message.mailbox })
        .then((mailbox) => {
          // notify mailbox settings have been updated if the mailbox is online
          if (clients.getSockByClientId(user.mailbox)) {
            console.log('update')
            clients.getSockByClientId(user.mailbox).sendMessage('update_settings', {
              settings: mailbox.settings
            });
          }
    
          sock.sendMessage(message.type, {
            mailbox
          });

          // also notify other users who own this mailbox
          users.find({ mailbox: user.mailbox })
            .then((users) => {
              users.map((user) => {
                // online, not me
                if (clients.getSockByClientId(user.email) && clients.getClientIdByKey(sock.getClientKey()) !== user.email) {
                  clients.getSockByClientId(user.email).sendMessage('update_mailbox', {
                    mailbox
                  });
                }
              });
            })
            .catch((err) => {
              sock.sendError(message.type, err);
            });
        })
        .catch((err) => {
          sock.sendError(message.type, err);
        });
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const startLive = (sock, message, clients) => {
  users.findOne({ email: clients.getClientIdByKey(sock.getClientKey()) })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('start_live', {
          email: clients.getClientIdByKey(sock.getClientKey())
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const stopLive = (sock, message, clients) => {
  users.findOne({ email: clients.getClientIdByKey(sock.getClientKey()) })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('stop_live', {
          email: clients.getClientIdByKey(sock.getClientKey())
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const liveHeartbeat = (sock, message, clients) => {
  users.findOne({ email: clients.getClientIdByKey(sock.getClientKey()) })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('live_heartbeat', {
          email: clients.getClientIdByKey(sock.getClientKey())
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

const downloadCategoryIcon = (sock, message, clients) => {

  const iconPath = path.join(__dirname, '../public/images/icons/');
  var found = false;

  //  https://stackoverflow.com/questions/2727167/how-do-you-get-a-list-of-the-names-of-all-files-present-in-a-directory-in-node-j

  fs.readdirSync(iconPath).forEach(file => {
    if (message.category.startsWith(file.split('.')[0])) {
      found = true;

      //  https://stackoverflow.com/questions/24523532/how-do-i-convert-an-image-to-a-base64-encoded-data-url-in-sails-js-or-generally

      var base64 = fs.readFileSync(path.join(iconPath, file), 'base64');
      sock.sendMessage(message.type, {
        category: message.category,
        content: base64
      });
    }
  });

  if (!found) {
    sock.sendError(message.type, new Error('Icon not found'));
  }
};


module.exports = {
  report,
  register,
  connect,
  checkMails,
  updateUser,
  updateMailbox,
  startLive,
  stopLive,
  liveHeartbeat,
  downloadCategoryIcon
};