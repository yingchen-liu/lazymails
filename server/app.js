// https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
// http://pm2.keymetrics.io/
// https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions

const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const mqtt = require('mqtt')

const index = require('./routes/index');
const users = require('./routes/users');

const google = require('./apis/google');

const app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', index);
app.use('/users', users);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});


// https://github.com/mqttjs/MQTT.js

const client = mqtt.connect('mqtt://192.168.43.154', {
  options: {
    clientId: 'server',
    // set to false to receive QoS 1 and 2 messages while offline
    clean: false
  }
});
const MAILBOX_ID = 'a8hfq3ohc9awr823rhdos9d3fasdf';

client.on('connect', () => {
  console.log('mqtt connected')
  client.subscribe(`mailbox/+`, {
    qos: 2
  });
});

client.on('message', (topic, message) => {
  const info = JSON.parse(message.toString());
  console.log(`received message ${topic}: ${info}`);

  if (topic.indexOf('mailbox') === 0) {
    google.request(info.mail, 
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
});


module.exports = app;
