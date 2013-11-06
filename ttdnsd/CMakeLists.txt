macro (SETUP_LIB_BY_CMAKE lib)
	
	find_package (${lib} REQUIRED)
	include_directories(${${lib}_INCLUDE_DIRS})
	list(APPEND PROJECT_LIBRARIES ${${lib}_LIBRARIES})
	list(APPEND PROJECT_LIBRARY_DIRS ${${lib}_LIBRARY_DIRS})

endmacro(SETUP_LIB_BY_CMAKE lib)

macro (SETUP_LIB_BY_PKGCONFIG lib)
	
	pkg_check_modules(${lib} REQUIRED ${lib})
	include_directories(${${lib}_INCLUDE_DIRS})
	list(APPEND PROJECT_LIBRARIES ${${lib}_LIBRARIES})
	list(APPEND PROJECT_LIBRARY_DIRS ${${lib}_LIBRARY_DIRS})

endmacro(SETUP_LIB_BY_PKGCONFIG lib)

cmake_minimum_required (VERSION 2.6)

project (unit_test)

find_package(Threads REQUIRED)

set(SOURCES ttdnsd.mm unit_test.cpp)

set(STOP_SOURCES ttdnsd.mm stopConsole.cpp)

#platform check
if(NOT HAVE_COCOA)
    set(NOT_HAVE_COCOA_FRAMEWORK 1)
endif(NOT HAVE_COCOA)


# platform-specific config file
configure_file("${CMAKE_SOURCE_DIR}/ttdnsd_platform.h.cmake" "${CMAKE_SOURCE_DIR}/ttdnsd_platform.h")

set(CMAKE_CXX_FLAGS "-Wall -g")

add_executable(Console ${SOURCES})
target_link_libraries(Console ${CMAKE_THREAD_LIBS_INIT})

add_executable(stopConsole ${STOP_SOURCES})
target_link_libraries(stopConsole ${CMAKE_THREAD_LIBS_INIT})
