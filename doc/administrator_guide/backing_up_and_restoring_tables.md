# Backup and Restore

Hypertable backup and restore are accomplished with the HQL commands DUMP TABLE and LOAD DATA INFILE. It is possible to create backups with the SELECT command, but it is not recommended because it will output table data in sorted order. When loading data with LOAD DATA INFILE that is in sorted order, only one RangeServer will be kept busy at a time. To combat this problem, the DUMP TABLE command was introduced which will output table data in random order. Loading backups taken with the DUMP TABLE command is much more efficient since all of the participating RangeServers will be kept busy.

### backup.sh

    #!/usr/bin/env bash

    if [ $# -lt 2 ] ; then
        echo "usage: $0 <namespace> <table> [  ... ]"
        exit 0
    fi

    namespace=$1
    shift
    while [ $# -ge 1 ]; do
        echo "Backing up '${namespace}/$1' ..."
        echo "USE '${namespace}';" > create-table-$1.hql
        echo "USE '${namespace}'; SHOW CREATE TABLE '$1';" | ht shell --batch --silent >> create-table-$1.hql
        echo ";" >> create-table-$1.hql
        echo "USE '${namespace}'; DUMP TABLE '$1' INTO FILE '$1.gz';" | ht shell --batch
        shift
    done

### restore.sh

    #!/usr/bin/env bash

    if [ $# -lt 2 ] ; then
        echo "usage: $0   [  ... ]"
        exit 0
    fi

    namespace=$1
    shift

    while [ $# -ge 1 ]; do
        table=`basename $1 | cut -f1 -d'.'`
        echo "Restoring '${namespace}/${table}' ..."
        cat create-table-$1.hql | ht shell --batch
        echo "USE '${namespace}'; LOAD DATA INFILE '$1.gz' INTO TABLE '$table';" | ht shell --batch
        shift
    done
