#pragma once

#include <cstdint>
#include <cstddef>

namespace scoppy::adc {

constexpr uint8_t kChannel1GPIO = 26;
constexpr uint8_t kChannel2GPIO = 27;
constexpr uint8_t kAdcResolutionBits = 10;
constexpr uint32_t kMaxSampleRate = 2000000;  // 2.0 MS/s

struct SampleBuffer {
    uint8_t* data;
    size_t capacity;
    size_t write_index;
    size_t read_index;
    bool overflow;
};

class AdcDma {
public:
    AdcDma() = default;
    ~AdcDma() = default;

    bool init();
    bool start(uint32_t sample_rate);
    bool stop();
    bool read_samples(uint16_t* samples, size_t count, size_t& read);
    void set_trigger(uint8_t channel, uint8_t type, uint16_t level);
    bool wait_for_trigger(uint32_t timeout_ms);

    static AdcDma& instance();

private:
    bool setup_dma();
    bool setup_adc();
    bool configure_sample_rate(uint32_t sample_rate);
    void isr_handler();

    SampleBuffer buffer_;
    uint32_t sample_rate_ = 500000;
    bool running_ = false;
    uint8_t trigger_channel_ = 0;
    uint8_t trigger_type_ = 0;
    uint16_t trigger_level_ = 0;
};

}
