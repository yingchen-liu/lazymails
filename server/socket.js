// https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html

const net = require('net');

const google = require('./apis/google');
const config = require('./config');
const db = require('./db');
const mailboxes = db.get('mailboxes');

const SOCKET_END_SYMBOL = '[^END^]';
const ROAD_TYPES = {
  rd: ['rd', 'road'],
  st: ['st', 'street']
}


const clients = {
  mailboxes: {},
  users: {}
};



const processMessage = (sock, message) => {
  if (message.end === 'mailbox') {
    if (message.type === 'connect') {
      console.log('Mailbox connected', message.id);

      clients.mailboxes[sock] = {
        id: message.id
      };

      // update settings
      mailboxes.findOne({ _id: message.id })
        .then((mailbox) => {
          sock.sendMessage('update_settings', {
            settings: mailbox.settings
          });
        })
        .catch((err) => {
          console.err('Failed to get mailbox settings', err);
        });

    } else if (message.type === 'mail') {
      mailboxes.findOne({ _id: message.id })
        .then((mailbox) => {
          // get similar road type
          mailbox.address.roadType = ROAD_TYPES[mailbox.address.roadType];

          google.request(message.mail, mailbox.names, mailbox.address, (err, result) => {
            if (err) return console.error(err);
            console.log(JSON.stringify(result, null, 2));
          });
        })
        .catch((err) => {
          console.err('Failed to get mailbox settings', err);
        });
    }
  }
};

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
      delete clients.mailboxes[sock]
    }
    if (clients.users[sock]) {
      delete clients.users[sock]
    }
  });

  sock.sendMessage = (type, message) => {
    message.type = type;
    sock.write(JSON.stringify(message) + SOCKET_END_SYMBOL);
  };
  
})
  .listen(config.socket.port, config.socket.host);