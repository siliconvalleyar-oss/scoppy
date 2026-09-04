#pragma once

#include <cstdint>

namespace scoppy::usb {

struct DeviceDescriptor {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint16_t bcdUSB;
    uint8_t bDeviceClass;
    uint8_t bDeviceSubClass;
    uint8_t bDeviceProtocol;
    uint8_t bMaxPacketSize0;
    uint16_t idVendor;
    uint16_t idProduct;
    uint16_t bcdDevice;
    uint8_t iManufacturer;
    uint8_t iProduct;
    uint8_t iSerialNumber;
    uint8_t bNumConfigurations;
};

struct ConfigurationDescriptor {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint16_t wTotalLength;
    uint8_t bNumInterfaces;
    uint8_t bConfigurationValue;
    uint8_t iConfiguration;
    uint8_t bmAttributes;
    uint8_t bMaxPower;
};

struct InterfaceDescriptor {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bInterfaceNumber;
    uint8_t bAlternateSetting;
    uint8_t bNumEndpoints;
    uint8_t bInterfaceClass;
    uint8_t bInterfaceSubClass;
    uint8_t bInterfaceProtocol;
    uint8_t iInterface;
};

struct EndpointDescriptor {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bEndpointAddress;
    uint8_t bmAttributes;
    uint16_t wMaxPacketSize;
    uint8_t bInterval;
};

constexpr uint8_t kDescriptorTypeIAD = 0x0B;
constexpr uint8_t kDescriptorTypeEndpoint = 0x05;
constexpr uint8_t kDescriptorTypeInterface = 0x04;
constexpr uint8_t kDescriptorTypeConfiguration = 0x02;
constexpr uint8_t kDescriptorTypeDevice = 0x01;

constexpr uint8_t kClassIAD = 0x02;
constexpr uint8_t kSubclassACM = 0x02;
constexpr uint8_t kClassCDC = 0x02;
constexpr uint8_t kClassCDCData = 0x0A;
constexpr uint8_t kTransferTypeBulk = 0x02;
constexpr uint8_t kTransferTypeInterrupt = 0x03;
constexpr uint8_t kDirectionIn = 0x80;
constexpr uint8_t kDirectionOut = 0x00;

constexpr uint16_t kVendorId = 0x2E8A;
constexpr uint16_t kProductId = 0x000A;
constexpr uint8_t kInterfaceCount = 2;

constexpr uint8_t kConfigurationIndex = 1;

constexpr uint16_t kEndpointInterruptMaxPacket = 8;
constexpr uint16_t kEndpointBulkMaxPacket = 64;
constexpr uint8_t kEndpointInterruptInterval = 16;

}
