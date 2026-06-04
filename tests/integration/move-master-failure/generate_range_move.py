#!/usr/bin/env python3

import sys

# Python 3 Thrift's binary_to_str decodes bytes as strict UTF-8, which fails
# for METADATA row keys containing binary end-row markers (\xff\xff).
# Patch to use errors='replace' so those bytes become replacement chars instead
# of raising UnicodeDecodeError.
if sys.version_info[0] >= 3:
    import thrift.compat
    thrift.compat.binary_to_str = lambda b: b.decode('utf-8', errors='replace')

import random
import time
from hypertable.thriftclient import *
from hyperthrift.gen.ttypes import *

if (len(sys.argv) < 2):
  print(sys.argv[0], "<duration-seconds>")
  sys.exit(1)

duration=int(sys.argv[1])

def is_ascii(s):
  if s is None:
    return True
  if isinstance(s, (bytes, bytearray)):
    return all(b < 128 for b in s)
  return all(ord(c) < 128 for c in s)

try:
  client = ThriftClient("localhost", 15867)

  namespace = client.open_namespace("/sys")

  scanner = client.open_scanner(namespace, "METADATA",
                                ScanSpec(None, None, None, 1, 0, None, None, ["StartRow","Location"]))

  ranges = [ ]
  cur = { }

  while True:
    cells = client.next_cells(scanner)
    if (len(cells) == 0):
      break
    for cell in cells:
      colon = cell.key.row.find(":")
      if not 'TableId' in cur or not 'EndRow' in cur:
        cur = { }
        cur['TableId'] = cell.key.row[:colon]
        cur['EndRow'] = cell.key.row[colon+1:]
      elif cell.key.row[:colon] != cur['TableId'] or cell.key.row[colon+1:] != cur['EndRow']:
        ranges.append(cur)
        cur = { }
        cur['TableId'] = cell.key.row[:colon]
        cur['EndRow'] = cell.key.row[colon+1:]
      if cell.key.column_family == "StartRow":
        cur['StartRow'] = cell.value.decode('latin-1') if cell.value else None
      elif cell.key.column_family == "Location":
        cur['Location'] = cell.value.decode('latin-1') if cell.value else None
      else:
        print("Unrecognized column family'%s'" % (cell.key.column_family))
        sys.exit(1)

  if 'StartRow' in cur:
    ranges.append(cur)

  client.close_namespace(namespace)

  # Skip ranges with non-ASCII row keys (system ranges using binary \xff markers)
  user_ranges = [r for r in ranges
                 if is_ascii(r.get('EndRow')) and is_ascii(r.get('StartRow'))]

  if not user_ranges:
    print("No ASCII ranges found in METADATA")
    sys.exit(1)

  offset = random.randint(0, len(user_ranges)-1)

  if user_ranges[offset]['Location'] == "rs1":
    destination = "rs2"
  elif user_ranges[offset]['Location'] == "rs2":
    destination = "rs1"
  else:
    print("Unexpected destination: %s" % (user_ranges[offset]['Location']))
    sys.exit(1)

  if user_ranges[offset].get('StartRow') is None:
    print('balance (\"%s\"[..\"%s\"], \"%s\", \"%s\") duration=%d;' % (user_ranges[offset]['TableId'], user_ranges[offset]['EndRow'], user_ranges[offset]['Location'], destination, duration))
  else:
    print('balance (\"%s\"[\"%s\"..\"%s\"], \"%s\", \"%s\") duration=%d;' % (user_ranges[offset]['TableId'], user_ranges[offset]['StartRow'], user_ranges[offset]['EndRow'], user_ranges[offset]['Location'], destination, duration))

except ClientException as e:
  print('%s' % (e.message))
