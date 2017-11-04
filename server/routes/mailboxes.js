/**
 * Mailbox admin page
 */


const express = require('express');
const router = express.Router();
const moment = require('moment');

const socket = require('../socket');
const db = require('../db');
const monk = require('monk');
const mailboxes = db.get('mailboxes');
const users = db.get('users');
const mails = db.get('mails');


/**
 * Get mailbox list
 * 
 * GET /mailboxes/
 */
router.get('/', (req, res, next) => {
  mailboxes.aggregate([
    {
      $lookup: {
        from: 'users',
        localField: '_id',
        foreignField: 'mailbox',
        as: 'users'
      }
    }, {
      $lookup: {
        from: 'mails',
        localField: '_id',
        foreignField: 'mailbox',
        as: 'mails'
      }
    }
  ])
    .then((mailboxes) => {
      res.render('mailboxes', {
        mailboxes
      });
    })
    .catch(next);
});

/**
 * Get mails in a mailbox 
 * 
 * GET /mailboxes/:id/mails
 */
router.get('/:id/mails', (req, res, next) => {
  mails.find({ mailbox: monk.id(req.params.id) })
    .then((mails) => {
      res.render('mails', {
        mails,
        moment
      });
    })
    .catch(next);
});

/** 
 * Add a mailbox 
 * 
 * POST /mailboxes/
 */
router.post('/', (req, res, next) => {
  mailboxes.insert({})
    .then((mailbox) => {
      res.json({
        mailbox
      });
    })
    .catch(next);
});

/** 
 * Update a mailbox 
 * 
 * POST /mailboxes/:id/
 */
router.post('/:id', (req, res, next) => {
  mailboxes.findOneAndUpdate({ _id: req.params.id }, { $set: req.body })
    .then((mailbox) => {
      // notify mailbox settings have been updated if the mailbox is online
      if (socket.clients.mailboxSocksById.hasOwnProperty(mailbox._id)) {
        socket.clients.mailboxSocksById[mailbox._id].sendMessage('update_settings', {
          settings: mailbox.settings
        });
      }

      res.json({
        mailbox
      });
    })
    .catch(next);
});

module.exports = router;
