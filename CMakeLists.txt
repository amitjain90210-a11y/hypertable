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

cmake_minimum_required(VERSION 3.5)

project(HYPERTABLE)

# Hypertable version components
set(VERSION_MAJOR "0")
set(VERSION_MINOR "9")
set(VERSION_MICRO "8")
set(VERSION_PATCH "11")
#set(VERSION_MISC_SUFFIX  "pre6")

mark_as_advanced(CMAKE_BACKWARDS_COMPATIBILITY)

# saner control structure syntax
set(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS true)

if (COMMAND cmake_policy)
  # we prefer the more strict behavior, to find out more:
  # cmake --help-policy CMP0003
  cmake_policy(SET CMP0003 NEW)
endif ()

# Something nice for GUI like ccmake
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING
      "Options: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

if (PHPTHRIFT_ROOT)
   message(FATAL_ERROR "PHPTHRIFT_ROOT variable no longer supported.  Use THRIFT_SOURCE_DIR instead.")
endif ()

#uname -p says i386, but we know better when its x86 apple
if (APPLE AND "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i386")
    SET(CMAKE_SYSTEM_PROCESSOR "x86_64")
endif ()
#detect 32 or 64 bit compiler
if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(i.86|x86|x86_64)$")
    include(CheckTypeSize)
    check_type_size("void*" SIZEOF_VOID_P BUILTIN_TYPES_ONLY)
    if (${SIZEOF_VOID_P} EQUAL 8)
        set(CMAKE_SYSTEM_PROCESSOR_x86 64)
    else ()
        set(CMAKE_SYSTEM_PROCESSOR_x86 32)
    endif ()
endif ()

# install directory prefix
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/opt/hypertable"
      CACHE PATH "installation directory prefix" FORCE)
endif ()

if (HT_DEPENDENCY_DIR)
  set(HT_DEPENDENCY_LIB_DIR ${HT_DEPENDENCY_DIR}/lib)
  set(HT_DEPENDENCY_INCLUDE_DIR ${HT_DEPENDENCY_DIR}/include)
endif ()

# Enable testing
enable_testing()

# Place all executables in build/bin/ so the ht wrapper script and test
# scripts can find them without requiring installation.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${HYPERTABLE_BINARY_DIR}/bin)

# A simple test helper
set(TEST_DIFF ${HYPERTABLE_SOURCE_DIR}/bin/src-utils/testdiff)

# gcc warning settings
if (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
  if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-long-long -pthreads")
    SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-long-long -pthreads")
  else (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-long-long")
    SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-long-long")
  endif (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
endif ()

# C flags
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-unknown-pragmas")
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pedantic")
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_LARGEFILE_SOURCE")
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_FILE_OFFSET_BITS=64")
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_REENTRANT")
SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")

# C++ flags
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-unknown-pragmas")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pedantic")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_LARGEFILE_SOURCE")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FILE_OFFSET_BITS=64")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_REENTRANT")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

set(SANITIZE "" CACHE STRING "Enable a sanitizer: address (asan), thread (tsan), memory (msan), undefined (ubsan)")
if (SANITIZE)
  if (SANITIZE STREQUAL "asan")
    set(SANITIZE "address")
  elseif (SANITIZE STREQUAL "tsan")
    set(SANITIZE "thread")
  elseif (SANITIZE STREQUAL "msan")
    set(SANITIZE "memory")
  elseif (SANITIZE STREQUAL "ubsan")
    set(SANITIZE "undefined")
  endif ()
  if (NOT SANITIZE MATCHES "^(address|thread|memory|undefined)$")
    message(FATAL_ERROR "SANITIZE must be one of: address (asan), thread (tsan), memory (msan), undefined (ubsan)")
  endif ()
  message(STATUS "Sanitizer enabled: ${SANITIZE}")
  if (SANITIZE STREQUAL "thread")
    macro(add_test)
      _add_test(${ARGV})
      if("${ARGV0}" STREQUAL "NAME")
        set(_tsan_test_name "${ARGV1}")
      else()
        set(_tsan_test_name "${ARGV0}")
      endif()
      if(_tsan_test_name)
        set_property(TEST ${_tsan_test_name} APPEND PROPERTY ENVIRONMENT
          "TSAN_OPTIONS=suppressions=${CMAKE_SOURCE_DIR}/tsan.supp:halt_on_error=1")
      endif()
    endmacro()
    install(FILES tsan.supp DESTINATION conf)
  elseif (SANITIZE STREQUAL "undefined")
    macro(add_test)
      _add_test(${ARGV})
      if("${ARGV0}" STREQUAL "NAME")
        set(_ubsan_test_name "${ARGV1}")
      else()
        set(_ubsan_test_name "${ARGV0}")
      endif()
      if(_ubsan_test_name)
        set_property(TEST ${_ubsan_test_name} APPEND PROPERTY ENVIRONMENT
          "UBSAN_OPTIONS=suppressions=${CMAKE_SOURCE_DIR}/ubsan.supp:halt_on_error=1:print_stacktrace=1")
      endif()
    endmacro()
    install(FILES ubsan.supp DESTINATION conf)
  endif ()
endif ()


# Build dynamic libraries and enable Legacy Hadoop support
set(BUILD_SHARED_LIBS ON)
set(HADOOP_INCLUDE_PATH /opt/hadoop/include)
set(HADOOP_LIB_PATH /opt/hadoop/lib/native)

# Locate required packages
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include(CommonUtil)

# A more informative hypertable version string
include(VersionHelper)

# Verison install directory
set(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/${VERSION})
set(INSTALL_DIR ${CMAKE_INSTALL_PREFIX})

find_package(Threads REQUIRED)
message(STATUS "Use thread library: ${CMAKE_THREAD_LIBS_INIT}")
find_package(Nodejs)
find_package(Python)
find_package(Boost REQUIRED)
find_package(BerkeleyDB REQUIRED)
find_package(EXPAT REQUIRED)
find_package(Editline REQUIRED)
find_package(SIGAR REQUIRED)
find_package(ZLIB REQUIRED)
find_package(BZip2 REQUIRED)
find_package(RE2 REQUIRED)
find_package(Snappy REQUIRED)
find_package(RRDtool REQUIRED)
find_package(Cronolog REQUIRED)
find_package(Doxygen)
find_package(Tcmalloc)
find_package(Jemalloc)
find_package(Hoard)
find_package(Mapr)
find_package(Qfs)
find_package(Ceph)
find_package(Maven REQUIRED)
find_package(JNI)
find_package(LibEvent REQUIRED)
find_package(Libssh REQUIRED)
find_package(Libssl REQUIRED)
find_package(Thrift REQUIRED)
find_package(RubyThrift)
find_package(PHP5Thrift)
find_package(PerlThrift)
find_package(PythonThrift)

# Apply sanitizer flags here — after find_package() — so that cmake's
# try_compile()/try_run() probes (e.g. FindSIGAR) are not run under the
# sanitizer and do not fail due to third-party leaks or instrumentation errors.
if (SANITIZE)
  set(_san_flags "-fsanitize=${SANITIZE} -fno-omit-frame-pointer -g")
  set(CMAKE_C_FLAGS              "${CMAKE_C_FLAGS}   ${_san_flags}")
  set(CMAKE_CXX_FLAGS            "${CMAKE_CXX_FLAGS} ${_san_flags}")
  set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    -fsanitize=${SANITIZE}")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=${SANITIZE}")
endif ()

# set malloc library (maybe) — skip when a sanitizer is active
if (SANITIZE)
  message(STATUS "Custom malloc disabled: incompatible with sanitizers")
elseif (USE_JEMALLOC)
  if (Jemalloc_FOUND)
    set(MALLOC_LIBRARY ${Jemalloc_LIBRARIES})
  else ()
    message(FATAL_ERROR "Unable to use jemalloc: library not found")
  endif ()
elseif (USE_HOARD)
  if (Hoard_FOUND)
    set(MALLOC_LIBRARY ${Hoard_LIBRARIES})
  else ()
    message(FATAL_ERROR "Unable to use hoard malloc: library not found")
  endif ()
elseif (NOT USE_GLIBC_MALLOC AND Tcmalloc_FOUND)
  if (NOT (CMAKE_BUILD_TYPE STREQUAL "Debug" OR APPLE) OR USE_TCMALLOC)
    set(MALLOC_LIBRARY ${Tcmalloc_LIBRARIES})
    if (USE_TCMALLOC)
      SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DTCMALLOC")
      SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DTCMALLOC")
    else ()
      SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DTCMALLOC_MINIMAL")
      SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DTCMALLOC_MINIMAL")
    endif ()
  endif ()
endif ()


if (APPLE)
   SET (CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework CoreFoundation")
endif ()

# include directories
include_directories(src/cc ${HYPERTABLE_BINARY_DIR}/src/cc
    ${ZLIB_INCLUDE_DIR} ${Boost_INCLUDE_DIRS}
    ${EXPAT_INCLUDE_DIRS} ${BDB_INCLUDE_DIR} ${EDITLINE_INCLUDE_DIR}
    ${SIGAR_INCLUDE_DIR})

if (Thrift_FOUND)
  include_directories(${LibEvent_INCLUDE_DIR} ${Thrift_INCLUDE_DIR})
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHT_WITH_THRIFT")
  SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHT_WITH_THRIFT")
  set(ThriftBroker_IDL_DIR ${HYPERTABLE_SOURCE_DIR}/src/cc/ThriftBroker)
endif ()

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-variadic-macros -Wno-deprecated")
  SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-variadic-macros -Wno-deprecated")
endif ()

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-terminate")
endif ()

include(HadoopHelper)
include(TestHelper)
include(DocHelper)

# sub-project directories
add_subdirectory(src)
add_subdirectory(java)
add_subdirectory(examples)
add_subdirectory(contrib)
add_subdirectory(tests/integration)

# Maven Repository
if (NOT MAVEN_REPOSITORY)
   SET (MAVEN_REPOSITORY "~/.m2/repository")
endif ()

# Java stuff
if (NOT SKIP_JAVA_BUILD)
  include(JavaHelper)
endif ()

configure_file(bin/ht.in bin/ht @ONLY)
configure_file(bin/postinst.in postinst @ONLY)
configure_file(bin/prerm.in prerm @ONLY)

file(GLOB CONFS conf/[^.]*)
install(FILES ${CONFS} DESTINATION conf)
install(PROGRAMS ${HYPERTABLE_BINARY_DIR}/bin/ht DESTINATION bin)

# Copy Thrift files
if (THRIFT_SOURCE_DIR)
  message(STATUS "Copying PHP files into installation")
  file(GLOB PHPFILES ${HYPERTABLE_SOURCE_DIR}/src/php/*.php)
  install(FILES ${PHPFILES} DESTINATION lib/php)
  if (EXISTS ${THRIFT_SOURCE_DIR}/lib/php/lib/Thrift)
    install(DIRECTORY ${THRIFT_SOURCE_DIR}/lib/php/lib/Thrift
            DESTINATION lib/php USE_SOURCE_PERMISSIONS)
  endif ()
  message(STATUS "Copying Perl files into installation")
  file(GLOB PERLFILES ${THRIFT_SOURCE_DIR}/lib/perl/lib/*.pm)
  install(FILES ${PERLFILES} DESTINATION lib/perl)
  if (EXISTS ${THRIFT_SOURCE_DIR}/lib/perl/lib/Thrift)
    install(DIRECTORY ${THRIFT_SOURCE_DIR}/lib/perl/lib/Thrift
            DESTINATION lib/perl USE_SOURCE_PERMISSIONS)
  endif ()
  message(STATUS "Copying Python files into installation")
  if (EXISTS ${THRIFT_SOURCE_DIR}/lib/py/src)
    install(DIRECTORY ${THRIFT_SOURCE_DIR}/lib/py/src/
            DESTINATION lib/py/thrift USE_SOURCE_PERMISSIONS)
  endif ()
  message(STATUS "Copying Ruby files into installation")
  file(GLOB RUBYFILES ${THRIFT_SOURCE_DIR}/lib/rb/lib/*.rb)
  install(FILES ${RUBYFILES} DESTINATION lib/rb)
  if (EXISTS ${THRIFT_SOURCE_DIR}/lib/rb/lib/thrift)
    install(DIRECTORY ${THRIFT_SOURCE_DIR}/lib/rb/lib/thrift
            DESTINATION lib/rb USE_SOURCE_PERMISSIONS)
  endif ()
endif ()

# Copy C++ Thrift files
install(DIRECTORY ${Thrift_INCLUDE_DIR} DESTINATION include USE_SOURCE_PERMISSIONS)

if (NOT HT_COMPONENT_INSTALL)
  file(GLOB SCRIPTS bin/*.sh)
  install(PROGRAMS ${SCRIPTS} DESTINATION bin)
  install(DIRECTORY examples/apache_log DESTINATION examples
          USE_SOURCE_PERMISSIONS)
  install(DIRECTORY examples/hql_tutorial DESTINATION examples
          USE_SOURCE_PERMISSIONS)
  install(DIRECTORY examples/freebase DESTINATION examples
          USE_SOURCE_PERMISSIONS)
  include(PackageHelper)
else ()
  install(PROGRAMS bin/ht-env.sh bin/fhsize.sh bin/rpm_pre_install.sh bin/rpm_post_install.sh DESTINATION bin)
endif ()

install(PROGRAMS "${CRONOLOG_DIR}/cronolog" DESTINATION sbin)
install(PROGRAMS "${NODEJS_EXECUTABLE}" DESTINATION sbin)
