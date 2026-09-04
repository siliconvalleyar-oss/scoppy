#pragma once

#include <cstdint>
#include <cstddef>

namespace scoppy::usb {

constexpr uint16_t kVendorRequest = 0x9A;
constexpr uint16_t kVendorRequestSet = 0x1312;
constexpr uint16_t kVendorRequestGet = 0xF2C;
constexpr uint8_t kVendorRequestType = 0x40;

class UsbHandler {
public:
    UsbHandler() = default;
    ~UsbHandler() = default;

    bool init();
    void process();
    bool send_samples(const uint8_t* data, size_t len);

    static UsbHandler& instance();

private:
    bool handle_vendor_request(uint8_t request, uint16_t value, uint16_t index);
    bool handle_set_sample_rate(uint32_t rate_hz);
    bool handle_set_trigger(uint8_t channel, uint8_t type, uint8_t level);
    bool handle_start_acquisition();
    bool handle_stop_acquisition();
    bool handle_set_channel_range(uint8_t channel, uint8_t range);
    bool handle_get_device_info(uint8_t* buffer, size_t len);
    bool handle_ping();

    uint32_t sample_rate_ = 500000;
    bool acquiring_ = false;
};

}
