# http://picamera.readthedocs.io/en/release-1.13/api_camera.html

import picamera
from time import sleep

camera = picamera.PiCamera()

camera.sharpness = 100
camera.contrast = 0
camera.brightness = 60
camera.saturation = 0
camera.ISO = 0
camera.video_stabilization = False
camera.exposure_compensation = 0
camera.exposure_mode = 'auto'
camera.meter_mode = 'average'
camera.awb_mode = 'auto'
camera.image_effect = 'none'
camera.color_effects = None
camera.rotation = 0
camera.hflip = False
camera.vflip = False
camera.crop = (0.0, 0.0, 1.0, 1.0)
camera.resolution = (1280, 720)

camera.start_preview()
for i in range(0, 120):
  camera.capture('./images/image{}.jpg'.format(i))

camera.stop_preview()