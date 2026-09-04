#include "tcp_server.h"
#include <cstring>

namespace scoppy::net {

bool TcpServer::init() {
    // TODO: Initialize lwIP TCP stack
    return true;
}

bool TcpServer::start(uint16_t port) {
    port_ = port;
    // TODO: Create TCP PCB
    // TODO: Bind to port
    // TODO: Start listening
    running_ = true;
    return true;
}

void TcpServer::stop() {
    if (!running_) return;
    // TODO: Close listener
    // TODO: Cleanup PCB
    running_ = false;
}

void TcpServer::process() {
    if (!running_) return;
    // TODO: Accept new connections
    // TODO: Send discovery response on connect
    // TODO: Close idle connections
}

TcpServer& TcpServer::instance() {
    static TcpServer instance;
    return instance;
}

bool TcpServer::handle_client(int client_fd) {
    uint8_t buffer[kDiscoveryResponseLength];
    int len = build_discovery_response(buffer, sizeof(buffer));
    if (len <= 0) return false;
    // TODO: Send response to client
    // TODO: Close connection
    return true;
}

int TcpServer::build_discovery_response(uint8_t* buffer, size_t len) {
    if (!buffer || len < kDiscoveryResponseLength) return -1;

    // TODO: Get MAC address from CYW43
    // TODO: Get IP address
    // TODO: Get firmware version
    // TODO: Build 41-byte response matching observed format:
    //   ff 00 29 3c 41 07 20 00 29 27 e6 61 4c 31 1b 85
    //   20 39 03 12 35 38 63 14 00 00 28 cd c1 04 e6 7c
    //   01 04 a8 c0 00 02 00 10 00

    // Placeholder: fill with zeros for now
    std::memset(buffer, 0, kDiscoveryResponseLength);
    buffer[0] = 0xFF;
    return kDiscoveryResponseLength;
}

}
