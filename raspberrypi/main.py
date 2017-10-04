# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/
# https://www.youtube.com/watch?v=u6VhRVH3Z6Y
# https://github.com/novaspirit/rpi_zram
# https://pymotw.com/2/socket/tcp.html

import time
import sys
import math
import base64
import numpy as np
import RPi.GPIO as GPIO
import cv2
import json
import socket
import _thread
import datetime
from picamera.array import PiRGBArray
from picamera import PiCamera
from pyimagesearch.transform import four_point_transform


# pins of motion detectors
MOTION_DETECTOR_PINS = [26, 19, 13]
FRAME_RESOLUTION = (640, 480)
LETTER_RESOLUTION = (1440, 1080)
TIME_TO_WAIT_FOR_CAMERA_READY = 0.1
FRAMES_TO_WAIT_TO_CAPTURE_LETTER = 10
MIN_LETTER_AREA = 20000
# SOCKET_HOST = 'socket.lazymails.com'
SOCKET_HOST = '192.168.0.3'
SOCKET_PORT = 6969
SOCKET_END_SYMBOL = '[^END^]'

MAILBOX_ID = '59d34df2b114a0423bcfc7a6'


# initialize the motion detector
GPIO.setmode(GPIO.BCM)
for pin in MOTION_DETECTOR_PINS:
  GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

# initialize socket connection
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

def connect():
  while True:
    try:
      sock.connect((SOCKET_HOST, SOCKET_PORT))
      print('Connected to the server')
      break
    except Exception as e:
      print('Failed to connenct to the server, retry after 3 seconds', e)
      time.sleep(3)

def sendConnectMessage():
  message = {
    'id': MAILBOX_ID,
    'client': 'mailbox'
  }

  # https://stackoverflow.com/questions/11781639/typeerror-str-does-not-support-buffer-interface
  sock.sendall((json.dumps(message) + SOCKET_END_SYMBOL).encode())

def receiveMessage():
  while True:
    try:
      data = ''
      while not data.endswith(SOCKET_END_SYMBOL):
        data += sock.recv(16)
      
      message = json.loads(data)
      print('Received message from the server', message)
    except KeyboardInterrupt:
      sock.close()
      break
    except Exception as e:
      # https://stackoverflow.com/questions/17386487/python-detect-when-a-socket-disconnects-for-any-reason
      print('Failed to receive message from the server:', e)
      connect()

connect()
sendConnectMessage()
try:
  # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread

  _thread.start_new_thread(receiveMessage, ())
except Exception as e:
  print('Unable to start thread for receiving message:', e)

hasMotionDetected = False
lastCenter = None

def analyse():
  """
  analyse frames from camera
  """

  # initialize the camera and grab a reference to the raw camera capture
  camera = PiCamera()
  camera.resolution = FRAME_RESOLUTION
  camera.framerate = 30
  rawCapture = PiRGBArray(camera, size=FRAME_RESOLUTION)

  # allow the camera to warmup
  time.sleep(TIME_TO_WAIT_FOR_CAMERA_READY)

  # initialize the background substractor
  substractor = cv2.bgsegm.createBackgroundSubtractorMOG(200, 5, 0.2)
  
  # capture frames from the camera
  # https://stackoverflow.com/questions/522563/accessing-the-index-in-python-for-loops
  for i, frame in enumerate(camera.capture_continuous(rawCapture, format='bgr', use_video_port=True)):
    minAreaBox = analyseOneFrame(frame, substractor)
    if minAreaBox != None:
      # close the camera
      camera.close()
      time.sleep(TIME_TO_WAIT_FOR_CAMERA_READY)

      takePictureOfRecognisedLetter(minAreaBox)
      upload(convertToBase64('letter.jpg'), convertToBase64('letterbox.jpg'))

      return True

    # clear the stream in preparation for the next frame
    rawCapture.truncate(0)

    # if the `q` key was pressed, break from the loop
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
      break

  camera.close()
  # cv2.destroyAllWindows()
  return False

def convertToBase64(filename):
  """
  convert file to base64
  """

  # https://www.programcreek.com/2013/09/convert-image-to-string-in-python/
  with open(filename, 'rb') as image:
    return base64.b64encode(image.read())

def upload(mail, mailbox):
  
  # https://stackoverflow.com/questions/3316882/how-do-i-get-a-string-format-of-the-current-date-time-in-python
  now = datetime.datetime.now()
  nowStr = now.strftime("%Y-%m-%d %H:%M:%S")

  # https://stackoverflow.com/questions/33269020/convert-byte-string-to-base64-encoded-string-output-not-being-a-byte-string
  message = {
    'mail': mail.decode('utf-8'),
    'mailbox': mailbox.decode('utf-8'),
    'id': MAILBOX_ID,
    'time': nowStr
  }

  sock.sendall((json.dumps(message) + SOCKET_END_SYMBOL).encode())
  

def takePictureOfRecognisedLetter(minAreaBox):
  """
  take a picute of recognised letter
  """

  # http://picamera.readthedocs.io/en/release-1.10/api_camera.html
  camera = PiCamera()
  camera.resolution = LETTER_RESOLUTION
  camera.capture('letterbox.jpg')
  print('A picture of the letterbox has been taken')
  
  letterBox = cv2.imread('letterbox.jpg')

  ratioX = 1.0 * LETTER_RESOLUTION[0] / FRAME_RESOLUTION[0]
  ratioY = 1.0 * LETTER_RESOLUTION[1] / FRAME_RESOLUTION[1]

  points = [
    [minAreaBox[0][0] * ratioX, minAreaBox[0][1] * ratioY],
    [minAreaBox[1][0] * ratioX, minAreaBox[1][1] * ratioY],
    [minAreaBox[2][0] * ratioX, minAreaBox[2][1] * ratioY],
    [minAreaBox[3][0] * ratioX, minAreaBox[3][1] * ratioY]
  ]
  print('Letter croped', points)

  points = np.array(points, dtype = 'float32')

  # apply the four point tranform to obtain a "birds eye view" of the letter
  # http://www.pyimagesearch.com/2014/08/25/4-point-opencv-getperspective-transform-example/
  letter = four_point_transform(letterBox, points)

  # cv2.imshow('Cropped Letter', letter)

  # save the letter
  # http://docs.opencv.org/2.4/doc/tutorials/introduction/load_save_image/load_save_image.html
  cv2.imwrite('letter.jpg', letter);
  print('Letter saved')

  camera.close()

def analyseOneFrame(frame, substractor):
  """
  analyse one frame
  """

  global hasMotionDetected
  global lastCenter

  # grab the raw NumPy array representing the image, then initialize the timestamp
  # and occupied/unoccupied text
  image = frame.array

  # pre-process
  # https://stackoverflow.com/questions/46000390/opencv-backgroundsubtractor-yields-poor-results-on-objects-with-similar-color-as
  # https://stackoverflow.com/questions/15100913/color-space-conversion-with-cv2
  # https://stackoverflow.com/questions/22153271/error-using-cv2-equalizehist
  image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

  image = cv2.equalizeHist(image)
  
  # cv2.imshow('sharped', image)

  fgmask = substractor.apply(image)

  # denoise
  # https://stackoverflow.com/questions/30369031/remove-spurious-small-islands-of-noise-in-an-image-python-opencv
  se1 = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 7))
  mask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, se1)

  se2 = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
  mask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, se2)

  # motion detected
  for pin in MOTION_DETECTOR_PINS:
    if GPIO.input(pin) == 0:
      hasMotionDetected = True
      print('Motion detected')

  if hasMotionDetected:
    nonZeroPixels = cv2.findNonZero(mask)
    if nonZeroPixels != None:
      
      # calculate the boundary of the letter
      # http://opencvpython.blogspot.com.au/2012/06/contours-2-brotherhood.html
      # https://stackoverflow.com/questions/23720875/how-to-draw-a-rectangle-around-a-region-of-interest-in-python
      # http://docs.opencv.org/trunk/d1/d32/tutorial_py_contour_properties.html
      # https://stackoverflow.com/questions/39994831/difference-between-cv2-findnonzero-and-numpy-nonzero
      minAreaRect = cv2.minAreaRect(nonZeroPixels)
      minAreaBox = cv2.boxPoints(minAreaRect)
      minAreaBox = np.int0(minAreaBox)
      area = cv2.contourArea(minAreaBox)

      
      if area > MIN_LETTER_AREA:
        center = (
          (minAreaBox[0][0] + minAreaBox[1][0] + minAreaBox[2][0] + minAreaBox[3][0]) / 4,
          (minAreaBox[0][1] + minAreaBox[1][1] + minAreaBox[2][1] + minAreaBox[3][1]) / 4,
        )
        if lastCenter:
          move = math.sqrt(math.pow(center[0] - lastCenter[0], 2) + math.pow(center[1] - lastCenter[1], 2))
          if move <= 0.01:
            # wait until it is static
            print('Letter recognised', minAreaBox)
            return minAreaBox

        lastCenter = center
      else:
        # ignore if the letter is too small
        print('Ignored, area of the letter ({}) is too small'.format(area))

  # live view
  # cv2.imshow('frame', image)
  # cv2.imshow('mask', fgmask)
  # cv2.imshow('dinoised', mask)

  return None

while True:
  if not analyse():
    break
