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
# Python bindings for SerializedCellsReader/SerializedCellsWriter
#

set(CMAKE_CXX_FLAGS "-DHAVE_NETINET_IN_H ${CMAKE_CXX_FLAGS}")

include_directories(${PYTHON_INCLUDE_DIR})

add_library(HyperPython MODULE SerializedCells.cc)
target_link_libraries(HyperPython HyperThrift HyperCommon
    Hypertable ${PYTHON_LIBRARY} ${BOOST_PYTHON_LIB} ${Thrift_LIBS} ${LibEvent_LIBS})
install(TARGETS HyperPython
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION "lib/py/hypertable"
        ARCHIVE DESTINATION "lib/py/hypertable")

add_test(HyperPython-reader env PYTHONPATH=${CMAKE_CURRENT_BINARY_DIR}:${CMAKE_SOURCE_DIR}/src/py/ThriftClient:${CMAKE_SOURCE_DIR}/src/py/ThriftClient/gen-py
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/run-reader.sh)

add_test(HyperPython-writer env PYTHONPATH=${CMAKE_CURRENT_BINARY_DIR}:${CMAKE_SOURCE_DIR}/src/py/ThriftClient:${CMAKE_SOURCE_DIR}/src/py/ThriftClient/gen-py
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/run-writer.sh)

if (SANITIZE STREQUAL "undefined")
  # Boost.Python placement-new's holder objects at misaligned addresses — a
  # known system library limitation.  Disable UBSan alignment checks for this
  # translation unit only (all Boost.Python templates are inlined here).
  set_source_files_properties(SerializedCells.cc PROPERTIES
    COMPILE_FLAGS "-fno-sanitize=alignment")
endif ()

if (SANITIZE STREQUAL "address")
  # HyperPython.so is an ASAN-instrumented C extension loaded by the stock
  # Python interpreter.  ASAN requires its runtime to be the very first
  # library in the process, so we must LD_PRELOAD it ahead of everything else.
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} -print-file-name=libasan.so
    OUTPUT_VARIABLE LIBASAN_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  set_tests_properties(HyperPython-reader HyperPython-writer PROPERTIES
    ENVIRONMENT "LD_PRELOAD=${LIBASAN_PATH}")
endif ()

if (SANITIZE STREQUAL "thread")
  # libtsan.so needs static TLS, which is not available when the .so is
  # dlopen'd by an uninstrumented python3.  We must LD_PRELOAD it before
  # python3 starts, but NOT before bash (which would segfault).  Pass the
  # path via HT_TSAN_PRELOAD; the shell scripts apply it only to python3.
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} -print-file-name=libtsan.so
    OUTPUT_VARIABLE LIBTSAN_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  set_tests_properties(HyperPython-reader HyperPython-writer PROPERTIES
    ENVIRONMENT "HT_TSAN_PRELOAD=${LIBTSAN_PATH}")
endif ()
