#!/usr/bin/env bash

echo "========================================================================"
echo "HyperPython: SerizalizedCellsReader test"
echo "========================================================================"

SCRIPT_DIR=`dirname $0`

echo "SCRIPT_DIR is $SCRIPT_DIR"
echo "PYTHONPATH is $PYTHONPATH"

${HT_TSAN_PRELOAD:+env LD_PRELOAD=$HT_TSAN_PRELOAD} python3 $SCRIPT_DIR/reader.py > test-reader.txt
diff test-reader.txt $SCRIPT_DIR/test-reader.golden
if [ $? != 0 ]
then
  echo "golden file differs"
  exit 1
fi
