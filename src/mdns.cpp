#include "mdns.h"
#include <cstring>

namespace scoppy::net {

bool Mdns::init() {
    // TODO: Initialize mDNS responder
    return true;
}

bool Mdns::start(const char* hostname) {
    if (!add_hostname(hostname)) return false;
    // TODO: Register _scoppy._tcp service on port 22483
    // TODO: Register _scoppyx._tcp service
    running_ = true;
    return true;
}

void Mdns::stop() {
    if (!running_) return;
    // TODO: Cleanup mDNS services
    running_ = false;
}

void Mdns::process() {
    if (!running_) return;
    // TODO: Process mDNS packets
    // TODO: Handle queries and announcements
}

Mdns& Mdns::instance() {
    static Mdns instance;
    return instance;
}

bool Mdns::add_service(const char* service_name, const char* protocol, uint16_t port) {
    // TODO: Add mDNS service using lwIP mdns_resp_add_service
    return true;
}

bool Mdns::add_hostname(const char* hostname) {
    // TODO: Add hostname to mDNS responder
    return true;
}

}
