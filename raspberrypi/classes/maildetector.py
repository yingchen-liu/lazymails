from PIL import Image
from picamera.array import PiRGBArray
from picamera import PiCamera

import numpy as np
import RPi.GPIO as GPIO
import cv2
from classes.transform import four_point_transform
import datetime
import time
import math

from classes.utils import toBase64


class MailDetector:
  
  def __init__(self, app, mailDetected, frameAvailable):
    self._app = app
    self._mailDetected = mailDetected
    self._frameAvailable = frameAvailable

    # initialize the motion detector
    GPIO.setmode(GPIO.BCM)
    for pin in self._app['config']['recognition']['motionDetector']['pins']:
      GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

    self._hasMotionDetected = False
    self._lastCenter = None

  def analyse(self):
    """
    analyse frames from camera
    """

    energySavingConfig = self._app['config']['energySaving']
    cameraConfig = self._app['config']['recognition']['camera']
    filesConfig = self._app['config']['recognition']['files']

    # initialize the camera and grab a reference to the raw camera capture
    camera = PiCamera()
    camera.resolution = cameraConfig['frameResolution']
    camera.framerate = 30
    camera.iso = 200
    camera.brightness = 50
    camera.sharpness = 100
    camera.shutter_speed = 13000

    rawCapture = PiRGBArray(camera, size=cameraConfig['frameResolution'])

    # allow the camera to warmup
    time.sleep(cameraConfig['timeToWaitForReady'])

    # initialize the background substractor
    substractor = cv2.bgsegm.createBackgroundSubtractorMOG(200, 5, 0.2)
    
    try:
      # capture frames from the camera
      # https://stackoverflow.com/questions/522563/accessing-the-index-in-python-for-loops
      for i, frame in enumerate(camera.capture_continuous(rawCapture, format='bgr', use_video_port=True)):
        
        # grab the raw NumPy array representing the image
        image = frame.array

        if self._frameAvailable:
          self._frameAvailable(self, image, i)

        minAreaBox = self.analyseOneFrame(image, substractor)
        if minAreaBox != None:
          # close the camera
          camera.close()
          time.sleep(cameraConfig['timeToWaitForReady'])

          self.takePictureOfRecognisedLetter(minAreaBox)

          if self._mailDetected:
            self._mailDetected(self)\

          return True

        if self._app['settings']['isEnergySavingOn']:
          now = datetime.datetime.now()

          if now.hour >= energySavingConfig['start'] or now.hour < energySavingConfig['end']:
            camera.close()
            time.sleep(cameraConfig['timeToWaitForReady'])
            return True

        # clear the stream in preparation for the next frame
        rawCapture.truncate(0)

        # if the `q` key was pressed, break from the loop
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
          break

    except Exception as e:
      print('Error occurs when capturating frame', e)
      return True

    camera.close()
    # cv2.destroyAllWindows()
    return False

  def takePictureOfRecognisedLetter(self, minAreaBox):
    """
    take a picute of recognised letter
    """

    cameraConfig = self._app['config']['recognition']['camera']
    filesConfig = self._app['config']['recognition']['files']

    # https://stackoverflow.com/questions/3316882/how-do-i-get-a-string-format-of-the-current-date-time-in-python
    now = datetime.datetime.now()
    nowStr = now.strftime("%Y-%m-%d %H:%M:%S")

    # http://picamera.readthedocs.io/en/release-1.10/api_camera.html
    camera = PiCamera()
    camera.resolution = cameraConfig['mailResolution']
    camera.capture(nowStr + '_' + filesConfig['mailbox'])
    print('A picture of the mailbox has been taken')
    
    mailbox = cv2.imread(nowStr + '_' + filesConfig['mailbox'])

    ratioX = 1.0 * cameraConfig['mailResolution'][0] / cameraConfig['frameResolution'][0]
    ratioY = 1.0 * cameraConfig['mailResolution'][1] / cameraConfig['frameResolution'][1]

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
    mail = four_point_transform(mailbox, points)

    # cv2.imshow('Cropped Letter', letter)

    # save the letter
    # http://docs.opencv.org/2.4/doc/tutorials/introduction/load_save_image/load_save_image.html
    cv2.imwrite(nowStr + '_(' + repr(points[0][0]) + ',' + repr(points[0][1]) + '),(' + repr(points[1][0]) + ',' + repr(points[1][1]) + '),(' + repr(points[2][0]) + ',' + repr(points[2][1]) + '),(' + repr(points[3][0]) + ',' + repr(points[3][1]) + ')_' + filesConfig['mail'], mail)
    print('Mail saved')

    camera.close()

  def analyseOneFrame(self, image, substractor):
    """
    analyse one frame
    """

    recognitionConfig = self._app['config']['recognition']

    # pre-process
    # https://stackoverflow.com/questions/46000390/opencv-backgroundsubtractor-yields-poor-results-on-objects-with-similar-color-as
    # https://stackoverflow.com/questions/15100913/color-space-conversion-with-cv2
    # https://stackoverflow.com/questions/22153271/error-using-cv2-equalizehist
    # image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # image = cv2.equalizeHist(image)
    
    cv2.imshow('sharped', image)

    fgmask = substractor.apply(image)

    # denoise
    # https://stackoverflow.com/questions/30369031/remove-spurious-small-islands-of-noise-in-an-image-python-opencv
    se1 = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 7))
    mask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, se1)

    se2 = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    mask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, se2)

    # motion detected
    for pin in recognitionConfig['motionDetector']['pins']:
      if GPIO.input(pin) == 0:
        self._hasMotionDetected = True
        print('Motion detected')

    if self._hasMotionDetected:
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
        
        if area > recognitionConfig['mailArea']['min'] and area < recognitionConfig['mailArea']['max']:
          center = (
            (minAreaBox[0][0] + minAreaBox[1][0] + minAreaBox[2][0] + minAreaBox[3][0]) / 4,
            (minAreaBox[0][1] + minAreaBox[1][1] + minAreaBox[2][1] + minAreaBox[3][1]) / 4,
          )
          if self._lastCenter:
            move = math.sqrt(math.pow(center[0] - self._lastCenter[0], 2) + math.pow(center[1] - self._lastCenter[1], 2))
            print('area', area, 'move', move)
            if move <= 0.01:
              # wait until it is static
              print('Letter recognised', minAreaBox)
              self._hasMotionDetected = False
              return minAreaBox

          self._lastCenter = center
        else:
          # ignore if the letter is too small
          print('Ignored, area of the letter ({}) is too small/large'.format(area))

    # live view
    cv2.imshow('frame', image)
    cv2.imshow('mask', fgmask)
    cv2.imshow('dinoised', mask)

    return None

