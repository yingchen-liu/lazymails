# http://answers.opencv.org/question/66084/using-backgroundsubtractormog2-for-images/
# https://www.raspberrypi.org/learning/getting-started-with-picamera/worksheet/

#coding=utf8

import numpy as np
import cv2

backgroundSubtractor = cv2.bgsegm.createBackgroundSubtractorMOG()

for i in range(0, 120):
  bg = cv2.imread("./images/image{}.jpg".format(i))
  backgroundSubtractor.apply(bg, learningRate=1.0/120)

stillFrame = cv2.imread("./letter.jpg")
fgmask = backgroundSubtractor.apply(stillFrame, learningRate=0)

cv2.imshow("original", cv2.resize(stillFrame, (0, 0), fx=0.5, fy=0.5))
cv2.imshow("mask", cv2.resize(fgmask, (0, 0), fx=0.5, fy=0.5))
cv2.waitKey()
cv2.destroyAllWindows()