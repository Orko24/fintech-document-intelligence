cmake_minimum_required(VERSION 3.16)
project(ocr-service)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(OpenCV REQUIRED)
find_package(Tesseract REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(Threads REQUIRED)

# Find additional libraries
pkg_check_modules(CROW REQUIRED crow)
pkg_check_modules(JSON REQUIRED nlohmann_json)

# Include directories
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${Tesseract_INCLUDE_DIRS})
include_directories(${CROW_INCLUDE_DIRS})
include_directories(${JSON_INCLUDE_DIRS})

# Source files
set(SOURCES
    src/main.cpp
    src/ocr_engine.cpp
    src/image_processor.cpp
    src/text_extractor.cpp
    src/api_handler.cpp
)

# Create executable
add_executable(ocr-service ${SOURCES})

# Link libraries
target_link_libraries(ocr-service
    ${OpenCV_LIBS}
    ${Tesseract_LIBRARIES}
    ${CROW_LIBRARIES}
    ${JSON_LIBRARIES}
    Threads::Threads
)

# Compiler flags
target_compile_options(ocr-service PRIVATE
    -Wall
    -Wextra
    -O2
    -DNDEBUG
)

# Install
install(TARGETS ocr-service DESTINATION bin) 