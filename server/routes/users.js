const express = require('express');
const router = express.Router();

const db = require('../db');
const users = db.get('users');


/* Register an user */
router.post('/', (req, res, next) => {
  users.insert({
    email: req.body.email,
    password: req.body.password
  })
    .then((user) => {
      res.json({
        user
      });
    })
    .catch(next);
});

/* Get an user */
router.get('/:email', (req, res, next) => {
  users.findOne({ email: req.params.email })
    .then((user) => {
      res.json({
        user
      });
    })
    .catch(next);
});

/* Update an user */
router.post('/:email', (req, res, next) => {
  delete req.body.email;

  users.findOneAndUpdate({ email: req.params.email }, { $set: req.body })
    .then((user) => {
      delete user.password;

      res.json({
        user
      });
    })
    .catch(next);
});

module.exports = router;
