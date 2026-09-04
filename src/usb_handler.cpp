#include "usb_handler.h"
#include "usb_descriptors.h"
#include <cstring>

namespace scoppy::usb {

bool UsbHandler::init() {
    // TODO: Initialize TinyUSB device stack
    // TODO: Register vendor request handler
    return true;
}

void UsbHandler::process() {
    // TODO: Process USB events
    // TODO: Handle incoming commands on EP2 OUT
    // TODO: Stream samples on EP2 IN when acquiring
}

bool UsbHandler::send_samples(const uint8_t* data, size_t len) {
    // TODO: Send samples via EP2 IN bulk transfer
    return false;
}

UsbHandler& UsbHandler::instance() {
    static UsbHandler instance;
    return instance;
}

bool UsbHandler::handle_vendor_request(uint8_t request, uint16_t value, uint16_t index) {
    switch (value) {
        case kVendorRequestSet:
            // TODO: Parse command from index
            break;
        case kVendorRequestGet:
            // TODO: Return requested data
            break;
        default:
            break;
    }
    return false;
}

bool UsbHandler::handle_set_sample_rate(uint32_t rate_hz) {
    // TODO: Configure ADC clock based on rate_hz
    sample_rate_ = rate_hz;
    return true;
}

bool UsbHandler::handle_set_trigger(uint8_t channel, uint8_t type, uint8_t level) {
    // TODO: Configure trigger engine
    return true;
}

bool UsbHandler::handle_start_acquisition() {
    acquiring_ = true;
    // TODO: Start ADC + DMA
    return true;
}

bool UsbHandler::handle_stop_acquisition() {
    acquiring_ = false;
    // TODO: Stop ADC + DMA
    return true;
}

bool UsbHandler::handle_set_channel_range(uint8_t channel, uint8_t range) {
    // TODO: Set voltage range GPIOs
    return true;
}

bool UsbHandler::handle_get_device_info(uint8_t* buffer, size_t len) {
    // TODO: Populate device info (firmware version, capabilities, etc.)
    return false;
}

bool UsbHandler::handle_ping() {
    return true;
}

}
