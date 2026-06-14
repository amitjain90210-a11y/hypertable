# salvage

This tool will salvage data from a (potentially corrupt) Hypertable database by recursively walking the `/hypertable/tables` directory in the brokered filesystem looking for CellStore files and extracting data from them. The recovered data is written into a tree of `.tsv` files that can be re-loaded into a clean database at a later time. For each unique table directory encountered, a `.hql` file will also be generated which contains the HQL required to re-create the table.

### Prerequisites

This tool requires Hyperspace to be intact and running and an FS broker running on local host. These services can be started as follows:

    $ ht cluster start_hyperspace
    $ ht start-fsbroker hadoop

This tool only extracts data from CellStores. To extract data in commit logs, the [log_player](ht_log_player.md) tool can be used.

### Basic Usage

The simplest usage is to run it with no options, supplying only the output directory argument:

    $ ht salvage output

After successfully completing, the output directory will be populated with the namespace hierarchy and the `.tsv` and `.hql` files. For example:

    $ tree output
    output
    ├── alerts
    │   ├── create-realtime.hql
    │   └── realtime.tsv
    ├── cache
    │   ├── create-image.hql
    │   └── image.tsv
    └── search
        ├── blog.tsv
        ├── create-blog.hql
        ├── create-image.hql
        ├── create-news.hql
        ├── image.tsv
        └── news.tsv

### Include and Exclude

To exclude a specific namespace or table, the `--exclude` option may be used:

    $ ht salvage --exclude search output

    $ tree output
    output
    ├── alerts
    │   ├── create-realtime.hql
    │   └── realtime.tsv
    └── cache
        ├── create-image.hql
        └── image.tsv

To include a specific namespace or table, the `--include` option may be used:

    $ ht salvage --include search/blog output

    $ tree output
    output
    └── search
        ├── blog.tsv
        └── create-blog.hql

### Restricting Row Space

To restrict the salvaged data to a specific row key range, use the `--start-key` and `--end-key` options. For example:

    $ ht salvage --start-key "019999999" --end-key "030000000" output

### Path Regex

With the `--path-regex` option, a regular expression can be supplied to specify which directories in the brokered filesystem should be included in the recovery. For example:

    $ ht salvage --verbose --path-regex "/hypertable/tables/[2-3]" output
