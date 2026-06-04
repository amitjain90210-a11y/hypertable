# Copyright (C) 2007-2016 Hypertable, Inc.
#
# This file is part of Hypertable.
#
# Hypertable is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or any later version.
#
# Hypertable is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hypertable. If not, see <http://www.gnu.org/licenses/>
#

# Redefine INSTALL_DIR to the build directory so that 'make alltests' and
# all add_test() calls with env INSTALL_DIR=... use the build tree rather
# than requiring 'make install' first.
set(INSTALL_DIR ${HYPERTABLE_BINARY_DIR})

# ---------------------------------------------------------------------------
# Set up a virtual directory layout in the build tree that mirrors the
# installation layout expected by the ht wrapper and test scripts.
# ---------------------------------------------------------------------------

set(BUILD_BIN_DIR ${HYPERTABLE_BINARY_DIR}/bin)
file(MAKE_DIRECTORY ${BUILD_BIN_DIR})
file(MAKE_DIRECTORY ${HYPERTABLE_BINARY_DIR}/run)
file(MAKE_DIRECTORY ${HYPERTABLE_BINARY_DIR}/log)

# Symlink every ht-*.sh script from the source bin dir into the build bin dir
# so that the ht wrapper and test scripts can find them at HYPERTABLE_HOME/bin/.
file(GLOB _source_bin_scripts LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/bin/*.sh)
foreach(_script ${_source_bin_scripts})
  get_filename_component(_name ${_script} NAME)
  execute_process(COMMAND ln -sf ${_script} ${BUILD_BIN_DIR}/${_name})
endforeach()

# Create a real conf/ directory in the build tree and symlink only the
# git-tracked conf files from the source tree.  Using a real directory (not
# a symlink to the source conf/) keeps runtime-generated files such as
# hadoop-distro out of the source tree.  Limiting to tracked files avoids
# picking up untracked user files (e.g. notification-hook.sh).
file(MAKE_DIRECTORY ${HYPERTABLE_BINARY_DIR}/conf)
execute_process(
  COMMAND git -C ${CMAKE_SOURCE_DIR} ls-files conf/
  OUTPUT_VARIABLE _tracked_conf_files
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(REPLACE "\n" ";" _tracked_conf_list "${_tracked_conf_files}")
foreach(_cf_rel ${_tracked_conf_list})
  get_filename_component(_cfname ${_cf_rel} NAME)
  if(NOT EXISTS ${HYPERTABLE_BINARY_DIR}/conf/${_cfname})
    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
                    ${CMAKE_SOURCE_DIR}/${_cf_rel}
                    ${HYPERTABLE_BINARY_DIR}/conf/${_cfname})
  endif()
endforeach()

# For TSan builds, symlink tsan.supp into conf/ so ht-start-test-servers.sh
# can locate it via $INSTALL_DIR/conf/tsan.supp without requiring make install.
if (SANITIZE STREQUAL "thread" AND EXISTS ${CMAKE_SOURCE_DIR}/tsan.supp)
  if(NOT EXISTS ${HYPERTABLE_BINARY_DIR}/conf/tsan.supp)
    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
                    ${CMAKE_SOURCE_DIR}/tsan.supp
                    ${HYPERTABLE_BINARY_DIR}/conf/tsan.supp)
  endif()
endif()

# For UBSan builds, symlink ubsan.supp into conf/ so ht-start-test-servers.sh
# can locate it via $INSTALL_DIR/conf/ubsan.supp without requiring make install.
if (SANITIZE STREQUAL "undefined" AND EXISTS ${CMAKE_SOURCE_DIR}/ubsan.supp)
  if(NOT EXISTS ${HYPERTABLE_BINARY_DIR}/conf/ubsan.supp)
    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
                    ${CMAKE_SOURCE_DIR}/ubsan.supp
                    ${HYPERTABLE_BINARY_DIR}/conf/ubsan.supp)
  endif()
endif()

# Symlink cronolog into sbin so the server startup scripts can find it.
file(MAKE_DIRECTORY ${HYPERTABLE_BINARY_DIR}/sbin)
if(NOT EXISTS ${HYPERTABLE_BINARY_DIR}/sbin/cronolog)
  execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
                  ${CRONOLOG_DIR}/cronolog ${HYPERTABLE_BINARY_DIR}/sbin/cronolog)
endif()

# ---------------------------------------------------------------------------
# Test server targets
# ---------------------------------------------------------------------------

# Use target names (not install paths) as dependencies so that the servers
# are built before trying to start them.
set(_test_server_targets htHyperspace htMaster htRangeServer htFsBrokerLocal)
if (Thrift_FOUND)
  list(APPEND _test_server_targets htThriftBroker)
endif ()
if (Ceph_FOUND)
  list(APPEND _test_server_targets htFsBrokerCeph)
endif ()

add_custom_target(runtestservers
  COMMAND ${BUILD_BIN_DIR}/ht-start-test-servers.sh --clear
  COMMENT "Starting test servers"
)
add_dependencies(runtestservers ${_test_server_targets})

macro(add_test_target target dir)
  add_custom_target(${target})
  add_dependencies(${target} runtestservers)
  if (SANITIZE STREQUAL "address")
    # Skip the 'ht' wrapper for ASAN builds: ht-env.sh prepends the installed
    # (non-ASAN) lib dir into LD_LIBRARY_PATH, which would cause the unfixed
    # installed libraries to load instead of the ASAN-built ones.  Running
    # ctest directly lets each binary's RUNPATH resolve to the ASAN build libs.
    add_custom_command(TARGET ${target} POST_BUILD
                       COMMAND ${CMAKE_COMMAND} -E env
                               "LSAN_OPTIONS=suppressions=${CMAKE_SOURCE_DIR}/lsan.supp"
                               $(MAKE) test
                       WORKING_DIRECTORY ${dir})
  else ()
    add_custom_command(TARGET ${target} POST_BUILD
                       COMMAND ${BUILD_BIN_DIR}/ht $(MAKE) test
                       WORKING_DIRECTORY ${dir})
  endif ()
endmacro()

# custom target must be globally unique to support IDEs like Xcode, VS etc.
add_test_target(alltests ${HYPERTABLE_BINARY_DIR})
add_test_target(coretests ${HYPERTABLE_BINARY_DIR}/src)
add_test_target(moretests ${HYPERTABLE_BINARY_DIR}/tests/integration)
