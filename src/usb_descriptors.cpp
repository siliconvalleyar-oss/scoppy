#include "usb_descriptors.h"
#include <cstdint>
#include <cstddef>

extern "C" {

constexpr uint8_t kStringManufacturer[] = {
    0x12, 0x03, 'R', 0, 'a', 0, 's', 0, 'p', 0, 'b', 0, 'e', 0, 'r', 0, 'r', 0, 'y', 0,
};

constexpr uint8_t kStringProduct[] = {
    0x22, 0x03, 'S', 0, 'c', 0, 'o', 0, 'p', 0, 'p', 0, 'y', 0, ' ', 0, 'P', 0, 'i', 0, 'c', 0, 'o', 0,
};

constexpr uint8_t kStringSerial[] = {
    0x12, 0x03, '0', 0, '0', 0, '0', 0, '0', 0, '0', 0, '0', 0, '0', 0, '0', 0, '1', 0,
};

constexpr uint8_t kConfigDescriptor[] = {
    0x09, 0x02, 0x4B, 0x00, 0x02, 0x01, 0xA0, 0x7D,
    0x08, 0x0B, 0x00, 0x02, 0x02, 0x02, 0x00, 0x00,
    0x09, 0x04, 0x00, 0x00, 0x01, 0x02, 0x02, 0x00, 0x04,
    0x05, 0x24, 0x00, 0x20, 0x01,
    0x05, 0x24, 0x01, 0x00, 0x01,
    0x04, 0x24, 0x02, 0x02,
    0x05, 0x24, 0x06, 0x00, 0x01,
    0x07, 0x05, 0x81, 0x03, 0x08, 0x00, 0x10,
    0x09, 0x04, 0x01, 0x00, 0x02, 0x0A, 0x00, 0x00, 0x00,
    0x07, 0x05, 0x02, 0x02, 0x40, 0x00, 0x00,
    0x07, 0x05, 0x82, 0x02, 0x40, 0x00, 0x00,
};

const uint8_t* tud_descriptor_device_cb(void) {
    using namespace scoppy::usb;
    static DeviceDescriptor desc = {
        .bLength = sizeof(DeviceDescriptor),
        .bDescriptorType = 0x01,
        .bcdUSB = 0x0200,
        .bDeviceClass = 0xEF,
        .bDeviceSubClass = 0x02,
        .bDeviceProtocol = 0x01,
        .bMaxPacketSize0 = 64,
        .idVendor = 0x2E8A,
        .idProduct = 0x000A,
        .bcdDevice = 0x0100,
        .iManufacturer = 1,
        .iProduct = 2,
        .iSerialNumber = 3,
        .bNumConfigurations = 1,
    };
    return reinterpret_cast<const uint8_t*>(&desc);
}

const uint8_t* tud_descriptor_configuration_cb(uint8_t index) {
    (void)index;
    return kConfigDescriptor;
}

constexpr uint16_t kStringCount = 4;
static const uint8_t* kStringDescriptors[kStringCount] = {
    nullptr,
    kStringManufacturer,
    kStringProduct,
    kStringSerial,
};

const uint16_t* tud_descriptor_string_cb(uint8_t index, uint16_t langid) {
    (void)langid;
    if (index >= kStringCount) return nullptr;
    const uint8_t* str = kStringDescriptors[index];
    if (!str) return nullptr;
    return reinterpret_cast<const uint16_t*>(str);
}

}
