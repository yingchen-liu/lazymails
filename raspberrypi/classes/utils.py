import base64

def toBase64(filename):
  """
  convert file to base64
  """

  # https://www.programcreek.com/2013/09/convert-image-to-string-in-python/
  with open(filename, 'rb') as image:
    return base64.b64encode(image.read())