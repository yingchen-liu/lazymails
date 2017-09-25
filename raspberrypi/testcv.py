# http://www.pyimagesearch.com/2015/02/23/install-opencv-and-python-on-your-raspberry-pi-2-and-b/
# http://www.pyimagesearch.com/2015/03/30/accessing-the-raspberry-pi-camera-with-opencv-and-python/
# http://www.pyimagesearch.com/2016/04/18/install-guide-raspberry-pi-3-raspbian-jessie-opencv-3/

# https://github.com/novaspirit/rpi_zram

# import the necessary packages
from picamera.array import PiRGBArray
from picamera import PiCamera
import math
import numpy as np
import RPi.GPIO as GPIO
import time
import cv2
from pyimagesearch.transform import four_point_transform

 
# initialize the camera and grab a reference to the raw camera capture


# initialize the motion detector
motionPin = [26, 19, 13]
GPIO.setmode(GPIO.BCM)
GPIO.setup(motionPin[0], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(motionPin[1], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(motionPin[2], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)





def analyse():
  global motionPin
  motionDetectedCount = 0
  motionDetected = False
  letterBox = []

  camera = PiCamera()
  camera.resolution = (640, 480)
  camera.framerate = 20
  rawCapture = PiRGBArray(camera, size=(640, 480))

  # allow the camera to warmup
  time.sleep(0.1)

  fgbg = cv2.bgsegm.createBackgroundSubtractorMOG()
  
  # capture frames from the camera
  print('camera inited')
  for frame in camera.capture_continuous(rawCapture, format="bgr", use_video_port=True):
    # grab the raw NumPy array representing the image, then initialize the timestamp
    # and occupied/unoccupied text
    image = frame.array
    fgmask = fgbg.apply(image)
    

    # https://stackoverflow.com/questions/30369031/remove-spurious-small-islands-of-noise-in-an-image-python-opencv
    se1 = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 7))
    se2 = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    mask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, se1)
    mask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, se2)

    # motion detected
    motion = GPIO.input(motionPin[0]) == 0 or GPIO.input(motionPin[1]) == 0 or GPIO.input(motionPin[0]) == 0
    if motion:
      motionDetected = True

    if motionDetected:
      motionDetectedCount += 1
      print("count", motionDetectedCount)

    # _, thresh = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)
    
    # _, contours, hierarchy = cv2.findContours(thresh, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)

    # # http://answers.opencv.org/question/32140/draw-largestrect-contour-on-this-image/
    # largestArea = 0
    # largestI = 0
    # # https://stackoverflow.com/questions/522563/accessing-the-index-in-python-for-loops
    # for i, contour in enumerate(contours):
    #   area = cv2.contourArea(contour)
    #   if area > largestArea:
    #     largestArea = area
    #     largestI = i

    # http://opencvpython.blogspot.com.au/2012/06/hi-this-article-is-tutorial-which-try.html
    # if len(contours) > largestI:
    #   cv2.drawContours(image, [contours[largestI]], -1, (0, 255, 0), 3)

    # https://stackoverflow.com/questions/23720875/how-to-draw-a-rectangle-around-a-region-of-interest-in-python
    # http://docs.opencv.org/trunk/d1/d32/tutorial_py_contour_properties.html
    # https://stackoverflow.com/questions/39994831/difference-between-cv2-findnonzero-and-numpy-nonzero
    
    if motionDetectedCount >= 10:
      nonZero = cv2.findNonZero(mask)
      if nonZero != None:
        #x,y,w,h = cv2.boundingRect(nonZero)
        #cv2.rectangle(image, (x, y), (x + w, y + h), (255,0,0), 3)

        # http://opencvpython.blogspot.com.au/2012/06/contours-2-brotherhood.html
      
        rect = cv2.minAreaRect(nonZero)
        box = cv2.boxPoints(rect)
        box = np.int0(box)
        area = cv2.contourArea(box)
        if area > 20000: # ignore if it is too small
          camera.close()
          time.sleep(0.1)

          # http://picamera.readthedocs.io/en/release-1.10/api_camera.html
          camera = PiCamera()
          camera.resolution = (1440, 1080)
          camera.start_preview()
          camera.capture('letterbox.jpg')
          camera.stop_preview()

          
          letter = cv2.imread('letterbox.jpg')

          pts = np.array([
            [box[0][0] * (1440.0 / 640), box[0][1] * (1080.0 / 480)],
            [box[1][0] * (1440.0 / 640), box[1][1] * (1080.0 / 480)],
            [box[2][0] * (1440.0 / 640), box[2][1] * (1080.0 / 480)],
            [box[3][0] * (1440.0 / 640), box[3][1] * (1080.0 / 480)]
          ], dtype = "float32")

          # apply the four point tranform to obtain a "birds eye view" of
          # the image
          warped = four_point_transform(letter, pts)
          cv2.imshow("Warped", warped)

          # http://docs.opencv.org/2.4/doc/tutorials/introduction/load_save_image/load_save_image.html
          cv2.imwrite( "letter.jpg", warped );

          time.sleep(0.1)
          camera.close()
          return

          # http://www.pyimagesearch.com/2014/08/25/4-point-opencv-getperspective-transform-example/

    # show the frame
    cv2.imshow("frame", image)
    cv2.imshow("mask", fgmask)
    cv2.imshow("dinoised", mask)

    # clear the stream in preparation for the next frame
    rawCapture.truncate(0)

    # if the `q` key was pressed, break from the loop
    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
      break

  cv2.destroyAllWindows()

while(True):
  analyse()
