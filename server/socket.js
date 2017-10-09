// https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html

const net = require('net');
const serializeError = require('serialize-error');

const config = require('./config');
const mailbox = require('./handlers/mailbox');
const app = require('./handlers/app');

const SOCKET_END_SYMBOL = '[^END^]';

const clients = {
  mailboxes: {},
  mailboxSocksById: {},
  apps: {},
  appSocksByEmail: {}
};


const processMessage = (sock, message) => {
  if (message.end === 'mailbox') {
    if (message.type === 'connect') {
      mailbox.connect(sock, message, clients);

    } else if (message.type === 'mail') {
      mailbox.receiveMail(sock, message, clients);

    }
  } else if (message.end === 'app') {
    switch (message.type) {
      case 'connect':
        app.connect(sock, message, clients);
        break;
      case 'check_mails':
        app.checkMails(sock, message, clients);
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

    sock.sendError = (type, error) => {
      error = serializeError(error);
      delete error.stack;
      const message = {
        type,
        error
      };
      sock.write(JSON.stringify(message) + SOCKET_END_SYMBOL);
    };
    
  })
    .listen(config.socket.port, config.socket.host);
};

module.exports = {
  connect,
  clients
};