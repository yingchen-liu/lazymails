import serial
import _thread
import datetime
import time


class Light:

  def __init__(self, app):
    self._app = app
    self._light = None

    _thread.start_new_thread(self.energySaving, ())

  def connect(self):
    # https://stackoverflow.com/questions/41987168/serial-object-has-no-attribute-is-open

    if not self._light or not self._light.isOpen():

      # http://pyserial.readthedocs.io/en/latest/shortintro.html
      # https://stackoverflow.com/questions/5471158/typeerror-str-does-not-support-the-buffer-interface

      self._light = serial.Serial('/dev/ttyUSB0')
      
  def switchOn(self):
    self._light.write(b'on\n')

  def switchOff(self):
    self._light.write(b'off\n')

  def energySaving(self):
    energySavingConfig = self._app['config']['energySaving']

    while True:
      self.connect()
        
      if self._app['settings']['isEnergySavingOn']:
        
        # https://stackoverflow.com/questions/30071886/how-to-get-current-time-in-python-and-break-up-into-year-month-day-hour-minu
        now = datetime.datetime.now()

        if now.hour >= energySavingConfig['start'] or now.hour < energySavingConfig['end']:
          self.switchOff()
        else:
          self.switchOn()
      else:
        self.switchOn()
      
      time.sleep(5)

  