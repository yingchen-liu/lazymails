/**
 * Authentication
 * 
 * Attributes:
 * 
 * node.js - Basic HTTP authentication with Node and Express 4 - Stack Overflow
 *    https://stackoverflow.com/questions/23616371/basic-http-authentication-with-node-and-express-4
 */


const auth = require('basic-auth');

// TODO: Use database to store users
const admins = {
  'ytxiuxiu@gmail.com': { password: '26981068' },
  'qcai21@student.monash.edu': { password: '27010767' },
};


module.exports = function(req, res, next) {
  if (req.path.startsWith('/admin') || req.path.endsWith('-mail.png') || req.path.endsWith('-mailbox.png')) {
    const user = auth(req);
    if (!user || !admins[user.name] || admins[user.name].password !== user.pass) {
      res.set('WWW-Authenticate', 'Basic realm="Please Login"');
      return res.status(401).send();
    }
  }
  return next();
};