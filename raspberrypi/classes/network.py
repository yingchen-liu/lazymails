import socket
import time
import json
import _thread


class Network:
  
  def __init__(self, app, connected, disconnected, receivedMessage):
    self._app = app
    self._sock = None
    self._connected = connected
    self._disconnected = disconnected
    self._receivedMessage = receivedMessage
    self._isConnected = False

    try:
      # https://raspberrypi.stackexchange.com/questions/22444/importerror-no-module-named-thread

      _thread.start_new_thread(self.receiveMessage, ())
    except Exception as e:
      print('Unable to start thread for receiving message:', e)

  def sendMessage(self, message):
    
    networkConfig = self._app['config']['network']

    try:
      # https://stackoverflow.com/questions/11781639/typeerror-str-does-not-support-buffer-interface
      self._sock.sendall((json.dumps(message) + networkConfig['endSymbol']).encode('utf-8'))
    except Exception as e:
      print('Failed to send the message', e)

  def connect(self):
    
    networkConfig = self._app['config']['network']

    print('Connection ...')

    while True:
      try:
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.connect((networkConfig['host'], networkConfig['port']))

        if self._connected:
          self._connected(self)

        self._isConnected = True
        break
      except Exception as e:
        self._isConnected = False
        print('Failed to connenct to the server, retry after 3 seconds', e)
        time.sleep(3)

  def receiveMessage(self):
    
    networkConfig = self._app['config']['network']

    while True:
      if not self._sock or not self._isConnected:
        print('Not connected')
        continue

      data = ''
      try:
        while not data.endswith(networkConfig['endSymbol']):
          buff = self._sock.recv(16)
          if buff:
            data += buff.decode('utf-8')
          else:
            # http://www.programmingforums.org/post143163.html
            
            self._sock.close()
            self._isConnected = False

            if self._disconnected:
              self._disconnected(None)

            self.connect()

      except KeyboardInterrupt:
        self._sock.close()
        self._isConnected = False
        break
      except Exception as e:
        # https://stackoverflow.com/questions/17386487/python-detect-when-a-socket-disconnects-for-any-reason
        print('Error occurs when receiving message', e)
        self._sock.close()
        self._isConnected = False

        if self._disconnected:
          self._disconnected(e)

        self.connect()

      messages = data.split(networkConfig['endSymbol'])

      for message in messages:
        if message != '':
          print('Received message from the server', message)
          message = json.loads(message)
          
          if self._receivedMessage:
            self._receivedMessage(self, message)