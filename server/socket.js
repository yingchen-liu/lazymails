// https://www.hacksparrow.com/tcp-socket-programming-in-node-js.html

const net = require('net');

const google = require('./apis/google');
const config = require('./config');

const SOCKET_END_SYMBOL = '[^END^]';


net.createServer((sock) => {
  console.log(`Socket client connected: ${sock.remoteAddress}:${sock.remotePort}`);
  
  var buffer = '';
  sock.on('data', (data) => {
    buffer += data.toString();

    if (buffer.endsWith(SOCKET_END_SYMBOL)) {
      try {
        const message = JSON.parse(buffer.replace(SOCKET_END_SYMBOL, ''));
        console.log(`received message from ${message.id}`);
      
        if (message.hasOwnProperty('mail')) {
          google.request(message.mail, 
            [{
              title: 'mr',
              firstname: 'yingchen',
              lastname: 'liu'
            }], 
            {
              unit: '11',
              number: '919',
              road: 'dandenong',
              roadType: ['rd', 'road'],
              suburb: 'malvern east',
              state: 'vic',
              postalCode: '3145'
            });
        }

      } catch (err) {
        // send error back
        console.log(err);
      }

      buffer = '';
    }
  });
  
  sock.on('close', (data) => {
    console.log(`Socket client disconnected: ${sock.remoteAddress}:${sock.remotePort}`);
  });
  
})
  .listen(config.socket.port, config.socket.host);