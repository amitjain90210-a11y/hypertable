#
# Copyright (C) 2007-2016 Hypertable, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#

set(ThriftGen_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/ClientService.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/Client_types.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/HqlService.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/Hql_types.cpp)

set(ThriftGen_HDRS
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/ClientService.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/Client_types.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/HqlService.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gen-cpp/Hql_types.h)

add_custom_command(
  OUTPUT    ${ThriftGen_SRCS} ${ThriftGen_HDRS}
  COMMAND   thrift
  ARGS      -r --gen cpp -o ${CMAKE_CURRENT_SOURCE_DIR}
            ${CMAKE_CURRENT_SOURCE_DIR}/Hql.thrift
  DEPENDS   ${CMAKE_CURRENT_SOURCE_DIR}/Client.thrift
            ${CMAKE_CURRENT_SOURCE_DIR}/Hql.thrift
  COMMENT   "thrift2cpp"
)

set(CMAKE_CXX_FLAGS "-DHAVE_NETINET_IN_H ${CMAKE_CXX_FLAGS}")

add_library(HyperThrift ThriftHelper.cc SerializedCellsReader.cc SerializedCellsWriter.cc ${ThriftGen_SRCS})
target_link_libraries(HyperThrift ${Thrift_LIBS} ${LibEvent_LIBS})

add_library(HyperThriftConfig Config.cc)
target_link_libraries(HyperThriftConfig HyperThrift Hypertable)

set(ThriftBroker_SRCS ThriftBroker.cc MetricsHandler.cc)

# Disable tcmalloc for 32-bit systems
if (CMAKE_SYSTEM_PROCESSOR STREQUAL "i386" OR
    CMAKE_SYSTEM_PROCESSOR STREQUAL "i586" OR
    CMAKE_SYSTEM_PROCESSOR STREQUAL "i686")
  set(THRIFT_MALLOC_LIBRARY "")
else ()
  set(THRIFT_MALLOC_LIBRARY ${MALLOC_LIBRARY})
endif ()

# htThriftBroker
add_executable(htThriftBroker ${ThriftBroker_SRCS})
target_link_libraries(htThriftBroker HyperThriftConfig HyperAppHelper ${THRIFT_MALLOC_LIBRARY})

# Basic regression test
add_executable(client_test tests/client_test.cc)
target_link_libraries(client_test HyperThrift HyperCommon Hypertable)
add_test(NAME ThriftClient-cpp COMMAND $<TARGET_FILE:client_test>)

# ThriftClient-reconnect-hyperspace cds into build/src/cc/ThriftBroker/ and runs ./client_test
set(_thrift_dst "${HYPERTABLE_BINARY_DIR}/src/cc/ThriftBroker")
if (NOT IS_SYMLINK "${_thrift_dst}/client_test")
  file(CREATE_LINK "${HYPERTABLE_BINARY_DIR}/bin/client_test" "${_thrift_dst}/client_test" SYMBOLIC)
endif()

# regression test for SerializedCellsWriter/SerializedCellsReader
add_executable(serialized_test tests/serialized_test.cc)
target_link_libraries(serialized_test HyperThrift HyperCommon Hypertable)
add_test(NAME ThriftClient-Serialized-cpp COMMAND $<TARGET_FILE:serialized_test>)

if (NOT HT_COMPONENT_INSTALL OR PACKAGE_THRIFTBROKER)
  install(TARGETS HyperThrift HyperThriftConfig htThriftBroker
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION lib)
  install(FILES Client.h ThriftHelper.h SerializedCellsFlag.h SerializedCellsReader.h SerializedCellsWriter.h Client.thrift Hql.thrift
          DESTINATION include/ThriftBroker)
  install(DIRECTORY gen-cpp DESTINATION include/ThriftBroker)
endif ()

if (PACKAGE_THRIFTBROKER)
  file(GLOB SCRIPTS ${CMAKE_SOURCE_DIR}/bin/*broker.sh ${CMAKE_SOURCE_DIR}/bin/stop-servers.sh ${CMAKE_SOURCE_DIR}/bin/random-wait.sh)
  install(PROGRAMS ${SCRIPTS} DESTINATION bin)
  set(CPACK_PACKAGE_NAME "hypertable-thriftbroker-only")
  include(PackageHelper)
endif ()
