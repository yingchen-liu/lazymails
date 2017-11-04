/**
 * User admin page
 */

const express = require('express');
const router = express.Router();

const db = require('../db');
const users = db.get('users');

/**
 * Get user list page
 * 
 * GET /users/
 */
router.get('/', (req, res, next) => {
  users.find({})
    .then((users) => {
      res.render('users', {
        users
      });
    })
    .catch(next);
})

/**
 * Register a user
 * 
 * POST /users/
 */
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

/**
 * Get a user
 * 
 * GET /users/:email/
 */
router.get('/:email', (req, res, next) => {
  users.findOne({ email: req.params.email })
    .then((user) => {
      res.json({
        user
      });
    })
    .catch(next);
});

/**
 * Update a user
 * 
 * POST /users/:email
 */
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
