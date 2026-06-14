# Error Codes

We try to always make Hypertable generate useful, human readable error messages, but if you encounter an error code, this table will help you determine what it means.

###

Code
(hexidecimal) |  Code
(decimal) |  Description
---|---|---
|  `-3` |  But that's unpossible!
|  `-2` |  External error
|  `-1` |  HYPERTABLE failed expectation
`0x0` |  `0` |  HYPERTABLE ok
`0x1` |  `1` |  HYPERTABLE protocol error
`0x2` |  `2` |  HYPERTABLE request truncated
`0x3` |  `3` |  HYPERTABLE response truncated
`0x4` |  `4` |  HYPERTABLE request timeout
`0x5` |  `5` |  HYPERTABLE local i/o error
`0x6` |  `6` |  HYPERTABLE bad root location
`0x7` |  `7` |  HYPERTABLE bad schema
`0x8` |  `8` |  HYPERTABLE invalid metadata
`0x9` |  `9` |  HYPERTABLE bad key
`0xa` |  `10` |  HYPERTABLE metadata not found
`0xb` |  `11` |  HYPERTABLE HQL parse error
`0xc` |  `12` |  HYPERTABLE file not found
`0xd` |  `13` |  HYPERTABLE block compressor unsupported type
`0xe` |  `14` |  HYPERTABLE block compressor invalid arg
`0xf` |  `15` |  HYPERTABLE block compressor block truncated
`0x10` |  `16` |  HYPERTABLE block compressor bad block header
`0x11` |  `17` |  HYPERTABLE block compressor bad magic string
`0x12` |  `18` |  HYPERTABLE block compressor block checksum mismatch
`0x13` |  `19` |  HYPERTABLE block compressor deflate error
`0x14` |  `20` |  HYPERTABLE block compressor inflate error
`0x15` |  `21` |  HYPERTABLE block compressor initialization error
`0x16` |  `22` |  HYPERTABLE table does not exist
`0x1a` |  `26` |  HYPERTABLE command parse error
`0x1b` |  `27` |  HYPERTABLE Master connect error
`0x1c` |  `28` |  HYPERTABLE Hyperspace client connect error
`0x18` |  `24` |  HYPERTABLE too many columns
`0x19` |  `25` |  HYPERTABLE bad domain name
`0x17` |  `23` |  HYPERTABLE malformed request
`0x1d` |  `29` |  HYPERTABLE bad memory allocation
`0x1e` |  `30` |  HYPERTABLE bad scan specification
`0x1f` |  `31` |  HYPERTABLE not implemented
`0x20` |  `32` |  HYPERTABLE version mismatch
`0x21` |  `33` |  HYPERTABLE cancelled
`0x22` |  `34` |  HYPERTABLE schema parse error
`0x23` |  `35` |  HYPERTABLE syntax error
`0x24` |  `36` |  HYPERTABLE double unget
`0x25` |  `37` |  HYPERTABLE empty bloom filter
`0x26` |  `38` |  HYPERTABLE bloom filter checksum mismatch
`0x27` |  `39` |  HYPERTABLE name already in use
`0x28` |  `40` |  HYPERTABLE namespace does not exist
`0x29` |  `41` |  HYPERTABLE bad namespace
`0x2a` |  `42` |  HYPERTABLE namespace exists
`0x2b` |  `43` |  HYPERTABLE no response
`0x2c` |  `44` |  HYPERTABLE not allowed
`0x2d` |  `45` |  HYPERTABLE induced failure
`0x2e` |  `46` |  HYPERTABLE server shutting down
`0x2f` |  `47` |  HYPERTABLE location unassigned
`0x30` |  `48` |  HYPERTABLE cell already exists
`0x31` |  `49` |  HYPERTABLE checksum mismatch
`0x3e9` |  `1001` |  CONFIG bad argument(s)
`0x3ea` |  `1002` |  CONFIG bad cfg file
`0x3eb` |  `1003` |  CONFIG failed to get config value
`0x3ec` |  `1004` |  CONFIG bad config value
`0x10001` |  `65537` |  COMM not connected
`0x10002` |  `65538` |  COMM broken connection
`0x10003` |  `65539` |  COMM connect error
`0x10004` |  `65540` |  COMM already connected
`0x10006` |  `65542` |  COMM send error
`0x10007` |  `65543` |  COMM receive error
`0x10008` |  `65544` |  COMM poll error
`0x10009` |  `65545` |  COMM conflicting address
`0x1000a` |  `65546` |  COMM socket error
`0x1000b` |  `65547` |  COMM bind error
`0x1000c` |  `65548` |  COMM listen error
`0x1000d` |  `65549` |  COMM header checksum mismatch
`0x1000e` |  `65550` |  COMM payload checksum mismatch
`0x1000f` |  `65551` |  COMM bad header
`0x10010` |  `65552` |  COMM invalid proxy
`0x20001` |  `131073` |  DFS BROKER bad file handle
`0x20002` |  `131074` |  DFS BROKER i/o error
`0x20003` |  `131075` |  DFS BROKER file not found
`0x20004` |  `131076` |  DFS BROKER bad filename
`0x20005` |  `131077` |  DFS BROKER permission denied
`0x20006` |  `131078` |  DFS BROKER invalid argument
`0x20007` |  `131079` |  DFS BROKER invalid config value
`0x20008` |  `131080` |  DFS BROKER end of file
`0x30001` |  `196609` |  HYPERSPACE i/o error
`0x30002` |  `196610` |  HYPERSPACE create failed
`0x30003` |  `196611` |  HYPERSPACE file not found
`0x30004` |  `196612` |  HYPERSPACE attribute not found
`0x30005` |  `196613` |  HYPERSPACE delete error
`0x30006` |  `196614` |  HYPERSPACE bad pathname
`0x30007` |  `196615` |  HYPERSPACE permission denied
`0x30008` |  `196616` |  HYPERSPACE expired session
`0x30009` |  `196617` |  HYPERSPACE file exists
`0x3000a` |  `196618` |  HYPERSPACE is directory
`0x3000b` |  `196619` |  HYPERSPACE invalid handle
`0x3000c` |  `196620` |  HYPERSPACE request cancelled
`0x3000d` |  `196621` |  HYPERSPACE mode restriction
`0x3000e` |  `196622` |  HYPERSPACE already locked
`0x3000f` |  `196623` |  HYPERSPACE lock conflict
`0x30010` |  `196624` |  HYPERSPACE not locked
`0x30011` |  `196625` |  HYPERSPACE bad attribute
`0x30012` |  `196626` |  HYPERSPACE Berkeley DB error
`0x30013` |  `196627` |  HYPERSPACE directory not empty
`0x30014` |  `196628` |  HYPERSPACE Berkeley DB deadlock
`0x30015` |  `196629` |  HYPERSPACE Berkeley DB replication handle dead
`0x30016` |  `196630` |  HYPERSPACE file open
`0x30017` |  `196631` |  HYPERSPACE CLI parse error
`0x30018` |  `196632` |  HYPERSPACE unable to create session
`0x30019` |  `196633` |  HYPERSPACE not master location
`0x3001a` |  `196634` |  HYPERSPACE State DB error
`0x3001b` |  `196635` |  HYPERSPACE State DB deadlock
`0x3001c` |  `196636` |  HYPERSPACE State DB bad key
`0x3001d` |  `196637` |  HYPERSPACE State DB bad value
`0x3001e` |  `196638` |  HYPERSPACE State DB attempt to access/delete previously deleted state
`0x3001f` |  `196639` |  HYPERSPACE State DB event exists
`0x30020` |  `196640` |  HYPERSPACE State DB event does not exist
`0x30021` |  `196641` |  HYPERSPACE State DB event attr not found
`0x30022` |  `196642` |  HYPERSPACE State DB session exists
`0x30023` |  `196643` |  HYPERSPACE State DB session does not exist
`0x30024` |  `196644` |  HYPERSPACE State DB session attr not found
`0x30025` |  `196645` |  HYPERSPACE State DB handle exists
`0x30026` |  `196646` |  HYPERSPACE State DB handle does not exist
`0x30027` |  `196647` |  HYPERSPACE State DB handle attr not found
`0x30028` |  `196648` |  HYPERSPACE State DB node exists
`0x30029` |  `196649` |  HYPERSPACE State DB node does not exist
`0x3002a` |  `196650` |  HYPERSPACE State DB node attr not found
`0x40001` |  `262145` |  MASTER table exists
`0x40002` |  `262146` |  MASTER bad schema
`0x40003` |  `262147` |  MASTER not running
`0x40004` |  `262148` |  MASTER no range servers
`0x40005` |  `262149` |  MASTER file not locked
`0x40006` |  `262150` |  MASTER range server with same location already registered
`0x40007` |  `262151` |  MASTER bad column family
`0x40008` |  `262152` |  Master schema generation mismatch
`0x40009` |  `262153` |  MASTER location already assigned
`0x4000a` |  `262154` |  MASTER location invalid
`0x4000b` |  `262155` |  MASTER operation in progress
`0x50001` |  `327681` |  RANGE SERVER generation mismatch
`0x50002` |  `327682` |  RANGE SERVER range already loaded
`0x50003` |  `327683` |  RANGE SERVER range mismatch
`0x50004` |  `327684` |  RANGE SERVER non-existent range
`0x50005` |  `327685` |  RANGE SERVER out of range
`0x50006` |  `327686` |  RANGE SERVER range not found
`0x50007` |  `327687` |  RANGE SERVER invalid scanner id
`0x50008` |  `327688` |  RANGE SERVER schema parse error
`0x50009` |  `327689` |  RANGE SERVER invalid column family id
`0x5000a` |  `327690` |  RANGE SERVER invalid column family
`0x5000b` |  `327691` |  RANGE SERVER truncated commit log
`0x5000c` |  `327692` |  RANGE SERVER no metadata for range
`0x5000d` |  `327693` |  RANGE SERVER shutting down
`0x5000e` |  `327694` |  RANGE SERVER corrupt commit log
`0x5000f` |  `327695` |  RANGE SERVER unavailable
`0x50010` |  `327696` |  RANGE SERVER supplied revision is not strictly increasing
`0x50011` |  `327697` |  RANGE SERVER row overflow
`0x50012` |  `327698` |  RANGE SERVER table not found
`0x50013` |  `327699` |  RANGE SERVER bad scan specification
`0x50014` |  `327700` |  RANGE SERVER clock skew detected
`0x50015` |  `327701` |  RANGE SERVER bad CellStore filename
`0x50016` |  `327702` |  RANGE SERVER corrupt CellStore
`0x50017` |  `327703` |  RANGE SERVER table dropped
`0x50018` |  `327704` |  RANGE SERVER unexpected table ID
`0x50019` |  `327705` |  RANGE SERVER range busy
`0x5001a` |  `327706` |  RANGE SERVER bad cell interval
`0x5001b` |  `327707` |  RANGE SERVER short cellstore read
`0x5001c` |  `327708` |  RANGE SERVER range no longer active
`0x60001` |  `393217` |  HQL bad load file format
`0x70001` |  `458753` |  METALOG version mismatch
`0x70002` |  `458754` |  METALOG bad range server metalog header
`0x70003` |  `458755` |  METALOG bad metalog header
`0x70004` |  `458756` |  METALOG entry truncated
`0x70005` |  `458757` |  METALOG checksum mismatch
`0x70006` |  `458758` |  METALOG bad entry type
`0x70007` |  `458759` |  METALOG entry out of order
`0x80001` |  `524289` |  SERIALIZATION input buffer overrun
`0x80002` |  `524290` |  SERIALIZATION bad vint encoding
`0x80003` |  `524291` |  SERIALIZATION bad vstr encoding
`0x90001` |  `589825` |  THRIFT BROKER bad scanner id
`0x90002` |  `589826` |  THRIFT BROKER bad mutator id
`0x90003` |  `589827` |  THRIFT BROKER bad namespace id
`0x90004` |  `589828` |  THRIFT BROKER bad future id
