#include <Adafruit_DotStar.h>
#include <SPI.h>

#define NUMPIXELS 60
#define DATAPIN    4
#define CLOCKPIN   5

Adafruit_DotStar strip = Adafruit_DotStar(
  NUMPIXELS, DATAPIN, CLOCKPIN, DOTSTAR_BRG);

void setup() {
  strip.begin(); // Initialize pins for output
  strip.show();  // Turn all LEDs off ASAP
}

void loop() {
  uint32_t color = 0x111111;
  
  // Set color to each pixel
  for (int i = 0; i < NUMPIXELS; i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();
}
