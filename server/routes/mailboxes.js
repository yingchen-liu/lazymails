const express = require('express');
const router = express.Router();

const socket = require('../socket');
const db = require('../db');
const mailboxes = db.get('mailboxes');


/* Get a mailbox */
router.get('/:id', (req, res, next) => {
  mailboxes.findOne({ _id: req.params.id })
    .then((mailbox) => {
      res.json({
        mailbox
      });
    })
    .catch(next);
});

/* Add a mailbox */
router.post('/', (req, res, next) => {
  mailboxes.insert({})
    .then((mailbox) => {
      res.json({
        mailbox
      });
    })
    .catch(next);
});

/* Update a mailbox */
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
