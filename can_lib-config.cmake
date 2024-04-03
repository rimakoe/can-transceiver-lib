#include(/usr/local/lib/can_lib/cmake/can_lib.cmake)
include( "${CMAKE_CURRENT_LIST_DIR}/can-transciever-lib.cmake" )
set(can_lib_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/../libcan-transciever-lib.so)