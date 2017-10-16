const md5 = require('md5');
const moment = require('moment');
const fs = require('fs');
const path = require('path');
const imageSize = require('image-size');

const db = require('../db');
const mailboxes = db.get('mailboxes');
const mails = db.get('mails');
const users = db.get('users');

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
  users.findOne({ email: clients.apps[sock].email })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('start_live', {
          email: clients.apps[sock].email
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const stopLive = (sock, message, clients) => {
  users.findOne({ email: clients.apps[sock].email })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('stop_live', {
          email: clients.apps[sock].email
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const liveHeartbeat = (sock, message, clients) => {
  users.findOne({ email: clients.apps[sock].email })
    .then((user) => {
      if (clients.getSockByClientId(user.mailbox)) {
        clients.getSockByClientId(user.mailbox).sendMessage('live_heartbeat', {
          email: clients.apps[sock].email
        });
      }
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};


module.exports = {
  connect,
  checkMails,
  updateUser,
  updateMailbox,
  startLive,
  stopLive,
  liveHeartbeat
};