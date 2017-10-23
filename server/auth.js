const auth = require('basic-auth');

const admins = {
  'ytxiuxiu@gmail.com': { password: '26981068' },
};


module.exports = function(req, res, next) {
  const user = auth(req);
  if (!user || !admins[user.name] || admins[user.name].password !== user.pass) {
    res.set('WWW-Authenticate', 'Basic realm="Please Login"');
    return res.status(401).send();
  }
  return next();
};