#include "usb_descriptors.h"
#include "usb_handler.h"
#include "adc_dma.h"
#include "tcp_server.h"
#include "mdns.h"
#include "wifi.h"

#include <cstdint>
#include <cstring>

using namespace scoppy::usb;
using namespace scoppy::adc;
using namespace scoppy::net;

int main() {
    // Initialize subsystems
    if (!WiFi::instance().init()) {
        // TODO: Handle fatal error
        return -1;
    }

    // TODO: Configure country code from stored settings
    // TODO: Start in AP mode or STA mode based on configuration

    if (!Mdns::instance().init()) {
        // TODO: Handle mDNS init failure
    }

    if (!TcpServer::instance().init()) {
        // TODO: Handle TCP server init failure
    }

    if (!AdcDma::instance().init()) {
        // TODO: Handle ADC/DMA init failure
    }

    if (!UsbHandler::instance().init()) {
        // TODO: Handle USB init failure
    }

    // Main loop
    while (true) {
        WiFi::instance().process();
        Mdns::instance().process();
        TcpServer::instance().process();
        UsbHandler::instance().process();

        // TODO: Sample ADC when acquiring
        // TODO: Send samples via USB when available
    }

    return 0;
}
