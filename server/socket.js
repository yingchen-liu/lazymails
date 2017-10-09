// https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html

const net = require('net');
const serializeError = require('serialize-error');

const config = require('./config');
const mailbox = require('./handlers/mailbox');
const app = require('./handlers/app');
const db = require('./db');
const users = db.get('users');

const SOCKET_END_SYMBOL = '[^END^]';

const clients = {
  mailboxes: {},
  mailboxSocksById: {},
  apps: {},
  appSocksByEmail: {}
};


const processMessage = (sock, message) => {
  if (message.end === 'mailbox') {
    switch (message.type) {
      case 'connect':
        mailbox.connect(sock, message, clients);
        break;
      case 'mail':
        mailbox.receiveMail(sock, message, clients);
        break;
      case 'live':
        mailbox.live(sock, message, clients);
        break;
    }
  } else if (message.end === 'app') {
    switch (message.type) {
      case 'connect':
        app.connect(sock, message, clients);
        break;
      case 'check_mails':
        app.checkMails(sock, message, clients);
        break;
      case 'update_mailbox_settings':
        app.updateMailboxSettings(sock, message, clients);
        break;
      case 'update_user_settings':
        app.updateUserSettings(sock, message, clients);
        break;
      case 'start_live':
        app.startLive(sock, message, clients);
        break;
      case 'stop_live':
        app.startLive(sock, message, clients);
        break;
      case 'live_heartbeat':
        app.liveHeartbeat(sock, message, clients);
        break;
      default:
        sock.sendError(new Error('Cannot understand the message'));
        break;
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
    
    sock.sendMessage = (type, message) => {
      message.type = type;
      sock.write(JSON.stringify(message) + SOCKET_END_SYMBOL);
    };

    sock.sendError = (type, error) => {
      error = serializeError(error);
      delete error.stack;
      const message = {
        type,
        error
      };
      sock.write(JSON.stringify(message) + SOCKET_END_SYMBOL);
    };

    sock.on('close', (data) => {
      console.log(`Socket client disconnected: ${sock.remoteAddress}:${sock.remotePort}`);
      if (clients.mailboxes[sock]) {
        // notify users their that mailbox is offline
        users.find({ mailbox: clients.mailboxes[sock].id })
          .then((users) => {
            users.map((user) => {
              if (clients.appSocksByEmail.hasOwnProperty(user.email)) {
                clients.appSocksByEmail[user.email].sendMessage('mailbox_offline', {});
              }
            });
          })
          .catch((err) => {
            sock.sendError(err);
          });

        console.log('Mailbox disconnected', clients.mailboxes[sock].id)
        delete clients.mailboxSocksById[clients.mailboxes[sock].id];
        delete clients.mailboxes[sock];

      }
      if (clients.apps[sock]) {
        delete clients.apps[sock];
      }
    });
    
  })
    .listen(config.socket.port, config.socket.host);
};

module.exports = {
  connect,
  clients
};