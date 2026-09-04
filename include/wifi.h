#pragma once

#include <cstdint>
#include <cstddef>

namespace scoppy::net {

constexpr uint8_t kWiFiModeAP = 0;
constexpr uint8_t kWiFiModeSTA = 1;

class WiFi {
public:
    WiFi() = default;
    ~WiFi() = default;

    bool init();
    bool set_mode(uint8_t mode);
    bool start_ap(const char* ssid, const char* password);
    bool connect_sta(const char* ssid, const char* password);
    void process();

    static WiFi& instance();

private:
    bool setup_cyw43();
    bool configure_country(const char* country_code);

    uint8_t mode_ = kWiFiModeAP;
    bool running_ = false;
};

}
