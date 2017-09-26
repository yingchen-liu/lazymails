# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/

# https://github.com/novaspirit/rpi_zram

import time
import numpy as np
import RPi.GPIO as GPIO
import cv2
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

# initialize the motion detector
GPIO.setmode(GPIO.BCM)
for pin in MOTION_DETECTOR_PINS:
  GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)


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

      return

    # clear the stream in preparation for the next frame
    rawCapture.truncate(0)

    # if the `q` key was pressed, break from the loop
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
      break

  cv2.destroyAllWindows()

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

while True:
  analyse()
