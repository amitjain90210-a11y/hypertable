#!/usr/bin/env bash
#
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

INSTALL_DIR=${INSTALL_DIR:-$(cd `dirname $0`/.. && pwd)}
HT_TEST_FS=${HT_TEST_FS:-local}

usage_exit() {
  echo
  echo "usage: ht-start-test-servers.sh [OPTIONS] [<global-options>]"
  echo
  echo "OPTIONS:"
  echo "  --clear                  Destroy existing database before starting servers"
  echo "  -h,--help                Display usage information"
  echo "  --no-master              Do not launch the Master"
  echo "  --no-rangeserver         Do not launch the RangeServer"
  echo "  --no-thriftbroker        Do not launch the ThriftBroker"
  echo "  --valgrind-hyperspace    Pass --valgrind option to ht-start-hyperspace.sh"
  echo "  --valgrind-master        Pass --valgrind option to ht-start-master.sh"
  echo "  --heapcheck-rangeserver  Pass --heapcheck option to ht-start-rangeserver.sh"
  echo "  --valgrind-rangeserver   Pass --valgrind option to ht-start-rangeserver.sh"
  echo "  --valgrind-thriftbroker  Pass --valgrind option to ht-start-thriftbroker.sh"
  echo
  echo "Starts all Hypertable processes on localhost.  By default, the local filesystem"
  echo "broker is started.  Alternatively, the environment varibale HT_TEST_FS can be"
  echo "set to any valid filesystem specifier to control which filesystem broker to"
  echo "start.  Valid filesystem specifiers include \"local\", \"hadoop\", \"ceph\", \"mapr\","
  echo "and \"qfs\".  This value is passed directly to the ht-start-fsbroker.sh script."
  echo
  echo "The script first stops all Hypertable processes with a call to"
  echo "ht-stop-servers.sh.  If the --clear option is specified, the script will instead"
  echo "start the filesystem broker and then destroy the database with a call to"
  echo "ht-destroy-database.sh."
  echo
  echo "Once the Hypertable processes are stopped, the hypertable processes are started"
  echo "with a call to ht-start-all-servers.sh."
  echo
  echo "The <global-options> are passed to all scripts run by this script."
  echo
  exit 0
}

while [ $# -gt 0 ]; do
  case $1 in
    --clear)              clear=1;;
    -h|--help)            usage_exit;;
    --val*|--no*|--heap*) opts[${#opts[*]}]=$1;;
    *)                    break;;
  esac
  shift
done

# For TSan builds, ensure server processes inherit halt_on_error and suppressions.
# tsan.supp is installed to conf/ only when the build was configured with
# SANITIZE=tsan, so its presence reliably indicates a TSan build.
_tsan_supp="$INSTALL_DIR/conf/tsan.supp"
if [ -z "$TSAN_OPTIONS" ] && [ -f "$_tsan_supp" ]; then
  export TSAN_OPTIONS="suppressions=$_tsan_supp:halt_on_error=1"
fi
unset _tsan_supp

# For UBSan builds, ensure server processes inherit halt_on_error.
# ubsan.supp is installed to conf/ only when the build was configured with
# SANITIZE=ubsan, so its presence reliably indicates a UBSan build.
if [ -z "$UBSAN_OPTIONS" ] && [ -f "$INSTALL_DIR/conf/ubsan.supp" ]; then
  export UBSAN_OPTIONS="suppressions=$INSTALL_DIR/conf/ubsan.supp:halt_on_error=1:print_stacktrace=1"
fi

if [ "$clear" ]; then
  $INSTALL_DIR/bin/ht-start-fsbroker.sh $HT_TEST_FS
  $INSTALL_DIR/bin/ht destroy-database "$@"
else
  $INSTALL_DIR/bin/ht stop servers "$@"
fi

$INSTALL_DIR/bin/ht start all-servers "${opts[@]}" $HT_TEST_FS "$@"
