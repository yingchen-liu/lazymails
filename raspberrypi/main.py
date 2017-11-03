# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/
# https://www.youtube.com/watch?v=u6VhRVH3Z6Y
# https://github.com/novaspirit/rpi_zram
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
  global lastSending
  global secondSendingKeepTheSameFor

  filesConfig = app['config']['recognition']['files']

  while True:
    sending = 0
    filenames = os.listdir()
    for filename in filenames:
      if filename.endswith(filesConfig['mail']):
        sending += 1

    print(sending, secondSendingKeepTheSameFor)
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
  global sending
  
  filesConfig = app['config']['recognition']['files']

  # Send all saved mails  
  # https://stackoverflow.com/questions/3207219/how-do-i-list-all-files-of-a-directory

  filenames = os.listdir()
  for filename in filenames:
    if filename.endswith(filesConfig['mail']):
      print('Sending a mail to the server')

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
  print('Disconnected')

def processMessage(self, message):
  if message['type'] == 'connect':
    global light
    light = Light(app)
    light.connect()
    light.switchOn()
    print('Connected to server')
    
  elif message['type'] == 'update_settings':
    app['settings'] = message['settings']
    print('Setting updated', app['settings'])

  elif message['type'] == 'start_live':
    app['status']['lives'][message['email']] = app['config']['live']['framesKeepAlive']
    print('Start live to', message['email'])

  elif message['type'] == 'live_heartbeat':
    app['status']['lives'][message['email']] = app['config']['live']['framesKeepAlive']
    print('Keep live to', message['email'])

  elif message['type'] == 'stop_live':
    if message['email'] in app['status']['lives']:
      del app['status']['lives'][message['email']]
      print('Stop live to', message['email'])

  elif message['type'] == 'mail':
    filenames = os.listdir()
    for filename in filenames:
      if message['mail']['receivedAt'] in filename:
        os.remove(filename)

def mailDetected(self):
  try:
    # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread

    _thread.start_new_thread(sendAllMails, ())
  except Exception as e:
    print('Unable to start thread for sending mails:', e)

def frameAvailable(self, image, i):
  
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


sock = Network(app, connected, disconnected, processMessage)
sock.connect()
detector = MailDetector(app, mailDetected, frameAvailable)
try:
  # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread
  _thread.start_new_thread(mailSendingMonitor, ())
except Exception as e:
  print('Unable to start thread for mail sending monitor:', e)

while True:
  if app['settings']['isEnergySavingOn']:
    energySavingConfig = app['config']['energySaving']

    now = datetime.datetime.now()
    if now.hour >= energySavingConfig['start'] or now.hour < energySavingConfig['end']:
      continue

  if not detector.analyse():
    break