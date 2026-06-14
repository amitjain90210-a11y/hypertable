# log_player

This program converts cells in a commit log (in the brokered file system) into a form that allows them to be re-inserted into Hypertable. It can be used in situations where Hypertable is not coming up due to major filesystem corruption and you need to recover data that has be inserted into the database.

### Input

There are four different commit logs for each range server, three logs that persist writes to internal system tables (root, metadata, system) and one commit log for application tables (user). These logs can be found, for each range server, under the following paths:

    /hypertable/servers/rs*/log/root
    /hypertable/servers/rs*/log/metadata
    /hypertable/servers/rs*/log/system
    /hypertable/servers/rs*/log/user

### Operation

For this tool to work properly, it needs access to both Hyperspace and the FS broker. The services can be started as follows:

    $ ht cluster start_hyperspace
    $ ht start-fsbroker hadoop  # or local, ...

The tool can be run in two modes. The first mode, specified with the `--tsv-output` switch, causes the cells in the log to be written into a tree of `.tsv` files rooted in the current working directory. The directory tree produced parallels the namespace hierarchy of the tables encountered in the log, with a `.tsv` file for each unique table encountered in the log. For example:

    $ ht log_player --tsv-output /hypertable/servers/rs6/log/user

    $ tree
    .
    ├── alerts
    │   └── realtime.tsv
    ├── cache
    │   └── image.tsv
    └── search
        ├── blog.tsv
        ├── image.tsv
        └── news.tsv

The `.tsv` files generated in the `--tsv-output` mode can be loaded into re-created tables using the LOAD DATA INFILE command.

The second mode, specified with the `--stdout` switch, causes the cells to be written to the terminal in the following format:

    <tablename> '\t' <timestamp> '\t' <rowkey> '\t' <column> '\t' <value>

For example:

    $ ht log_player --stdout /hypertable/servers/rs6/log/user

    LoadTest  1456961038717377419  212321801        source  ively\\nundiffractiveness\\nundi
    LoadTest  1456961038717377420  212322677        source  s\\nrestrip\\nrestrive\\nrestrive
    LoadTest  1456961038717377421  212323185        source  sly\\nsacrilegiousness\\nsacrile
    LoadTest  1456961038717377422  212324729        source  s\\npsammophile\\npsammophilous\\
    LoadTest  1456961038717377423  212325006        source  cartilaginous\\ncarting\\ncartis
    LoadTest  1456961038717377424  212325929        source  nah\\nwinnard\\nWinne\\nWinnebago
    ...
