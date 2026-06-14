# Thrift API Reference

## Table of Contents

### Namespaces

####  namespace_open

This function opens a namespace, creating a namespace object within the ThriftBroker. It returns an ID that refers to the namespace object and can be used in subsequent operations.

**DEFINITION**

    Namespace namespace_open(1:string ns) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Full namespace path to open

**RETURN VALUE**

Reference to open namespace.

* * *

####  namespace_close

This function closes a namespace.

**DEFINITION**

    void namespace_close(1:Namespace ns) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace Identifier

* * *

####  namespace_create

Creates a namespace.

**DEFINITION**

    void namespace_create(1:string ns) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Full namespace path to create

* * *

####  namespace_drop

Drops (deletes) a namespace.

**DEFINITION**

      void namespace_drop(1:string ns, 2:bool if_exists = 1)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Full path of namespace to drop
_if_exists_ |  Boolean flag that prevents the operation from returning an error if the namespace path does not exist.

* * *

####  namespace_exists

Checks for the existence of a namespace.

**DEFINITION**

      bool namespace_exists(1:string ns) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Full path of namespace to check the existence of

**RETURN VALUE**

_true_ if exists, _false_ otherwise.

* * *

####  namespace_get_listing

Lists the contents of a namespace. Checks for the existence of a namespace.

**DEFINITION**

    list < NamespaceListing > namespace_get_listing(1:Namespace ns)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier

**RETURN VALUE**

List of NamespaceListing objects.

* * *

### Tables

####  table_create

Creates a table

**DEFINITION**

    void table_create(1:Namespace ns, 2:string name,
                    3:Schema schema) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table to drop
_name_ |  Name of table to create
_schema_ |  Schema of the table (in xml)

* * *

####  table_alter

Alters the schema of a table

**DEFINITION**

    void table_alter(1:Namespace ns, 2:string name,
                    3:Schema schema) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table to drop
_name_ |  Name of table to be altered
_schema_ |  Schema of the table returned by [table_get_schema](thrift_api.md#tablegetschema) and then modified as desired.

* * *

####  table_drop

Drops (deletes) a table

**DEFINITION**

    void table_drop(1:Namespace ns, 2:string name,
                    3:bool if_exists = 1) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table to drop
_name_ |  Name of table to drop
_if_exists_ |  Boolean flag that prevents the operation from generating an error if the table does not exist

* * *

####  table_rename

Renames a table

**DEFINITION**

    void table_rename(1:Namespace ns, 2:string name, 3:string new_name)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table to rename
_name_ |  Name of table to rename
_new_name_ |  New name for table

* * *

####  table_exists

Checks for the existence of a table

**DEFINITION**

    bool table_exists(1:Namespace ns, 2:string name) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table to check for existence
_name_ |  Name of table to check for existence

**RETURN VALUE**

_true_ if table exists, _false_ othterwise

* * *

####  table_get_schema

Get the Schema object representing the table definition

**DEFINITION**

    Schema table_get_schema(1:Namespace ns, 2:string table_name)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table for which to fetch schema
_table_name_ |  Name of table for which to fetch schema

**RETURN VALUE**

Schema object representing table definition

* * *

####  table_get_schema_str

Get the schema XML string representing the table definition

**DEFINITION**

    string table_get_schema_str(1:Namespace ns, 2:string table_name)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table for which to fetch schema
_table_name_ |  Name of table for which to fetch schema

**RETURN VALUE**

XML schema string representing table definition

* * *

####  table_get_schema_str_with_ids

Get the schema XML string, containing internal column identifiers, representing the table definition

**DEFINITION**

    string table_get_schema_str_with_ids(1:Namespace ns, 2:string table_name)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table for which to fetch schema
_table_name_ |  Name of table for which to fetch schema

**RETURN VALUE**

XML schema string, containing column identifiers, representing table definition

* * *

####  table_get_id

Fetch the internal table identifier

**DEFINITION**

    string table_get_id(1:Namespace ns, 2:string table_name)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table for which to fetch identifier
_table_name_ |  Name of table for which to fetch identifier

**RETURN VALUE**

String representing table identifier

* * *

####  table_get_splits

Fetch table splits. This method is used by the MapReduce framework to obtian table splits for the map phase.

**DEFINITION**

    list < TableSplit > table_get_splits(1:Namespace ns, 2:string table_name)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table for which to fetch table splits
_table_name_ |  Name of table for which to fetch table splits

**RETURN VALUE**

List of TableSplit objects for table

* * *

### HQL

####  hql_exec

Versatile method to execute an HQL statement

**DEFINITION**

      HqlResult hql_exec(1:i64 ns, 2:string command, 3:bool noflush, 4:bool unbuffered)
        throws (1:Client.ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace context within which to execute HQL command
_command_ |  HQL command to execute
_noflush_ |  Do not auto commit any modifications (return a Mutator)
_unbuffered_ |  Return a Scanner instead of buffered results

**RETURN VALUE**

HqlResult containing the result of the HQL command

* * *

####  hql_query

Convenience method for executing an buffered and flushed HQL command

**DEFINITION**

      HqlResult hql_query(1:i64 ns, 2:string command)
        throws (1:Client.ClientException e)

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace context within which to execute HQL command
_command_ |  HQL command to execute

**RETURN VALUE**

HqlResult containing the result of the HQL command

* * *

####  hql_query_as_arrays

Convenience method for executing an buffered and flushed HQL command. Similar to the hql_query method, except returns an HqlResultAsArrays object which can be more efficient to decode for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

**DEFINITION**

    HqlResultAsArrays hql_query_as_arrays(1:i64 ns, 2:string command)
        throws (1:Client.ClientException e)

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace context within which to execute HQL command
_command_ |  HQL command to execute

**RETURN VALUE**

HqlResultAsArrays containing the result of the HQL command

* * *

### Mutator

####  mutator_open

Creates a table mutator. There are two different types of mutators that can be created by this function which are described as follows.

_Normal Mutator_

This is the type of mutator that most applications should use. It will buffer mutations in the ThriftBroker and will flush the mutations to the Hypertable RangeServers when either the buffers fill up or mutator_flush function is called. Any errors encountered will get propagated back to the client application via exceptions. To create this type of mutator, pass a value of 0 for the `flush_interval` argument.

_Periodic Flush Mutator_

This type of mutator is unreliable and should only be used if data loss is tolerable. This type of mutator works by creating a background thread and flushing the mutations to the Hypertable RangeServer every `flush_interval` milliseconds. If errors are encountered during a flush, the errors are buried and not propagated back to the client application. To create this type of mutator, pass a non-zero value for the `flush_interval` argument.

**DEFINITION**

    Mutator mutator_open(1:Namespace ns, 2:string table_name,
                         3:i32 flags, 4:i32 flush_interval)
                         throws (1:ClientException e),

**PARAMETERS**

-

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table on which to create mutator
_table_name_ |  Name of table on which to create mutator
_flags_ |  Bitmask of MutatorFlag that control the behavior of the table mutator
_flush_interval_ |  Auto-flush interval in milliseconds; 0 disables it.

**RETURN VALUE**

Opaque identifier for table mutator

* * *

####  mutator_close

Closes a table mutator

**DEFINITION**

    void mutator_close(1:Mutator mutator) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator to close

* * *

####  mutator_flush

Flushes the mutator by sending all buffered updates to the appropriate RangeServers

**DEFINITION**

    void mutator_flush(1:Mutator mutator) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator to flush

* * *

####  mutator_set_cell

Mutates the table by inserting the given Cell object. The cell may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void mutator_set_cell(1:Mutator mutator, 2:Cell cell) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator on which to insert cell
_cell_ |  Cell object to insert via mutator

* * *

####  mutator_set_cell_as_array

Mutates the table by inserting the given CellAsArray object. This method is similar to the mutator_set_cell method except that it inserts a CellAsArray object which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string). The cell may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void mutator_set_cell_as_array(1:Mutator mutator, 2:CellAsArray cell) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator on which to insert cell
_cell_ |  CellAsArray object to insert via mutator

* * *

####  mutator_set_cells

Mutates the table by inserting the given list of Cell objects. The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void mutator_set_cells(1:Mutator mutator, 2:list < Cell > cells)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator on which to insert cells
_cells_ |  List of Cell objects representing cells to insert via mutator

* * *

####  mutator_set_cells_as_arrays

Mutates the table by inserting the given list of CellAsArray objects. This method is similar to the mutator_set_cells method except that it inserts a list of CellAsArray objects which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string). The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void mutator_set_cells_as_arrays(1:Mutator mutator, 2:list < CellAsArray > cells)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator on which to insert list of cells
_cells_ |  List of CellAsArray objects representing cells to insert via mutator

* * *

####  mutator_set_cells_serialized

Mutates the table by inserting the given list of cells contained in a CellsSerialized object. This method is similar to the mutator_set_cells method except that it accepts a CellsSerialized object which is fairly efficient to encode and decode. The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when mutator_flush is called, or the mutator is closed.

_Note:_ The class `SerializedCellsWriter` that is used to create CellsSerialized objects is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

      void mutator_set_cells_serialized(1:Mutator mutator, 2:CellsSerialized cells,
                                   3:bool flush = 0) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of mutator on which to insert cells
_cells_ |  CellsSerialized object containing list of cells to insert via mutator
_flush_ |  Boolean flag to cause a mutator flush after the cells have been inserted

* * *

### Scanner

####  scanner_open

Opens a table scanner

**DEFINITION**

      Scanner scanner_open(1:Namespace ns, 2:string table_name,
                           3:ScanSpec scan_spec) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table on which to create scanner
_table_name_ |  Name of table on which to create scanner
_scan_spec_ |  ScanSpec object representing query predicate. It defines what cells will be returned by the scanner

**RETURN VALUE**

Opaque identifier for table scanner

* * *

####  scanner_close

Closes a table scanner

**DEFINITION**

    void scanner_close(1:Scanner scanner) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_scanner_ |  Opaque identifier of scanner to close

* * *

####  scanner_get_cells

Fetches the next block of cells from an existing scan

**DEFINITION**

    list < Cell > scanner_get_cells(1:Scanner scanner)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_scanner_ |  Opaque identifier of scanner from which to fetch the next block of cells

**RETURN VALUE**

List of cells returned by the scanner

* * *

####  scanner_get_cells_as_arrays

Fetches the next block of cells from an existing scan. Similar to scanner_get_cells, except that it returns a list of CellAsArray objects which are more efficient in languages (e.g. Ruby) where object creation overhead is very high.

**DEFINITION**

    list < CellAsArray > scanner_get_cells_as_arrays(1:Scanner scanner)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_scanner_ |  Opaque identifier of scanner from which to fetch the next block of cells

**RETURN VALUE**

List of cells returned by the scanner

* * *

####  scanner_get_cells_serialized

Fetches the next block of cells from an existing scan. Similar to scanner_get_cells except that it returns a CellsSerialized object which is fairly efficient to encode and decode.

_Note:_ The class `SerializedCellsReader` that is used to read cells from a CellsSerialized object is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

    CellsSerialized scanner_get_cells_serialized(1:Scanner scanner)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_scanner_ |  Opaque identifier of scanner from which to fetch the next block of cells

**RETURN VALUE**

List of cells returned by the scanner

* * *

### Asynchronous

####  async_mutator_open

Opens an asynchronous table mutator

**DEFINITION**

    MutatorAsync async_mutator_open(1:Namespace ns, 2:string table_name, 3:Future future,
          4:i32 flags = 0) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier representing namespace containing table on which to create asynchronous mutator
_table_name_ |  Name of table on which to create asynchronous mutator
_future_ |  Reference to future object that can be used to obtain the result of the asynchronous mutation
_flags_ |  Bitmask of MutatorFlag that control the behavior of the asynchronous table mutator

**RETURN VALUE**

Opaque identifier of asynchronous table mutator

* * *

####  async_mutator_close

Closes an asynchronous table mutator

**DEFINITION**

    void async_mutator_close(1:MutatorAsync mutator) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of asynchronous mutator to close

* * *

####  async_mutator_flush

Flush asynchronous mutator buffers, sending all pending updates to the RangeServers for which they are destined.

**DEFINITION**

    void async_mutator_flush(1:MutatorAsync mutator) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Opaque identifier of asynchronous mutator to flush

* * *

####  async_scanner_open

Opens an asynchronous table scanner which can be used to query a table asynchronously.

**DEFINITION**

    ScannerAsync async_scanner_open(1:Namespace ns, 2:string table_name, 3:Future future, 4:ScanSpec scan_spec)
       throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table on which to create asynchronous scanner
_table_name_ |  Name of table on which to create asynchronous scanner
_future_ |  Reference to future object that can be used to obtain the result of the asynchronous scan
_scan_spec_ |  ScanSpec object representing scan predicate, defining what cells will be returned by the scanner

**RETURN VALUE**

Opaque identifier of asynchronous table scanner

* * *

####  async_scanner_close

Closes an asynchronous table scanner

**DEFINITION**

    void async_scanner_close(1:ScannerAsync scanner) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_scanner_ |  Opaque identifier of asynchronous scanner to close

* * *

####  async_mutator_set_cell

Mutates the table by inserting the given Cell object. The cell may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when async_mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void async_mutator_set_cell(1:MutatorAsync mutator, 2:Cell cell)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Reference to asynchronous mutator through which to insert the cell
_cell_ |  Cell object to insert

* * *

####  async_mutator_set_cell_as_array

Mutates the table by inserting the given CellAsArray object. This method is similar to the async_mutator_set_cell method except that it inserts a CellAsArray object which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string). The cell may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when async_mutator_flush is called, or the mutator is closed.

**DEFINITION**

      void async_mutator_set_cell_as_array(1:MutatorAsync mutator, 2:CellAsArray cell)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Reference to asynchronous mutator through which to insert the cell
_cell_ |  CellAsArray object to insert

* * *

####  async_mutator_set_cells

Mutates the table by inserting the given list of Cell objects. The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when async_mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void async_mutator_set_cells(1:Mutator mutator, 2:list < Cell > cells)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Reference to asynchronous mutator through which to insert the cells
_cells_ |  List of Cell objects to insert

* * *

####  async_mutator_set_cells_as_arrays

Mutates the table by inserting the given list of CellAsArray objects. This method is similar to the async_mutator_set_cells method except that it inserts a list of CellAsArray objects which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string). The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when async_mutator_flush is called, or the mutator is closed.

**DEFINITION**

    void mutator_set_cells_as_arrays(1:Mutator mutator, 2:list < CellAsArray > cells)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Reference to asynchronous mutator through which to insert the list of cells
_cells_ |  List of CellAsArray objects to insert

* * *

####  async_mutator_set_cells_serialized

Mutates the table by inserting the given list of cells contained in a CellsSerialized object. This method is similar to the async_mutator_set_cells method except that it accepts a CellsSerialized object which is fairly efficient to encode and decode. The cells may be buffered client-side and will be flushed (persisted) when the client side cell buffers fill up, or when async_mutator_flush is called, or the mutator is closed.

_Note:_ The class `SerializedCellsWriter` that is used to create CellsSerialized objects is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

      void async_mutator_set_cells_serialized(1:Mutator mutator, 2:CellsSerialized cells, 3:bool flush = 0)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_mutator_ |  Reference to asynchronous mutator through which to insert the list of cells
_cells_ |  CellsSerialized object containing list of cells to insert
_flush_ |  Boolean flag to cause a mutator flush after the cells have been inserted

* * *

####  future_open

Opens (creates) a future object that can be used to wait for and obtain the results of asynchronous operations

**DEFINITION**

      Future future_open(1:i32 capacity) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_capacity_ |  The amount of asynchonous result data, in bytes, that the future will accumulate before blocking

**RETURN VALUE**

Opaque identifier for the opened future object

* * *

####  future_close

Closes a future object

**DEFINITION**

      void future_close(1:Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

* * *

####  future_cancel

Cancels tasks outstanding on a future object

**DEFINITION**

      void future_close(1:Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

* * *

####  future_get_result

Fetches next asynchronous result object

**DEFINITION**

      Result future_get_result(1:Future ff, 2:i32 timeout_millis) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object
_timeout_millis_ |  If results have not arrived within this amount of time, throw an exception

**RETURN VALUE**

Result object for next completed asynchronous operation

* * *

####  future_get_result_as_arrays

Fetches next asynchronous result object. Similar to future_get_result except that it returns a ResultAsArrays object which contains a list of CellAsArrays member for scan results which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

**DEFINITION**

      ResultAsArrays future_get_result_as_arrays(1:Future ff, 2:i32 timeout_millis)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object
_timeout_millis_ |  If results have not arrived within this amount of time, throw an exception

**RETURN VALUE**

ResultAsArrays object for next completed asynchronous operation

* * *

####  future_get_result_serialized

Fetches next asynchronous result object. Similar to future_get_result except that it returns a ResultSerialized object which contains a CellsSerialized member for scan results. Encoding and decoding cells to/from the CellsSerialized object is more efficient in languages such as Java and C++.

_Note:_ The class `SerializedCellsReader` that is used to read cells from a CellsSerialized object is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

      ResultSerialized future_get_result_serialized(1:Future ff, 2:i32 timeout_millis)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object
_timeout_millis_ |  If results have not arrived within this amount of time, throw an exception

**RETURN VALUE**

ResultSerialized object for next completed asynchronous operation

* * *

####  future_has_outstanding

Determines whether or not a future object has outstanding asynchronous

**DEFINITION**

      bool future_has_outstanding(1:Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

**RETURN VALUE**

_true_ if operations are outstanding, _false_ otherwise

* * *

####  future_is_cancelled

Determines whether or not a future object has been cancelled

**DEFINITION**

      bool future_is_cancelled(1:Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

**RETURN VALUE**

_true_ if future has been cancelled, _false_ otherwise

* * *

####  future_is_empty

Determines whether or not a future object's result queue is empty. The future may have outstanding requests, but if none of them have completed, this method will return true.

**DEFINITION**

      bool future_is_empty(1: Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

**RETURN VALUE**

_true_ if future's result queue is empty, _false_ otherwise

* * *

####  future_is_full

Determines whether or not a future object has been filled to capacity and is therefore blocking

**DEFINITION**

      bool future_is_full(1: Future ff) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ff_ |  Reference to future object

**RETURN VALUE**

_true_ if futue is filled to capacity, _false_ otherwise

* * *

### Application Helper APIs

####  create_cell_unique

Inserts a unique cell into a table. This function is useful for generating unique identifiers such as usernames for a website. It requires that the column being update be created with the TIME_ORDER DESC and MAX_VERSIONS 1 options. You can supply the contents (value) of the cell or leave it blank and let the function generate unique content internally, the only requirement is that the value is globally unique.

This function can be used to create unique rows in a table. For example, you could create a Users table whose row key is the unique username for each user. The table could be craeted as follows.

    create table Users (
      id TIME_ORDER DESC MAX_VERSIONS 1
      name,
      image
    );

Unique rows can be inserted by calling this function with the desired row key and column family _id_ specified in the key parameter. If the row does not exist, the function will return successfully, otherwise an exception will be thrown.

**DEFINITION**

    string create_cell_unique(1:Namespace ns, 2:string table_name,
                              3:Key key, 4:string value) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to create unique cell
_table_name_ |  Name of table in which to create unique cell
_key_ |  Key of unique cell to create
_value_ |  Content of unique cell. Should be globally unique so that race conditions on create can be disambiguated. Can be empty in which case the function will internally generate a GUID to store as the value.

**RETURN VALUE**

The cell value. If the cell already exists with a different value, a ClientException is thrown

* * *

####  generate_guid

Generates a [GUID](http://en.wikipedia.org/wiki/Globally_unique_identifier) (Globally Unique ID). The generated string is 36 bytes long and has a format similar to "9cf7da31-307a-4bef-b65e-19fb05aa57d8".

**DEFINITION**

    string generate_guid()

**RETURN VALUE**

The GUID

* * *

### Convenience APIs

####  get_cell

Fetches the most recent version of column

**DEFINITION**

    Value get_cell(1:Namespace ns, 2:string table_name, 3:string row, 4:string column)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_row_ |  Row containing cell to fetch
_column_ |  Column containing cell to fetch

**RETURN VALUE**

Cell contents

* * *

####  get_cells

Fetches cells from a table

**DEFINITION**

    list < Cell > get_cells(1:Namespace ns, 2:string table_name, 3:ScanSpec scan_spec)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_scan_spec_ |  ScanSpec object representing query predicate. It defines what cells will be returned by the fetch

**RETURN VALUE**

List of cells

* * *

####  get_cells_as_arrays

Fetches cells from a table. Similar to get_cells, except that it returns a list of CellAsArray objects which are more efficient in languages (e.g. Ruby) where object creation overhead is very high.

**DEFINITION**

    list < CellAsArray > get_cells_as_arrays(1:Namespace ns, 2:string table_name, 3:ScanSpec scan_spec)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_scan_spec_ |  ScanSpec object representing query predicate. It defines what cells will be returned by the fetch

**RETURN VALUE**

List of cells

* * *

####  get_cells_serialized

Fetches cells from a table. Similar to get_cells, except that it returns the list of cells in a CellsSerialized object which is fairly efficient to encode and decode.

_Note:_ The class `SerializedCellsReader` that is used to read cells from a CellsSerialized object is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

    CellsSerialized get_cells_serialized(1:Namespace ns, 2:string name, 3:ScanSpec scan_spec)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_scan_spec_ |  ScanSpec object representing query predicate. It defines what cells will be returned by the fetch

**RETURN VALUE**

List of cells

* * *

####  get_row

Fetches a the latest version of cells from a row

**DEFINITION**

    list < Cell > get_row(1:Namespace ns, 2:string table_name, 3:string row)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_row_ |  Row containing cells to fetch

**RETURN VALUE**

List of cells

* * *

####  get_row_as_arrays

Fetches a the latest version of cells from a row. Similar to get_rows, except that it returns a list of CellAsArray objects which are more efficient in languages (e.g. Ruby) where object creation overhead is very high.

**DEFINITION**

    list < CellAsArray > get_row_as_arrays(1:Namespace ns, 2:string table_name,
                                            3:string row) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_row_ |  Row containing cells to fetch

**RETURN VALUE**

List of cells

* * *

####  get_row_serialized

Fetches a the latest version of cells from a row. Similar to get_rows, except that it returns the list of cells in a CellsSerialized object which is more efficient to encode and decode than Thrift serialization in languages such as Java and C++.

_Note:_ The class `SerializedCellsReader` that is used to read cells from a CellsSerialized object is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

    CellsSerialized get_row_serialized(1:Namespace ns, 2:string table_name,
                                       3:string row) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table from which to fetch cells
_table_name_ |  Name of table from which to fetch cells
_row_ |  Row containing cells to fetch

**RETURN VALUE**

List of cells

* * *

####  set_cell

Inserts a cell into a table

_Notes:_ This method should not be used when inserting many cells into a table because it does no buffering.

**DEFINITION**

    void set_cell(1:Namespace ns, 2:string table_name, 3:Cell cell)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to insert cell
_table_name_ |  Name of table in which to insert cell
_cell_ |  Cell object representing cell to insert

* * *

####  set_cell_as_array

Inserts a cell into a table. Similar to set_cell except that it inserts a CellAsArray object which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

_Notes:_ This method should not be used when inserting many cells into a table because it does no buffering.

**DEFINITION**

    void set_cell(1:Namespace ns, 2:string table_name, 3:Cell cell)
        throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to insert cell
_table_name_ |  Name of table in which to insert cell
_cell_ |  Cell to insert

* * *

####  set_cells

Inserts a list of cells into a table

_Notes:_ This method should not be called repeatedly to insert many cells into a table because it does no buffering. Use the `mutator_` APIs instead.

**DEFINITION**

    void set_cells(1:Namespace ns, 2:string table_name, 3:list < Cell > cells)
          throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to insert cells
_table_name_ |  Name of table in which to insert cells
_cells_ |  List of Cell objects to insert

* * *

####  set_cells_as_arrays

Inserts a list of cells into a table. Similar to set_cells except that it inserts a CellAsArray object which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

_Notes:_ This method should not be called repeatedly to insert many cells into a table because it does no buffering. Use the `mutator_` APIs instead.

**DEFINITION**

    void set_cells_as_arrays(1:Namespace ns, 2:string table_name,
                             3:list < CellAsArray > cells) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to insert cells
_table_name_ |  Name of table in which to insert cells
_cells_ |  List of CellAsArray objects to insert

* * *

####  set_cells_serialized

Inserts a list of cells into a table. Similar to set_cells except that it takes a list of cells represented by a CellsSerialized object.

_Note:_ The class `SerializedCellsWriter` that is used to create CellsSerialized objects is currently only available in C++, Java, Node.js (Javascript), and Python which effectively makes this method only available in those languages.

**DEFINITION**

    void set_cells_serialized(1:Namespace ns, 2:string table_name,
                              3:CellsSerialized cells) throws (1:ClientException e),

**PARAMETERS**

Parameter | Description
---|---
_ns_ |  Namespace identifier of namespace containing table in which to insert cells
_table_name_ |  Name of table in which to insert cells
_cells_ |  List of cells to insert, in the form of a CellsSerialized object

* * *

####  shared_mutator_refresh

Creates a shared mutator from a given MutateSpec, deleting and recreating one if it already exists.

**WARNING:** Shared mutators sacrifice write durability guarantee because they buffer and flush mutations on a periodic time interval and the `set_` methods return without knowing if the mutations succeeded or failed.

****DEFINITION****

    void shared_mutator_refresh(1:Namespace ns, 2:string table_name,
                                3:MutateSpec mutate_spec) throws (1:ClientException e),

****PARAMETERS****

Parameter | Description
---|---
_mutator_ |  Identifier of namespace containing table on which to create or refresh mutator
_table_name_ |  Name of table on which to create or refresh mutator
_mutate_spec_ |  Mutator specification object which includes information such as flush period and mutator flags

* * *

####  shared_mutator_set_cell

Mutates a table by writing a cell through a shared mutator, creating one if it does not exist. Shared mutators buffer data in memory and flush on a periodic time interval.

**WARNING:** This method sacrifices write durability guarantee because it adds the cell to the mutator's internal memory buffers without waiting for the operation to complete.

****DEFINITION****

      void shared_mutator_set_cell(1:Namespace ns, 2:string table_name,
                                   3:MutateSpec mutate_spec, 4:Cell cell)
          throws (1:ClientException e),

****PARAMETERS****

Parameter | Description
---|---
_mutator_ |  Identifier of namespace containing table in which to insert cell
_table_name_ |  Name of table in which to insert cell
_mutate_spec_ |  Mutator specification object which includes information such as flush period and mutator flags
_cell_ |  Cell object to insert via mutator

* * *

####  shared_mutator_set_cell_as_array

Mutates a table by writing a cell through a shared mutator, creating one if it does not exist. Shared mutators buffer data in memory and flush on a periodic time interval. This method is similar to the shared_mutator_set_cell method except except that it inserts a CellAsArray object which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

**WARNING:** This method sacrifices write durability guarantee because it adds the cell to the mutator's internal memory buffers without waiting for the operation to complete.

****DEFINITION****

      void shared_mutator_set_cell_as_array(1:Namespace ns, 2:string table_name, 3:MutateSpec mutate_spec, 4:CellAsArray cell)
          throws (1:ClientException e),

****PARAMETERS****

Parameter | Description
---|---
_mutator_ |  Identifier of namespace containing table in which to insert cell
_table_name_ |  Name of table in which to insert cell
_mutate_spec_ |  Mutator specification object which includes information such as flush period and mutator flags
_cell_ |  CellAsArray object to insert via mutator

* * *

####  shared_mutator_set_cells

Mutates a table by writing a list of cells through a shared mutator, creating one if it does not exist. Shared mutators buffer data in memory and flush on a periodic time interval.

**WARNING:** This method sacrifices write durability guarantee because it adds the cells to the mutator's internal memory buffers without waiting for the operation to complete.

****DEFINITION****

      void shared_mutator_set_cells(1:Namespace ns, 2:string table_name, 3:MutateSpec mutate_spec, 4:list < Cell > cell)
          throws (1:ClientException e),

****PARAMETERS****

Parameter | Description
---|---
_mutator_ |  Identifier of namespace containing table in which to insert cells
_table_name_ |  Name of table in which to insert cells
_mutate_spec_ |  Mutator specification object which includes information such as flush period and mutator flags
_cells_ |  List of Cell objects to insert via mutator

* * *

####  shared_mutator_set_cells_as_arrays

Mutates a table by writing a list of cells through a shared mutator, creating one if it does not exist. Shared mutators buffer data in memory and flush on a periodic time interval. This method is similar to the shared_mutator_set_cells method except except that it inserts a list of CellAsArray objects which can be more efficient for languages (e.g. Ruby) where object construction overhead is large in comparison to native datatypes (e.g. string).

**WARNING:** This method sacrifices write durability guarantee because it adds the cells to the mutator's internal memory buffers without waiting for the operation to complete.

****DEFINITION****

      void shared_mutator_set_cells_as_arrays(1:Namespace ns, 2:string table_name, 3:MutateSpec mutate_spec, 4:list < CellAsArray > cell)
          throws (1:ClientException e),

****PARAMETERS****

Parameter | Description
---|---
_mutator_ |  Identifier of namespace containing table in which to insert cells
_table_name_ |  Name of table in which to insert cells
_mutate_spec_ |  Mutator specification object which includes information such as flush period and mutator flags
_cells_ |  List of CellAsArray objects to insert via mutator

* * *

### Datatypes

####  AccessGroupOptions

This structure describes access group options.

**DEFINITION**

    struct AccessGroupOptions {
      1: optional i16 replication
      2: optional i32 blocksize
      3: optional string compressor
      4: optional string bloom_filter
      5: optional bool in_memory
    }

**FIELDS**

Parameter | Description
---|---
_replication_ |  The replication factor for CellStores in this access group
_blocksize_ |  The blocksize for CellStores in this access group
_compressor_ |  The compressor used to compress CellStore blocks in this access group
_bloom_filter_ |  The bloom filter options that apply to CellStores in this access group
_in_memory_ |  Boolean flag indicating if the access group should be pinned in memory

####  AccessGroupSpec

This structure represents an access group specification.

**DEFINITION**

    struct AccessGroupSpec {
      1: string name
      2: optional i64 generation
      3: optional AccessGroupOptions options
      4: optional ColumnFamilyOptions defaults
    }

**FIELDS**

Parameter | Description
---|---
_name_ |  Name of access group
_generation_ |  Generation number (updated each time access group spec is modified)
_options_ |  Options defined for this access group
_defaults_ |  Default column family options given to all columns in this access group. These defaults only apply if corresponding option is not explicitly specified in the column family spec.

####  Cell

This structure is used to represent a cell. It has two members, the key and the value.

**DEFINITION**

    struct Cell {
      1: Key key
      2: optional Value value
    }

**FIELDS**

Parameter | Description
---|---
_key_ |  the complete key
_value_ |  the value

* * *

####  CellAsArray

This typedef is an alternative Cell interface for languages (e.g., Ruby) where user defined objects are much more expensive to create than builtin primitives. The base type is a list of strings and the cell members flattened into the list as follows: ["row_key", "column_family", "column_qualifier", "value", "timestamp"]

Note, revision and cell flag are not returned for the array interface.

**DEFINITION**

    typedef list < string > CellAsArray

* * *

####  CellInterval

This structure is part of a scan query predicate (ScanSpec) and can be used to efficiently retrieve cells over column qualifier ranges. It is typically used to select ranges of cells in a specific column family of a single row, where the column family contains a very large number of qualified instances (e.g., millions).

_Additional Notes:_ While you can specify a cell interval that spans multiple column families, it is inadvisable because the results are somewhat undefined. Column families are implicitly assigned a numeric ID which is what's stored in the key and the ID is what's used for comparison purposes. For example, the following cell interval,

    "row","bar:good" < CELL <= "row",foo:good"

could be invalid if the numeric ID for column family _foo_ is 1 and the numeric ID for column family _bar_ is 2, which would make `"row",foo:good"` come before `"row","bar:good"` in the table.

**DEFINITION**

    struct CellInterval {
      1: optional string start_row
      2: optional string start_column
      3: optional bool start_inclusive = 1
      4: optional string end_row
      5: optional string end_column
      6: optional bool end_inclusive = 1
    }

**FIELDS**

Parameter | Description
---|---
_start_row_ |  Start row of the interval
_start_column_ |  Start column of the interval, specified as _family:qualifier_
_start_inclusive_ |  Indicates if the start cell should be included in the results
_end_row_ |  End row of the interval
_end_column_ |  End column of the interval, specified as _family:qualifier_
_end_inclusive_ |  Indicates if the end cell should be included in the results

* * *

####  CellsSerialized

This type is an array of bytes that represents a binary, serialized array of cells

**DEFINITION**

    typedef binary CellsSerialized

* * *

####  ClientException

This is the exception class that is thrown by most of the Thrift client APIs in the event of an error.

**DEFINITION**

    exception ClientException {
      1: i32 code
      2: string message
    }

**FIELDS**

Parameter | Description
---|---
_code_ |  Hypertable error code (see [Error Codes](error_codes.md))
_message_ |  String message describing the error

* * *

####  ColumnFamilyOptions

This structure describes column family options.

**DEFINITION**

    struct ColumnFamilyOptions {
      1: optional i32 max_versions
      2: optional i32 ttl
      3: optional bool time_order_desc
      4: optional bool counter
    }

**MEMBERS**

Parameter | Description
---|---
_max_versions_ |  Maximum number of cell versions to keep for this column family (0 means keep all versions)
_ttl_ |  Time to live value for column family. Automatically delete cells that are older than this value
_time_order_desc_ |  Indicates physical timestamp ordering of cell versions (_true_ is chronological, _false_ is reverse chronological which is the default)
_counter_ |  Columns in this family are treated as atomic counters

* * *

####  ColumnFamilySpec

This structure describes column family options.

**DEFINITION**

    struct ColumnFamilySpec {
      1: string name
      2: string access_group
      3: bool deleted
      4: optional i64 generation
      5: optional i32 id
      6: bool value_index
      7: bool qualifier_index
      8: optional ColumnFamilyOptions options
    }

**MEMBERS**

Parameter | Description
---|---
_name_ |  Name of column family
_access_group_ |  Access group to which this column family belongs
_deleted_ |  Column family has been deleted
_counter_ |  Columns in this family are treated as atomic counters
_generation_ |  Generation number (updated each time column spec is modified)
_id_ |  Numeric identifier
_value_index_ |  Value index is defined
_qualifier_index_ |  Qualifier index is defined
_options_ |  Options defined for this column

* * *

####  ColumnPredicate

A list of these structures is a member of the ScanSpec structure and describes a column predicate to be applied to a secondary index.

**DEFINITION**

    struct ColumnPredicate {
      1: optional string column_family
      2: optional string column_qualifier
      3: i32 operation
      4: optional string value
    }

**MEMBERS**

Parameter | Description
---|---
_column_family_ |  Name of the column family
_column_qualifier_ |  Exact, prefix, or regex column qualifier pattern (depends on the operation)
_operation_ |  Bitwise OR of [ColumnPredicateOperation](thrift_api.md#columnpredicateoperation) values
_value_ |  Exact, prefix, or regex value pattern (depends on the operation)

* * *

####  ColumnPredicateOperation

This enum type is used to describe the time of column predicate operation that is to be performed on a secondary index.

**DEFINITION**

    enum ColumnPredicateOperation {
      EXACT_MATCH  = 1,
      PREFIX_MATCH = 2,
      REGEX_MATCH  = 4,
      VALUE_MATCH  = 7,
      QUALIFIER_EXACT_MATCH  = 256,
      QUALIFIER_PREFIX_MATCH = 512,
      QUALIFIER_REGEX_MATCH  = 1024,
      QUALIFIER_MATCH        = 1792
    }

**MEMBERS**

Parameter | Description
---|---
_EXACT_MATCH_ |  Perform an exact match on the value
_PREFIX_MATCH_ |  Perform a prefix match on the value
_REGEX_MATCH_ |  Perform a regex match on the value
_VALUE_MATCH_ |  Bitmask for value operations
_QUALIFIER_EXACT_MATCH_ |  Perform an exact match on the column qualifier
_QUALIFIER_PREFIX_MATCH_ |  Perform a prefix match on the column qualifier
_QUALIFIER_REGEX_MATCH_ |  Perform a regex match on the column qualifier
_QUALIFIER_MATCH_ |  Bitmask for column qualifier operations

* * *

####  Future

Opaque identifier for Future object. Future objects are used with the asynchronous APIs as a rendezvous point to collect the results of the asynchronous operations.

**DEFINITION**

    typedef i64 Future

* * *

####  HqlResult

This structure holds the result of an HQL query.

**DEFINITION**

    struct HqlResult {
      1: optional list< string > results,
      2: optional list< Cell > cells,
      3: optional i64 scanner,
      4: optional i64 mutator
    }

**FIELDS**

Parameter | Description
---|---
_results_ |  String results from meta data queries
_cells_ |  Resulting table cells of for buffered queries
_scanner_ |  Resulting scanner ID for unbuffered queries
_mutator_ |  Resulting mutator ID for unflushed modifying queries

* * *

####  HqlResultAsArrays

This structure holds the result of an HQL query. It is the same as HqlResult except that the cell is contains CellAsArray structures

**DEFINITION**

    struct HqlResultAsArrays {
      1: optional list< string > results,
      2: optional list< CellAsArray > cells,
      3: optional i64 scanner,
      4: optional i64 mutator
    }

####  Key

This structure is a member of the Cell structure and defines the complete key for the cell.

**DEFINITION**

    struct Key {
      1: string row
      2: string column_family
      3: string column_qualifier
      4: optional i64 timestamp
      5: optional i64 revision
      6: KeyFlag flag = KeyFlag.INSERT
    }

Parameter | Description
---|---
_row_ |  Row key
_column_family_ |  Column family name
_column_qualifier_ |  Column qualifier
_timestamp_ |  Timestamp
_revision_ |  Revision number for the cell (currently internal use only)
_flag_ |  Flag field of type KeyFlag, indicating type of cell (insert, delete, etc.)

* * *

####  KeyFlag

This enumeration type is a member of the Key structure and is used to indicate what type of record the cell represents (insert, delete, etc.)

**DEFINITION**

    enum KeyFlag {
      DELETE_ROW = 0,
      DELETE_CF = 1,
      DELETE_CELL = 2,
      DELETE_CELL_VERSION = 3,
      INSERT = 255
    }

**MEMBERS**

Parameter | Description
---|---
_DELETE_ROW_ |  Delete all cells of a specific row
_DELETE_CF_ |  Delete all cells in the given column family of a specific row
_DELETE_CELL_ |  Delete all cells of a specific qualified column of a row with the given timestamp or older
_DELETE_CELL_VERSION_ |  Delete the exact cell that matches the column family, qualifier, and timestamp
_INSERT_ |  Insert cell

* * *

####  MutateSpec

Mutator specification used for shared, periodic mutators (`offer_` APIs).

**DEFINITION**

    struct MutateSpec {
      1: required string appname = ""
      2: required i32 flush_interval = 1000
      3: required i32 flags = MutatorFlag.IGNORE_UNKNOWN_CFS
    }

**FIELDS**

Parameter | Description
---|---
_appname_ |  Name used to identify a shared, periodic mutator
_flush_interval_ |  Flush interval for shared, periodic mutator
_flags_ |  Flags passed to constructor of shared, periodic mutator

* * *

####  Mutator

Opaque identifier for table mutator, returned by mutator_open. The mutator APIs are recommended for injecting large amounts of data into a table.

**DEFINITION**

    typedef i64 Mutator

* * *

####  MutatorAsync

Opaque identifier for an asynchronous table mutator, returned by async_mutator_open. The asynchronous mutator APIs are recommended for for situations where you need to update multiple tables in parallel.

**DEFINITION**

    typedef i64 MutatorAsync

* * *

####  MutatorFlag

This enumeration type defines the constants that can be passed into the mutator_open APIs for the _flags_ argument.

**DEFINITION**

    enum MutatorFlag {
      NO_LOG_SYNC = 1,
      IGNORE_UNKNOWN_CFS = 2,
      NO_LOG = 4
    }

**CONSTANTS**

Parameter | Description
---|---
_NO_LOG_SYNC_ |  This flag causes the mutator to trade off durability for performance, by not calling `sync()` on the commit log after each write. Use of this flag should be avoided, but there are some (older) filesystems that can't keep up with Hypertable request load can fail due to the heavy demands put on it. This flag can help eliminate these failures.
_IGNORE_UNKNOWN_CFS_ |  Ignore unknown column families. There are some situations where you would like to load a `.tsv` file that contains column data for a column that has been deleted. Normally, the mutator will generate an error in this circumstance. This flag tells the mutator to silently skip unknown column data.
_NO_LOG_ \-  |  This flag is passed through to the RangeServers and causes them to skip the commit log write entirely. It can be used to dramatically speed up bulk insert performance, but opens a window of vulnerability in terms of data loss. If a RangeServer fails while inserting data with this flag, data may be lost and should be reloaded. To close the window of vulnerability after successfullly loading data with this flag, the table(s) into which the data were loaded must be manually compacted (see [COMPACT](hql.md#compact)).

* * *

####  Namespace

Opaque identifier for namespace, returned by namespace_open.

**DEFINITION**

    typedef i64 Namespace

* * *

####  NamespaceListing

This structure is used to represent an entry in a namespace listing. A list of these objects are returned by namespace_get_listing.

**DEFINITION**

    struct NamespaceListing {
      1: required string name
      2: required bool is_namespace
    }

**FIELDS**

Parameter | Description
---|---
_name_ |  The name of the entry
_is_namespace_ |  Boolean flag to indicate if the entry is a namespace or table

* * *

####  Result

This structure holds the result of an asynchronous request.

**DEFINITION**

    struct Result {
      1: required bool is_empty
      2: required i64 id
      3: required bool is_scan
      4: required bool is_error
      5: optional i32 error
      6: optional string error_msg
      7: optional list < Cell > cells
    }

Parameter | Description
---|---
_is_empty_ |  Indicates whether or not this object contains a result
_id_ |  Scanner or mutator identifier to which these results pertain
_is_scan_ |  Indicates whether this result is from an asynchronous scan or update
_is_error_ |  Indicates whether or not the async request was successful
_error_ |  Error code
_error_msg_ |  Error message
_cells_ |  Query result (list of Cell objects) from an asynchronous scan.

* * *

####  ResultAsArrays

This structure holds the result of an asynchronous request. It differs from the Result structure in that the list of cells is returned as a list of CellsAsArray objects

**DEFINITION**

    struct ResultAsArrays {
      1: required bool is_empty
      2: required i64 id
      3: required bool is_scan
      4: required bool is_error
      5: optional i32 error
      6: optional string error_msg
      7: optional list < CellAsArray > cells
    }

Parameter | Description
---|---
_is_empty_ |  Indicates whether or not this object contains a result
_id_ |  Scanner or mutator identifier to which these results pertain
_is_scan_ |  Indicates whether this result is from an asynchronous scan or update
_is_error_ |  Indicates whether or not the async request was successful
_error_ |  Error code
_error_msg_ |  Error message
_cells_ |  Query result from an asynchronous scan.

* * *

####  ResultSerialized

This structure holds the result of an asynchronous request. It differs from the Result structure in that the list of cells is returned as a CellsSerialized object

**DEFINITION**

    struct ResultSerialized {
      1: required bool is_empty
      2: required i64 id
      3: required bool is_scan
      4: required bool is_error
      5: optional i32 error
      6: optional string error_msg
      7: optional CellsSerialized cells
    }

Parameter | Description
---|---
_is_empty_ |  Indicates whether or not this object contains a result
_id_ |  Scanner or mutator identifier to which these results pertain
_is_scan_ |  Indicates whether this result is from an asynchronous scan or update
_is_error_ |  Indicates whether or not the async request was successful
_error_ |  Error code
_error_msg_ |  Error message
_cells_ |  Query result from an asynchronous scan.

* * *

####  RowInterval

The query predicate structure (ScanSpec) contains a list of RowInterval structures. They allow for efficient retrieval of row ranges of table data.

**DEFINITION**

    struct RowInterval {
      1: optional string start_row
      2: optional bool start_inclusive = 1
      3: optional string end_row
      4: optional bool end_inclusive = 1
    }

**FIELDS**

Parameter | Description
---|---
_start_row_ |  Start row of the interval
_start_inclusive_ |  Indicates if the start row should be included in the results
_end_row_ |  End row of the interval
_end_inclusive_ |  Indicates if the end row should be included in the results

* * *

####  ScanSpec

This structure represents a query predicate and controls what cells are returned from a scan.

**DEFINITION**

    struct ScanSpec {
      1: optional list<rowinterval> row_intervals
      2: optional list<cellinterval> cell_intervals
      3: optional bool return_deletes = 0
      4: optional i32 versions = 0
      5: optional i32 row_limit = 0
      6: optional i64 start_time
      7: optional i64 end_time
      8: optional list<string> columns
      9: optional bool keys_only = 0
      14:optional i32 cell_limit = 0
      10:optional i32 cell_limit_per_family = 0
      11:optional string row_regexp
      12:optional string value_regexp
      13:optional bool scan_and_filter_rows = 0
      15:optional i32 row_offset = 0
      16:optional i32 cell_offset = 0
      17:optional list<columnpredicate> column_predicates
      18:optional bool do_not_cache = 0
      19:optional bool and_column_predicates = 0
    }

**FIELDS**

Parameter | Description
---|---
_row_intervals_ |  A list of row ranges to return (mutually exclusive with cell_interval)
_cell_intervals_ |  A list of cell ranges to return (mutually exclusive with row_interval)
_return_deletes_ |  Return delete records (for testing only)
_versions_ |  Number of versions of each cell to return. Versions are stored in reverse-chronological order, so specifying versions=1 will return the latest version of each cell.
_row_limit_ |  Limits the number of rows to return. Result paging can be implemented by using this option with the _row_offset_ option. This option applies independently to each row or cell interval.
_start_time_ |  Return only cells whos timestamp is greater than or equal to this time (nanoseconds since the epoch).
_end_time_ |  Return only cells whos timestamp is less than this time (nanoseconds since the epoch).
_columns_ |  List of columns from which to return cells. Column names can be specified as just the column family name, or can be fully qualified as _family:qualifier_.
_keys_only_ |  Only return keys, not values
_cell_limit_ |  Maximum number of cells to return. This can be used in conjunction with cell_offset to implement result paging. This option applies independently to each cell or row interval.
_cell_limit_per_family_ |  Limits the number of cells to return, per column family
_row_regexp_ |  Regular expression used to filter row keys.
_value_regexp_ |  Regular expression used to filter values.
_scan_and_filter_rows_ |  This is an explicit optimization for the case where you're querying for a very large number of row intervals (e.g. 10,000+). Instead of fetching each row interval independently, this option will cause the system to do a full table scan and filter the results to find the rows that are desired. Use this option with caution, it can be extremely inefficient for smaller number of row intervals.
_row_offset_ |  This option provides a way to skip the first rows that would otherwise be returned by the query. It can be used in conjunction with row_limit to implement result paging. This option applies independently to each row or cell interval.
_cell_offset_ |  This option provides a way to skip the first cells that would otherwise be returned by the query. It can be used in conjunction with row_limit to implement result paging. This option applies independently to each row or cell interval.
_column_predicates_ |  This option provides a way to match a set of column predicates to a secondary index.
_do_not_cache_ |  This option provides a way to prevent the query results from being inserted into the query cache.
_and_column_predicates_ |  Perform boolean AND of column predicate results

* * *

####  Scanner

Opaque identifier for table scanner, returned by scanner_open. The scanner APIs are recommended for querying large amounts of data from a table.

**DEFINITION**

    typedef i64 Scanner

* * *

####  ScannerAsync

Opaque identifier for an asynchronous table scanner, returned by async_scanner_open. The asynchronous scanner APIs are recommended for for situations where you need to query multiple tables in parallel.

**DEFINITION**

    typedef i64 ScannerAsync

* * *

####  Schema

This structure represents a table schema definition and is returned by table_get_schema.

**DEFINITION**

    struct Schema {
      1: optional map<string, AccessGroupSpec> access_groups
      2: optional map<string, ColumnFamilySpec> column_families
      3: optional i64 generation
      4: optional i32 version
      5: optional i32 group_commit_interval
      6: optional AccessGroupOptions access_group_defaults
      7: optional ColumnFamilyOptions column_family_defaults
    }

**FIELDS**

Parameter | Description
---|---
_access_groups_ |  List of AccessGroupSpec objects that specify the access groups that are part of the table definition
_column_families_ |  List of ColumnFamilySpec objects that specify the column families that are part of the table definition
_generation_ |  Generation number (updated each time schema is modified)
_version_ |  Version number. Can be used to signal changes in the schema that are no explicitly captured by the specification, such as changes in the row key format.
group_commit_interval - |  Group commit interval.
access_group_defaults - |  Default access group options to be used for access groups in this schema. These options only apply if the corresponding option in the access group was not explicitly defined.
column_family_defaults - |  Default column family options to be used for column families in this schema. These options only apply if the corresponding option in the column family was not explicitly defined.

* * *

####  TableSplit

This structure represents a table split, which contains information about a Range and its location, and is used by the MapReduce framework to logically split a table into pieces for the map phase.

**DEFINITION**

    struct TableSplit {
      1: optional string start_row
      2: optional string end_row
      3: optional string location
      4: optional string ip_address
      5: optional string hostname
    }

**FIELDS**

Parameter | Description
---|---
_start_row_ |  Start row of the split
_end_row_ |  End row of the split
_location_ |  Proxy name of RangeServer managing this range
_ip_address_ |  IP address of RangeServer managing this range
_hostname_ |  Hostname of RangeServer managing this range

* * *

####  Value

This type is used to represent a cell value.

**DEFINITION**

    typedef binary Value

* * *
