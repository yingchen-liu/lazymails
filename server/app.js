// https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
// http://pm2.keymetrics.io/
// https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions

const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const basicAuth = require('express-basic-auth');

const index = require('./routes/index');
const users = require('./routes/users');
const mailboxes = require('./routes/mailboxes');

const socket = require('./socket');

const app = express();

// auth
app.use(basicAuth({
  users: { 'admin': '26981068' }
}))

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
app.use(express.static(path.join(__dirname, 'mails')));

app.use('/', index);
app.use('/users', users);
app.use('/mailboxes', mailboxes);

// catch 404 and forward to error handler
app.use((req, res, next) => {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use((err, req, res, next) => {
  console.error(err);

  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  if (req.xhr) {
    res.render('error');
  } else {
    res.json({
      error: err
    });
  }
});

socket.connect();


module.exports = app;
