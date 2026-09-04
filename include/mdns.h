#pragma once

#include <cstdint>
#include <cstddef>

namespace scoppy::net {

constexpr uint16_t kMdnsPort = 5353;

class Mdns {
public:
    Mdns() = default;
    ~Mdns() = default;

    bool init();
    bool start(const char* hostname);
    void stop();
    void process();

    static Mdns& instance();

private:
    bool add_service(const char* service_name, const char* protocol, uint16_t port);
    bool add_hostname(const char* hostname);

    bool running_ = false;
};

}
