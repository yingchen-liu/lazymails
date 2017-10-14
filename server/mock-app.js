const net = require('net');

const config = require('./config');
const moment = require('moment');

const SOCKET_END_SYMBOL = '[^END^]';

var client = new net.Socket();
client.connect(config.socket.port, config.socket.host, () => {
  console.log('Connected');
  
  client.write(JSON.stringify({
    end: 'app',
    type: 'connect',
    email: 'ytxiuxiu@gmail.com',
    password: '123456'
  }) + SOCKET_END_SYMBOL);

  // client.write(JSON.stringify({
  //   end: 'app',
  //   type: 'check_mails',
  //   after: '2017-10-09 13:00:00'
  // }) + SOCKET_END_SYMBOL);

  
});

client.on('data', (data) => {
  console.log('Received: ' + data);
  data = data.toString().split(SOCKET_END_SYMBOL).join('');
  message = JSON.parse(data);

  if (message.type === 'connect') {
    client.write(JSON.stringify({
      end: 'app',
      type: 'update_mailbox',
      mailbox: {
        "settings" : {
            "isEnergySavingOn" : false
        }, 
        "names" : [
            {
                "title" : "mr", 
                "firstname" : "yingchen", 
                "lastname" : "liu"
            }
        ], 
        "address" : {
            "unit" : "11", 
            "number" : "919", 
            "road" : "dandenong", 
            "roadType" : "rd", 
            "suburb" : "malvern east", 
            "state" : "vic", 
            "postalCode" : "3145"
        }, 
        "isEnergySavingOn" : false
      }
    }) + SOCKET_END_SYMBOL);
  }
});

client.on('close', () => {
	console.log('Connection closed');
});