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

set(SRC_DIR "${HYPERTABLE_SOURCE_DIR}/src/cc/AsyncComm/tests")
set(DST_DIR "${HYPERTABLE_BINARY_DIR}/src/cc/AsyncComm")

set(TEST_DEPENDENCIES ${DST_DIR}/words)

set(AsyncComm_SRCS
DispatchHandlerSynchronizer.cc
Comm.cc
CommAddress.cc
CommHeader.cc
Config.cc
ConnectionManager.cc
Event.cc
HandlerMap.cc
IOHandler.cc
IOHandlerAccept.cc
IOHandlerData.cc
IOHandlerDatagram.cc
IOHandlerRaw.cc
PollEvent.cc
Protocol.cc
ProxyMap.cc
Reactor.cc
ReactorFactory.cc
ReactorRunner.cc
RequestCache.cc
ResponseCallback.cc
)

if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
  link_libraries(nsl socket resolv)
endif (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")

add_library(HyperComm ${AsyncComm_SRCS})
target_link_libraries(HyperComm HyperCommon)

# sampleClient
add_executable(sampleClient sampleClient.cc)
target_link_libraries(sampleClient HyperComm)

# testServer
add_executable(testServer testServer.cc)
target_link_libraries(testServer HyperComm)

# commTest
add_executable(commTest tests/commTest.cc tests/CommTestThreadFunction.cc
               ${TEST_DEPENDENCIES})
target_link_libraries(commTest HyperComm)

# commTestDatagram
add_executable(commTestDatagram tests/commTestDatagram.cc
               tests/CommTestDatagramThreadFunction.cc ${TEST_DEPENDENCIES})
target_link_libraries(commTestDatagram HyperComm)

# commTestTimeout
add_executable(commTestTimeout tests/commTestTimeout.cc)
target_link_libraries(commTestTimeout HyperComm)

# commTestTimer
add_executable(commTestTimer tests/commTestTimer.cc)
target_link_libraries(commTestTimer HyperComm)

# commTestReverseRequest
add_executable(commTestReverseRequest tests/commTestReverseRequest.cc)
target_link_libraries(commTestReverseRequest HyperComm)

configure_file(${SRC_DIR}/commTestTimeout.golden
               ${DST_DIR}/commTestTimeout.golden)
configure_file(${SRC_DIR}/commTestTimer.golden ${DST_DIR}/commTestTimer.golden)
configure_file(${SRC_DIR}/datafile.txt ${DST_DIR}/datafile.txt)
configure_file(${SRC_DIR}/commTestReverseRequest.golden
               ${DST_DIR}/commTestReverseRequest.golden)

add_custom_command(SOURCE ${HYPERTABLE_SOURCE_DIR}/tests/data/words.gz
    COMMAND gzip ARGS -d < ${HYPERTABLE_SOURCE_DIR}/tests/data/words.gz
                         > ${DST_DIR}/words
    OUTPUT ${DST_DIR}/words)

set(ADDITIONAL_MAKE_CLEAN_FILES ${DST_DIR}/words)

# Tests reference ./testServer and ./sampleClient relative to CWD; symlink them into DST_DIR
foreach(_exe testServer sampleClient)
  if (NOT IS_SYMLINK "${DST_DIR}/${_exe}")
    file(CREATE_LINK "${HYPERTABLE_BINARY_DIR}/bin/${_exe}" "${DST_DIR}/${_exe}" SYMBOLIC)
  endif()
endforeach()

add_test(NAME HyperComm COMMAND $<TARGET_FILE:commTest>
         WORKING_DIRECTORY ${DST_DIR})
add_test(NAME HyperComm-datagram COMMAND $<TARGET_FILE:commTestDatagram>
         WORKING_DIRECTORY ${DST_DIR})
add_test(NAME HyperComm-timeout COMMAND $<TARGET_FILE:commTestTimeout>
         WORKING_DIRECTORY ${DST_DIR})
add_test(NAME HyperComm-timer COMMAND $<TARGET_FILE:commTestTimer>
         WORKING_DIRECTORY ${DST_DIR})
add_test(NAME HyperComm-reverse-request COMMAND $<TARGET_FILE:commTestReverseRequest>
         WORKING_DIRECTORY ${DST_DIR})

if (NOT HT_COMPONENT_INSTALL)
  file(GLOB HEADERS *.h)

  install(FILES ${HEADERS} DESTINATION include/AsyncComm)

  install(TARGETS HyperComm
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)
endif ()
