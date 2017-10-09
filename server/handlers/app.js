const md5 = require('md5');

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
              clients.apps[sock] = { email: message.email };
              clients.appSocksByEmail[message.email] = sock;

              // get mailbox online status
              if (clients.mailboxSocksById.hasOwnProperty(user.mailbox)) {
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
  mails.find({ serverReceivedAt: { $gte: new Date(message.after) } })
    .then((mails) => {
      sock.sendMessage(message.type, {
        mails
      });
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const updateUserSettings = (sock, message, clients) => {
  delete req.body.email;
  
  users.findOneAndUpdate({ email: clients.apps[sock].email }, { $set: req.body })
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
const updateMailboxSettings = (sock, message, clients) => {
  // get the mailbox id by user email
  users.findOne({ email: clients.apps[sock].email })
    .then((user) => {
      // update mailbox
      mailboxes.findOneAndUpdate({ _id: user.mailbox }, { $set: req.body })
        .then((mailbox) => {
          // notify mailbox settings have been updated if the mailbox is online
          if (clients.mailboxSocksById.hasOwnProperty(mailbox._id)) {
            clients.mailboxSocksById[mailbox._id].sendMessage('update_settings', {
              mailbox
            });
          }
    
          sock.sendMessage(message.type, {
            mailbox
          });

          // also notify other users who own this mailbox
          users.find({ mailbox: user.mailbox })
            .then((users) => {
              user.map((user) => {
                if (clients.userSocksByEmail.hasOwnProperty(user.email)) {
                  clients.userSocksByEmail[user.email].sendMessage('update_settings', {
                    mailbox
                  });
                }
              });
            })
            .catch((err) => {
              sock.sendError(message.type, err);
            });
        })
        .catch(next);
    })
    .catch((err) => {
      sock.sendError(message.type, err);
    });
};

// TODO: to be tested
const startLive = (sock, message, clients) => {
  users.findOne({ email: clients.apps[sock].email })
    .then((user) => {
      if (clients.mailboxSocksById.hasOwnProperty(user.mailbox)) {
        clients.mailboxSocksById[user.mailbox].sendMessage('start_live', {
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
      if (clients.mailboxSocksById.hasOwnProperty(user.mailbox)) {
        clients.mailboxSocksById[user.mailbox].sendMessage('stop_live', {
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
      if (clients.mailboxSocksById.hasOwnProperty(user.mailbox)) {
        clients.mailboxSocksById[user.mailbox].sendMessage('live_heartbeat', {
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
  updateUserSettings,
  updateMailboxSettings,
  startLive,
  stopLive,
  liveHeartbeat
};