#pragma once

#include <cstdint>
#include <cstddef>

namespace scoppy::net {

constexpr uint16_t kDiscoveryPort = 22483;
constexpr size_t kDiscoveryResponseLength = 41;

class TcpServer {
public:
    TcpServer() = default;
    ~TcpServer() = default;

    bool init();
    bool start(uint16_t port);
    void stop();
    void process();

    static TcpServer& instance();

private:
    bool handle_client(int client_fd);
    int build_discovery_response(uint8_t* buffer, size_t len);

    uint16_t port_ = kDiscoveryPort;
    bool running_ = false;
};

}
