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

# - Find Maven (a java build tool)
# This module defines
#  MAVEN_VERSION version string of maven if found
#  MAVEN_FOUND, If false, do not try to use maven

execute_process(COMMAND env mvn -version
                OUTPUT_VARIABLE MAVEN_OUTPUT
                RESULT_VARIABLE MAVEN_RETURN
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET)

if (MAVEN_RETURN STREQUAL "0")
   string(REPLACE ";" " " MAVEN_OUTPUT2 ${MAVEN_OUTPUT})
   string(REPLACE "\n" ";" MAVEN_OUTPUT3 ${MAVEN_OUTPUT2})
   list(GET MAVEN_OUTPUT3 0 MAVEN_VERSION)
   set(MAVEN_FOUND TRUE)
   if (NOT MAVEN_FIND_QUIETLY)
      message(STATUS "Found Maven: ${MAVEN_VERSION}")
   endif ()
else ()
  message(STATUS "Maven: not found")
  set(MAVEN_FOUND FALSE)
  set(SKIP_JAVA_BUILD TRUE)
endif ()

execute_process(COMMAND env javac -version
                OUTPUT_VARIABLE JAVAC_OUT
                ERROR_VARIABLE JAVAC_ERR
                RESULT_VARIABLE JAVAC_RETURN
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE)
string(APPEND JAVAC_OUT "${JAVAC_ERR}")

if (JAVAC_RETURN STREQUAL "0")
  message(STATUS "    Javac: ${JAVAC_OUT}")
  string(REGEX MATCH "(1\\.[6-9]\\.[0-9]|[1-9][0-9]+\\.[0-9])" JAVAC_VERSION ${JAVAC_OUT})

  if (NOT JAVAC_VERSION)
    message(STATUS "    Expected JDK 1.6 or greater. Skipping Java build")
    set(SKIP_JAVA_BUILD TRUE)
  endif ()
else ()
  message(STATUS "    Javac: not found")
  set(SKIP_JAVA_BUILD TRUE)
endif ()
