#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// https://www.uuidgenerator.net/

#define BTNAME "ESP32"

#define CONTROLL       "1450dbb0-e48c-4495-ae90-5ff53327ede4"
#define CONTROLL_EFFECT "ec693074-43fe-489d-b63b-94456f83beb5"
#define CONTROLL_BRIGHTNESS "25e79015-4e97-44cd-9c5e-b539082666b0"
#define CONTROLL_COLOR "45db5a06-5481-49ee-a8e9-10b411d73de7"

#define MUSIC       "f2f9a4de-ef95-4fe1-9c2e-ab5ef6f0d6e9"
#define MUSIC_LEFT  "e376bd46-0d9a-44ab-bb71-c262d06f60c7"
#define MUSIC_RIGHT "b68f146c-e40c-4850-9d8b-ebbf513c8911"

int effect = 0;
int brightness = 100;
int color = 0;
double ampLeft = 0;
double ampRight = 0;

int strToInt(std::string str) {
  const char* encoded = str.c_str();
  return 256 * int(encoded[1]) + int(encoded[0]);
}

double intToDouble(int value, double max) {
  return (1.0 * value) / max;
}

class WriteEffect: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      effect = strToInt(pCharacteristic->getValue());
      Serial.print("Effect:");
      Serial.println(effect);
    }
};

class WriteColor: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      color = strToInt(pCharacteristic->getValue());
      Serial.print("Color:");
      Serial.println(color);
    }
};

class WriteBrightness: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      brightness = strToInt(pCharacteristic->getValue());
      Serial.print("Brightness:");
      Serial.println(brightness);
    }
};

class WriteMusicLeft: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      ampLeft = 100 * intToDouble(strToInt(pCharacteristic->getValue()), 10000.0);
      Serial.print("AmpLeft:");
      Serial.println(ampLeft);
    }
};

class WriteMusicRight: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      ampRight = 100 * intToDouble(strToInt(pCharacteristic->getValue()), 10000.0);
      Serial.print("AmpRight:");
      Serial.println(ampRight);
    }
};

void setup() {
  Serial.begin(115200);
  Serial.print("Device Name: ESP32");
  
  BLEDevice::init("ESP32");
  BLEServer *btServer = BLEDevice::createServer();
  BLEService *sControll = btServer->createService(CONTROLL);

  BLECharacteristic *cControllEffect = sControll->createCharacteristic(CONTROLL_EFFECT, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  cControllEffect->setCallbacks(new WriteEffect());
  cControllEffect->setValue("1");

  BLECharacteristic *cControllColor = sControll->createCharacteristic(CONTROLL_COLOR, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  cControllColor->setCallbacks(new WriteColor());
  cControllColor->setValue("1");

  BLECharacteristic *cControllBrightness = sControll->createCharacteristic(CONTROLL_BRIGHTNESS, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  cControllBrightness->setCallbacks(new WriteBrightness());
  cControllBrightness->setValue("1");


  BLEService *sMusic = btServer->createService(MUSIC);
  BLECharacteristic *cMusicLeft = sMusic->createCharacteristic(MUSIC_LEFT, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  cMusicLeft->setCallbacks(new WriteMusicLeft());
  cMusicLeft->setValue("0.5");

  BLECharacteristic *cMusicRight = sMusic->createCharacteristic(MUSIC_RIGHT, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  cMusicRight->setCallbacks(new WriteMusicRight());
  cMusicRight->setValue("0.5");

  sControll->start();
  sMusic->start();

  BLEAdvertising *pAdvertising = btServer->getAdvertising();
  pAdvertising->start();
}

void loop() {
  // Codo
  delay(2000);
}
