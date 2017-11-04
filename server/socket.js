/**
 * Network Handler
 *
 * Attributes: 
 * 
 * TCP Socket Programming in Node.js
 *    https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html
 */
const net = require('net');
const serializeError = require('serialize-error');

const config = require('./config');
const mailbox = require('./handlers/mailbox');
const app = require('./handlers/app');
const db = require('./db');
const users = db.get('users');

const SOCKET_END_SYMBOL = '[^END^]';

const clients = {
  idsByKey: {},
  socksByKey: {},
  socksById: {},
  mailboxKeys: [],
  appKeys: [],

  addClient: (sock, id, type) => {
    clients.idsByKey[sock.getClientKey()] = id;
    clients.socksByKey[sock.getClientKey()] = sock;
    clients.socksById[id] = sock;
    if (type === 'mailbox') {
      clients.mailboxKeys.push(sock.getClientKey());
    } else if (type === 'app') {
      clients.appKeys.push(sock.getClientKey());
    }
  },
  getClientIdByKey: (key) => {
    return clients.idsByKey[key];
  },
  getSockByClientKey: (key) => {
    return clients.socksByKey[key];
  },
  getSockByClientId: (id) => {
    return clients.socksById[id];
  },
  isMailbox: (key) => {
    return clients.mailboxKeys.indexOf(key) >= 0;
  },
  isApp: (key) => {
    return clients.appKeys.indexOf(key) >= 0;
  },
  removeClient: (key) => {
    delete clients.socksById[clients.idsByKey[key]];
    delete clients.idsByKey[key];
    delete clients.socksByKey[key];
    delete clients.mailboxKeys[key];
    delete clients.appKeys[key];
  }
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
      case 'heartbeat':
        sock.sendMessage(message.type, {});
        break;
    }
  } else if (message.end === 'app') {
    switch (message.type) {
      case 'register':
        app.register(sock, message, clients);
        break;
      case 'connect':
        app.connect(sock, message, clients);
        break;
      case 'check_mails':
        app.checkMails(sock, message, clients);
        break;
      case 'update_mailbox':
        app.updateMailbox(sock, message, clients);
        break;
      case 'update_user':
        app.updateUser(sock, message, clients);
        break;
      case 'start_live':
        app.startLive(sock, message, clients);
        break;
      case 'stop_live':
        app.stopLive(sock, message, clients);
        break;
      case 'live_heartbeat':
        app.liveHeartbeat(sock, message, clients);
        break;
      case 'download_category_icon':
        app.downloadCategoryIcon(sock, message, clients);
        break;
      case 'report':
        app.report(sock, message, clients);
        break;
      case 'heartbeat':
        sock.sendMessage(message.type, {});
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

      if (buffer.indexOf(SOCKET_END_SYMBOL) >= 0) {
        const parts = buffer.split(SOCKET_END_SYMBOL);
        
        for (let i = 0; i < parts.length - 1; i++) {
          const part = parts[i];

          try {
            const message = JSON.parse(part);
            console.log(`Received message from ${message.end} [${clients.getClientIdByKey(sock.getClientKey())}]`);
          
            processMessage(sock, message);
  
          } catch (err) {
            console.log(err);

            sock.sendError('error', new Error('Message cannot be understood.'));
          }
        }

        buffer = parts[parts.length - 1];
      }
    });

    sock.getClientKey = () => {
      return sock.remoteAddress + ':' + sock.remotePort;
    },
    
    sock.sendMessage = (type, message) => {
      message = message ? message : {};
      
      message.type = type;
      console.log('sent', message.type)
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

    sock.on('error', (err) => {
      console.log('Socket error', err);
    });

    sock.on('close', (data) => {
      var clientId = clients.getClientIdByKey(sock.getClientKey());

      console.log(`Socket client disconnected: ${sock.remoteAddress}:${sock.remotePort}`);
      if (clients.isMailbox(sock.getClientKey())) {
        // notify users their that mailbox is offline
        users.find({ mailbox: clientId })
          .then((users) => {
            users.map((user) => {
              if (clients.getSockByClientId(user.email)) {
                clients.getSockByClientId(user.email).sendMessage('mailbox_offline', {});
              }
            });
          })
          .catch((err) => {
            sock.sendError(err);
          });

        console.log('Mailbox disconnected', clientId)
        clients.removeClient(sock.getClientKey());

      } else if (clients.isApp(sock.getClientKey())) {
        console.log('App disconnected', clientId)
        clients.removeClient(sock.getClientKey());
      }
    });
    
  })
    .listen(config.socket.port, config.socket.host);
};

module.exports = {
  connect,
  clients
};