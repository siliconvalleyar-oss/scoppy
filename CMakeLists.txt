cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(pico_sdk_import.cmake OPTIONAL RESULT_VARIABLE PICO_SDK_IMPORT)
if(NOT PICO_SDK_IMPORT)
    get_filename_component(PICO_SDK_PATH "[HOST_NAME]" DIRECTORY)
    set(PICO_SDK_PATH ${PICO_SDK_PATH}/pico-sdk)
    include(${PICO_SDK_PATH}/pico_sdk_init.cmake)
endif()

project(scoppy_pico_firmware C CXX ASM)

pico_sdk_init()

add_executable(scoppy_firmware
    src/main.cpp
    src/usb_descriptors.cpp
    src/usb_handler.cpp
    src/adc_dma.cpp
    src/tcp_server.cpp
    src/mdns.cpp
    src/wifi.cpp
)

target_include_directories(scoppy_firmware PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/include
)

target_link_libraries(scoppy_firmware
    pico_stdlib
    pico_cyw43_arch_lwip_sys_freertos
    hardware_adc
    hardware_dma
    hardware_pwm
    tinyusb_device
    tinyusb_host
)

pico_add_extra_outputs(scoppy_firmware)
