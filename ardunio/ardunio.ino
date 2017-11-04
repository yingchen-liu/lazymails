//
// LazyMails Ardunio Nano-End
//
// For controlling the light
//

// Attributes:
// adafruit/Adafruit_DotStar
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

uint32_t color                  = 0x333333;
int      head                   = 0, tail = -10;
bool     inited                 = false;
int      serialNotAvailabeTimes = 0;

void loop() {

  // Arduino - Serial
  // https://www.arduino.cc/en/Reference/Serial

  if (Serial.available()) {
    serialNotAvailabeTimes = 0;
    inited = true;
    String command = Serial.readStringUntil('\n');
    
    if (command == "on") {
      for (int i = 0; i < NUMPIXELS; i++) {
        strip.setPixelColor(i, color);
      }
      strip.show();
      
    } else if (command == "off") {
      for (int i = 0; i < NUMPIXELS; i++) {
        strip.setPixelColor(i, 0);
      }
      strip.show();
    }
  } else {
    delay(10);
    if (++serialNotAvailabeTimes >= 5 * (1000 / 10)) {    // Show connecting animation if 5s no signal
      inited = false;
    }
  }

  if (!inited) {
    // Show connecting animation if it is not inited
    
    strip.setPixelColor(head, color); // 'On' pixel at head
    strip.setPixelColor(tail, 0);     // 'Off' pixel at tail
    strip.show();
    delay(10);
  
    if (++head >= NUMPIXELS) {        // Increment head index
      head = 0;                       // Reset head index to start
    }
    if (++tail >= NUMPIXELS) {        // Increment tail index
      tail = 0;                       // Reset head index to start
    }
  }
}
