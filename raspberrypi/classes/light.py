import serial
import _thread
import datetime
import time


"""
Light Control Class
"""
class Light:

  def __init__(self, app):
    """
    Initialize the light
    """
    self._app = app
    self._light = None

    _thread.start_new_thread(self.energySaving, ())

  def connect(self):
    """
    Connect to the Nano
    """

    # https://stackoverflow.com/questions/41987168/serial-object-has-no-attribute-is-open

    if self._light and self._light.isOpen():
      self._light.close()
    
    # http://pyserial.readthedocs.io/en/latest/shortintro.html
    # https://stackoverflow.com/questions/5471158/typeerror-str-does-not-support-the-buffer-interface

    while True:
      try:
        self._light = serial.Serial('/dev/ttyUSB0')
      except Exception as e:
        print('Could not connect to ttyUSB0', e)

      if not self._light:
        try:
          self._light = serial.Serial('/dev/ttyUSB1')
        except Exception as e:
          print('Could not connect to ttyUSB1', e)

      if self._light:
        print('Connected to the light')
        break

      time.sleep(1000)

  def switchOn(self):
    """
    Switch on the light
    """
    try:
      self._light.write(b'on\n')
    except Exception as e:
      print('Could not send on message to the light', e)
      self.connect()

  def switchOff(self):
    """
    Switch off the light
    """
    try:
      self._light.write(b'off\n')
    except Exception as e:
      print('Could not send on message to the light', e)
      self.connect()

  def energySaving(self):
    """
    Monitor the energy saving mode
    """
    energySavingConfig = self._app['config']['energySaving']

    while True:
      if self._app['settings']['isEnergySavingOn']:
        
        # https://stackoverflow.com/questions/30071886/how-to-get-current-time-in-python-and-break-up-into-year-month-day-hour-minu
        now = datetime.datetime.now()

        if now.hour >= energySavingConfig['start'] or now.hour < energySavingConfig['end']:
          self.switchOff()
        else:
          self.switchOn()
      else:
        self.switchOn()
      
      time.sleep(1)

  