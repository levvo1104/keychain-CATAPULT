#include <NimBLEDevice.h>

// Must match your Swift UUIDs exactly
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890AB"
#define BUTTON_COUNTS_UUID  "12345678-1234-1234-1234-1234567890AC"
#define HABIT_DATA_UUID     "12345678-1234-1234-1234-1234567890AD"

NimBLEServer* pServer = nullptr;
NimBLECharacteristic* pButtonCountsChar = nullptr;
NimBLECharacteristic* pHabitDataChar = nullptr;

uint8_t buttonCounts[9] = {0}; // one counter per button

// Called when iPhone writes habit data
class HabitDataCallback : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pChar) override {
        std::string val = pChar->getValue();
        // val is the raw JSON from HabitPayload — parse as needed
        Serial.printf("Received %d bytes: %s\n", val.length(), val.c_str());
    }
};

// Track connection state
class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) override {
        Serial.println("iPhone connected");
    }
    void onDisconnect(NimBLEServer* pServer) override {
        Serial.println("Disconnected — restarting advertising");
        NimBLEDevice::startAdvertising();
    }
};

void setup() {
    Serial.begin(115200);
    NimBLEDevice::init("MyKeychain"); // device name shown in scan

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService* pService = pServer->createService(SERVICE_UUID);

    // Button counts: notify-only (ESP32 → iPhone)
    pButtonCountsChar = pService->createCharacteristic(
        BUTTON_COUNTS_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );

    // Habit data: write-only (iPhone → ESP32)
    pHabitDataChar = pService->createCharacteristic(
        HABIT_DATA_UUID,
        NIMBLE_PROPERTY::WRITE
    );
    pHabitDataChar->setCallbacks(new HabitDataCallback());

    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID); // critical — your app scans by this UUID
    pAdvertising->start();
    Serial.println("Advertising...");
}

void loop() {
    // Example: simulate button 1 being pressed every 5 seconds
    delay(5000);
    buttonCounts[0]++;

    // Send all 9 counts as a 9-byte notification
    pButtonCountsChar->setValue(buttonCounts, 9);
    pButtonCountsChar->notify();
}
