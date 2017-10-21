// https://github.com/adafruit/Adafruit_DotStar/

#include <Adafruit_DotStar.h>
#include <SPI.h>

#define NUMPIXELS 60
#define DATAPIN    4
#define CLOCKPIN   5

Adafruit_DotStar strip = Adafruit_DotStar(
  NUMPIXELS, DATAPIN, CLOCKPIN, DOTSTAR_BRG);

void setup() {
  Serial.begin(9600);
  
  strip.begin(); // Initialize pins for output
  strip.show();  // Turn all LEDs off ASAP
}

uint32_t color  = 0x333333;
int      head   = 0, tail = -10;
bool     inited = false;

void loop() {

  // https://www.arduino.cc/en/Reference/Serial
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    
    if (command == "on") {
      inited = true;
      for (int i = 0; i < NUMPIXELS; i++) {
        strip.setPixelColor(i, color);
      }
      strip.show();
      
    } else if (command == "off") {
      inited = true;
      for (int i = 0; i < NUMPIXELS; i++) {
        strip.setPixelColor(i, 0);
      }
      strip.show();
    }
  }

  if (!inited) {
    // Show connecting animation if it is not inited
    
    strip.setPixelColor(head, color); // 'On' pixel at head
    strip.setPixelColor(tail, 0);     // 'Off' pixel at tail
    strip.show();
    delay(20);
  
    if (++head >= NUMPIXELS) {        // Increment head index
      head = 0;                       // Reset head index to start
    }
    if (++tail >= NUMPIXELS) {        // Increment tail index
      tail = 0;                       // Reset head index to start
    }
  }
}
