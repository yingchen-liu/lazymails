# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/
# https://www.youtube.com/watch?v=u6VhRVH3Z6Y
# https://github.com/novaspirit/rpi_zram

import time
import base64
import numpy as np
import RPi.GPIO as GPIO
import cv2
import json
import paho.mqtt.client as mqtt
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
MQTT_SERVER = 'localhost'
MAILBOX_ID = 'a8hfq3ohc9awr823rhdos9d3fasdf'
TOPIC_SUBSCRIBE = 'server/{}'
TOPIC_PUBLISH = 'mailbox/{}'

# initialize the motion detector
GPIO.setmode(GPIO.BCM)
for pin in MOTION_DETECTOR_PINS:
  GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

# initialize mqtt
def onMqttConnect(client, userdata, flags, rc):
  """
  on connected to the mqtt broker
  """

  print('connected to the mqtt broker')

  # https://pypi.python.org/pypi/paho-mqtt/1.1

  # subscribing in on_connect() means that if we lose the connection and
  # reconnect then subscriptions will be renewed.
  topic = TOPIC_SUBSCRIBE.format(MAILBOX_ID)
  client.subscribe(topic, qos=2)
  print('subscribed to {}'.format(topic))

def onMqttMessage(client, userdata, msg):
  """
  on receive mqtt message
  """

  print('received mqtt message {}: {}'.format(msg.topic, str(msg.payload)))

def onMqttDisconnect(client, userdata, rc):
  """
  on disconnected to mqtt
  """

  if rc != 0:
    print('unexpected disconnected to the mqtt broker')

def onMqttLog(client, userdata, level, buf):
  """
  on mqtt log
  """

  print('{}: {}'.format(level, buf))

client = mqtt.Client(client_id=MAILBOX_ID, clean_session=False)
client.on_connect = onMqttConnect
client.on_message = onMqttMessage
client.on_disconnect = onMqttDisconnect
client.on_log = onMqttLog
client.connect(MQTT_SERVER, 1883, 60)

hasMotionDetected = False
numberOfFramesAfterMotionHasDetected = 0

def analyse():
  """
  analyse frames from camera
  """

  # initialize the camera and grab a reference to the raw camera capture
  camera = PiCamera()
  camera.resolution = FRAME_RESOLUTION
  camera.framerate = 20
  rawCapture = PiRGBArray(camera, size=FRAME_RESOLUTION)

  # allow the camera to warmup
  time.sleep(TIME_TO_WAIT_FOR_CAMERA_READY)

  # initialize the background substractor
  substractor = cv2.bgsegm.createBackgroundSubtractorMOG()
  
  # capture frames from the camera
  for frame in camera.capture_continuous(rawCapture, format='bgr', use_video_port=True):
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
  cv2.destroyAllWindows()
  client.loop_stop()
  client.disconnect()
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
  payload = {
    'mail': mail.decode('utf-8'),
    'mailbox': mailbox.decode('utf-8'),
    'time': nowStr
  }
  topic = TOPIC_PUBLISH.format(MAILBOX_ID)

  # http://www.hivemq.com/blog/mqtt-essentials-part-6-mqtt-quality-of-service-levels
  client.publish(topic, payload=json.dumps(payload), qos=2, retain=False)
  

def takePictureOfRecognisedLetter(minAreaBox):
  """
  take a picute of recognised letter
  """

  # http://picamera.readthedocs.io/en/release-1.10/api_camera.html
  camera = PiCamera()
  camera.resolution = LETTER_RESOLUTION
  camera.capture('letterbox.jpg')
  print('a picture of the letterbox has been taken')
  
  letterBox = cv2.imread('letterbox.jpg')

  ratioX = 1.0 * LETTER_RESOLUTION[0] / FRAME_RESOLUTION[0]
  ratioY = 1.0 * LETTER_RESOLUTION[1] / FRAME_RESOLUTION[1]

  points = [
    [minAreaBox[0][0] * ratioX, minAreaBox[0][1] * ratioY],
    [minAreaBox[1][0] * ratioX, minAreaBox[1][1] * ratioY],
    [minAreaBox[2][0] * ratioX, minAreaBox[2][1] * ratioY],
    [minAreaBox[3][0] * ratioX, minAreaBox[3][1] * ratioY]
  ]
  print('letter croped', points)

  points = np.array(points, dtype = 'float32')

  # apply the four point tranform to obtain a "birds eye view" of the letter
  # http://www.pyimagesearch.com/2014/08/25/4-point-opencv-getperspective-transform-example/
  letter = four_point_transform(letterBox, points)

  cv2.imshow('Cropped Letter', letter)

  # save the letter
  # http://docs.opencv.org/2.4/doc/tutorials/introduction/load_save_image/load_save_image.html
  cv2.imwrite('letter.jpg', letter);
  print('letter saved')

  camera.close()

def analyseOneFrame(frame, substractor):
  """
  analyse one frame
  """

  global hasMotionDetected
  global numberOfFramesAfterMotionHasDetected

  # grab the raw NumPy array representing the image, then initialize the timestamp
  # and occupied/unoccupied text
  image = frame.array
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
      print('motion detected')

  if hasMotionDetected:
    numberOfFramesAfterMotionHasDetected += 1

  if numberOfFramesAfterMotionHasDetected >= FRAMES_TO_WAIT_TO_CAPTURE_LETTER:
    hasMotionDetected = False
    numberOfFramesAfterMotionHasDetected = 0

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

      # ignore if the letter is too small
      if area > MIN_LETTER_AREA:
        print('letter recognised', minAreaBox)
        return minAreaBox
      else:
        print('ignored, area of the letter ({}) is too small'.format(area))

  # live view
  cv2.imshow('frame', image)
  cv2.imshow('mask', fgmask)
  cv2.imshow('dinoised', mask)
  return None

client.loop_start()
while True:
  if not analyse():
    break
