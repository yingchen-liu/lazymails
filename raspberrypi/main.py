#
# LazyMails Mailbox-End Application
#
# For mails extraction and sending them to the server
#


# Attributes:
# 
# Install OpenCV and Python on your Raspberry Pi 2 and B+ - PyImageSearch
# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# 
# Accessing the Raspberry Pi Camera with OpenCV and Python - PyImageSearch
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
#
# Install guide: Raspberry Pi 3 + Raspbian Jessie + OpenCV 3 - PyImageSearch
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/
#
# Easy Raspberry Pi Camera refocusing - YouTube
# https://www.youtube.com/watch?v=u6VhRVH3Z6Y
#
# novaspirit/rpi_zram: script to enable zram for raspberry pi
# https://github.com/novaspirit/rpi_zram
#
# TCP/IP Client and Server - Python Module of the Week
# https://pymotw.com/2/socket/tcp.html

import time
import datetime
import os
import _thread
import cv2
from PIL import Image

from classes.network import Network
from classes.light import Light
from classes.maildetector import MailDetector
from classes.utils import toBase64


# App settings
app = {
  'config': {
    'network': {
      'host': 'socket.lazymails.com',
      # 'host': '192.168.0.3',
      'port': 6969,
      'endSymbol': '[^END^]'
    },
    'energySaving': {
      'start': 19,
      'end': 7
    },
    'live': {
      'framesKeepAlive': 10,
      'sendPerFrames': 1,
      'file': 'live.jpg'
    },
    'mailbox': {
      'id': '59e1e68a00d5f221145ba626'
    },
    'recognition': {
      'mailArea': {
        'min': 20000,
        'max': 250000
      },
      'motionDetector': {
        'pins': [26, 19, 13]
      },
      'camera': {
        'frameResolution': (640, 480),
        'mailResolution': (1440, 1080),
        'timeToWaitForReady': 2,
        'framesToWaitToCaptureMail': 20
      },
      'files': {
        'mail': 'mail.jpg',
        'mailbox': 'mailbox.jpg'
      }
    }
  },
  'settings': {
    'isEnergySavingOn': False
  },
  'status': {
    'lives': {}
  }
}


light = None
sock = None
secondSendingKeepTheSameFor = 0
lastSending = 0


def mailSendingMonitor():
  """
  This function runs as a thread itself, it is used to monitor the process of sending a mail
  to the server, it ensures the mail can be sent successuflly, otherwiese, it will send it again.
  """
  global lastSending
  global secondSendingKeepTheSameFor

  filesConfig = app['config']['recognition']['files']

  while True:
    sending = 0

    # Looking for unsent mails in the folder
    filenames = os.listdir()
    for filename in filenames:
      if filename.endswith(filesConfig['mail']):
        sending += 1

    if sending > 0:
      print('mails:', sending, 'time:', secondSendingKeepTheSameFor)

    if sending != 0 and secondSendingKeepTheSameFor >= 60:
      secondSendingKeepTheSameFor = 0
      print('Spending too long to send a mail to the server')
    
    if sending != 0 and sending == lastSending:
      secondSendingKeepTheSameFor += 1

    if sending != lastSending:
      secondSendingKeepTheSameFor = 0
    
    lastSending = sending
    time.sleep(1)

def sendAllMails():
  """
  Get and send all unsent mails to the server
  """
  global sending
  
  filesConfig = app['config']['recognition']['files']

  # Send all saved mails  
  # https://stackoverflow.com/questions/3207219/how-do-i-list-all-files-of-a-directory

  filenames = os.listdir()
  for filename in filenames:
    if filename.endswith(filesConfig['mail']):
      print('Sending a mail to the server')

      # 7.1. string — Common string operations — Python 2.7.14 documentation
      # https://docs.python.org/2/library/string.html

      # get received time
      timeStr = filename.split('_')[0]

      # get croped points
      cropStr = filename.split('_')[1]
      cropPoints = []
      cropPointStrs = cropStr.split('),(')
      for cropPointStr in cropPointStrs:
        pointStr = cropPointStr.replace('(', '').replace(')', '').split(',')
        cropPoints.append((float(pointStr[0]), float(pointStr[1])))

      # mail for sending
      message = {
        'type': 'mail',
        'end': 'mailbox',
        'mail': {
          'content': toBase64(filename).decode('utf-8')
        },
        'mailbox': {
          'content': toBase64(timeStr + '_' + filesConfig['mailbox']).decode('utf-8')
        },
        'id': app['config']['mailbox']['id'],
        'croppedPoints': cropPoints,
        'receivedAt': timeStr
      }

      sock.sendMessage(message)
      print('Sent a mail to the server')
      time.sleep(2)

      

def connected(self):
  """
  Callback function called once it connected to the server
  """
  message = {
    'type': 'connect',
    'id': app['config']['mailbox']['id'],
    'end': 'mailbox'
  }
  
  self.sendMessage(message)
  
  try:
    # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread

    _thread.start_new_thread(sendAllMails, ())
  except Exception as e:
    print('Unable to start thread for sending mails:', e)

def disconnected(self):
  """
  Callback function called once it disconnected to the server
  """
  print('Disconnected')

def processMessage(self, message):
  """
  Process a message sent from the server
  """
  try:
    # Connection
    if message['type'] == 'connect':
      global light
      light = Light(app)
      light.connect()
      light.switchOn()
      print('Connected to server')
      
    # Update mailbox settings
    elif message['type'] == 'update_settings':
      app['settings'] = message['settings']
      print('Setting updated', app['settings'])

    # Start live to a users
    elif message['type'] == 'start_live':
      app['status']['lives'][message['email']] = app['config']['live']['framesKeepAlive']
      print('Start live to', message['email'])

    # Live heartbeat
    elif message['type'] == 'live_heartbeat':
      app['status']['lives'][message['email']] = app['config']['live']['framesKeepAlive']
      print('Keep live to', message['email'])

    # Stop live to a user
    elif message['type'] == 'stop_live':
      if message['email'] in app['status']['lives']:
        del app['status']['lives'][message['email']]
        print('Stop live to', message['email'])

    # Mail has been received by the server
    elif message['type'] == 'mail':
      filenames = os.listdir()
      for filename in filenames:
        if message['mail']['receivedAt'] in filename:
          os.remove(filename)

  except Exception as e:
    print('Unable to process message:', e)

def mailDetected(self):
  """
  Callback function called once a mail has been detected in the mailbox
  """
  try:
    # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread

    _thread.start_new_thread(sendAllMails, ())
  except Exception as e:
    print('Unable to start thread for sending mails:', e)

def frameAvailable(self, image, i):
  """
  Callback function called once a frame is available from the camera
  """
  lives = app['status']['lives']
  liveConfig = app['config']['live']

  # https://stackoverflow.com/questions/17682103/how-can-i-send-cv2-frames-to-a-browser
  if len(lives) > 0:
    cv2.imwrite(liveConfig['file'], image)
    jpg = Image.open(liveConfig['file'])
    jpg.save(liveConfig['file'], quality=40, optimize=True)
    encode = toBase64(liveConfig['file'])

    for email in list(lives.keys()):
      framesLeft = lives[email]

      if framesLeft > 0:
        # only send per n frames or the first frame when live started
        # print(i)
        if i % liveConfig['sendPerFrames'] == 0 or framesLeft == liveConfig['sendPerFrames']:
          print('live to {}, {} remains'.format(email, lives[email]))

          now = datetime.datetime.now()
          nowStr = now.strftime("%Y-%m-%d %H:%M:%S")

          message = {
            'type': 'live',
            'mailbox': {
              'content': encode.decode('utf-8')
            },
            'time': nowStr,
            'email': email,
            'end': 'mailbox'
          }

          sock.sendMessage(message)
          lives[email] -= 1
      else:
        del lives[email]



# Initialize the connection
sock = Network(app, connected, disconnected, processMessage)
sock.connect()

# Initialize the mail detector
detector = MailDetector(app, mailDetected, frameAvailable)

# Initialize the mail sending monitor
try:
  # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread
  _thread.start_new_thread(mailSendingMonitor, ())
except Exception as e:
  print('Unable to start thread for mail sending monitor:', e)

# Initialize the heartbeat sender
try:
  _thread.start_new_thread(sock.heartbeat, ())
except Exception as e:
  print('Unable to start thread for sending heartbeat:', e)

# Main loop
while True:
  if app['settings']['isEnergySavingOn']:
    energySavingConfig = app['config']['energySaving']

    now = datetime.datetime.now()
    if now.hour >= energySavingConfig['start'] or now.hour < energySavingConfig['end']:
      continue

  if not detector.analyse():
    break