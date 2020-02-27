cmake_minimum_required(VERSION 3.15)

project(mc_ruler LANGUAGES C CXX)

add_library(mc_ruler INTERFACE)
target_include_directories(mc_ruler INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/public)
add_library(mc_ruler::mc_ruler ALIAS mc_ruler)

# Don't build the test project unless this is built as a standalone project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH})
    add_subdirectory(test)
else()
    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
endif()