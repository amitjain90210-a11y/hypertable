# Cluster Administration Tool

## Table of Contents

### Introduction

`ht_cluster` is a simple tool that can be used to automate the execution of tasks on a large cluster of machines. It is the recommended tool for administering a Hypertable cluster and is the tool that is referenced throughout the documentation.

`ht_cluster` was developed as a replacement for [Capistrano](http://capistranorb.com/), a Ruby-based remote server automation tool. It is based on the same concepts as Capistrano, but improves on it in a number of ways, most notably usability. The biggest problem with Capistrano and the primary motivation for writing `ht_cluster` is Capistrano's dependence on Ruby and a number of Ruby gems. These external dependencies can be problematic on some systems and a stumbling block to getting it installed. `ht_cluster`, on the other hand, has no external dependencies and works "right out of the box".

The tool is driven off of a configuration file called `cluster.def`, the cluster definition file. This file contains definitions for _roles_ and _tasks_. A role is a named set of machines that will all perform some similar task. A task is a script that can launch a daemon server and/or run an arbitrary set of programs. Each task is associated with a set of roles. When a task is executed, it is executed on the set of machines defined by the set of roles with which it is associated. To execute a task, the name of the task is provided as the first argument to `ht_cluster` followed by any optional task arguments:

    ht cluster <task-name> [<args> …]

> **NOTE** : As can be seen by the above command line, the `ht_cluster` program should be launched with the `ht` wrapper script, which makes appropriate changes to the environment before launching the tool. This script is invoked as `ht <tool> [args…]`. The `ht` script will prepend `ht_` to the `<tool>` argument to locate the executable file, which is why it is invoked as `ht cluster` (i.e. without an intervening underscore character).

### Cluster Definition Syntax

The cluster definition file, named `cluster.def` by default, contains the definitions of roles and tasks. `ht_cluster` looks for `cluster.def` first in the current working directory and if not found, looks for it in the directory `../conf`, relative to the directory containing the `ht_cluster` executable file. The location of the cluster definition file can also be supplied directly by passing an `–f <filename>` argument to `ht_cluster`.

The language of the cluster definition file is almost entirely Bash, which is one of the advantages it has over the Capistrano, whose language is a mixture of Ruby and Bash. The cluster definition file is essentially just a Bash script with a few additional constructs for defining tasks and roles. The additional constructs are described below.

####  Roles

A role is a named set of machines that will run some similar service or perform some similar task. For example, in the Hypertable `cluster.def` file there is a role called _slave_ , which defines the set of machines that will run the RangeServer process. The following is the BNF for a role definition statement:

    role: <role-name> <hostspec>

The `<role-name>` argument is an identifier that is the name of the role and must be a valid Bash identifier (e.g. consisting of alphanumeric and underscore characters and not beginning with a numeric character). See [Host Specification Pattern](ht_ssh.md#host-specification-pattern) for a description of the `<hostspec>` argument. The following is an example role definition:

    role: slave test[00-99]

Role definitions may be split across multiple lines and the end of the definition is signalled by the beginning of a new role definition or an empty line. Role definitions translate into Bash variable definitions where the variable name is the name of the role prefixed with "ROLE_". For example, the above role definition can be referenced in subsequent parts of the cluster definition file with `${ROLE_slave}`.

####  Tasks

Tasks are essentially just Bash functions that are associated with a set of roles. The following is the BNF for a task definition statement:

    <task-comment-block>
    task: <take-name> [ roles: <role-list> ] {
      <task-body>
    }

The `<task-comment-block>` is a Bash comment block (e.g. lines starting with the ‘#’ character. The text up to the first ‘.’ character in the comment is taken as the short description for the task and should be less than 50 characters. The text after the first ‘.’ character in the comment is taken as the extended description of the task and can be of arbitrary length. The `<task-name>` argument is an identifier that is the name of the task and must be a valid Bash function identifier (e.g. consisting of alphanumeric and underscore characters and not beginning with a numeric character). The `<role-list>` argument in the optional `roles:` clause is a comma-separated list of role names to which the task applies. If no `roles:` clause is provided then the task applies to all roles. The `<task-body>` is similar to a Bash function body and can contain a mix of valid bash statements, task invokations, and `ssh:` statements which are described below.

The `ssh:` statement can appear within a task definition body and directs the task to perform the statements within its body on all the machines defined by the roles associated with the task. The following is the BNF for the ssh: statement:

    ssh: [<ssh-options>] {
      <ssh-body>
    }

The `<ssh-body>` is a Bash script that will get executed, in parallel, on all machines defined by the set of roles associated with the task. The optional `<ssh-options>` argument is a space-separated list of options that control the behavior of the ssh command. Currently, the only supported option is `random-start-delay=<milliseconds>`. This directs the ssh tool to randomly wait `<milliseconds>` milliseconds before running the script on each machine (to avoid a potential thundering herd problem). The following are examples of task definitions:

_Task Example 1_

    # Start slave processes.  Starts slave processes by starting the FS broker and
    # RangeServers from the current installation.  The processes are started with a
    # random start delay of 5000 milliseconds.
    task: start_slaves roles: slave {
      ssh: random-start-delay=5000 {
        ${INSTALL_PREFIX}/current/bin/start-fsbroker.sh ${FS} ${CONFIG}
        ${INSTALL_PREFIX}/current/bin/start-rangeserver.sh ${CONFIG}
      }
    }

_Task Example 2_

    # Distribute installation.  This task writes the value of the variable
    # \$HADOOP_DISTRO (${HADOOP_DISTRO}) into the conf/hadoop-distro file of the
    # Hypertable \$HYPERTABLE_VERSION (${HYPERTABLE_VERSION}) installation and then
    # runs the rsync_installation task.
    task: dist roles: source {
      if [ ! -f ${INSTALL_DIR}/conf/hadoop-distro ] ||
         [ "`cat ${INSTALL_DIR}/conf/hadoop-distro`" != "${HADOOP_DISTRO}" ]; then
        ssh: {
          echo ${HADOOP_DISTRO} > ${INSTALL_DIR}/conf/hadoop-distro
        }
      fi
      rsync_installation
    }

In Task Eample 2, `rsync_installation` is the name of another task to be executed as part of the `dist` task. Tasks compile down into Bash functions, so the `rsync_installation` statement translates directly into a Bash function call.

####  Include

Another advantage of the ht_cluster tool over Capistrano is that the cluster definition statements can be split into separate files that can be updated independently. This is accomplished with the include: statement that has the following BNF:

    include: <pathname>

The `<pathname>` argument is either a relative or absolute pathname of another cluster definition file that is to be included as part of the definition. If a relative path name is supplied, it is relative to the directory of the parent file (i.e. the file containing the include: statement). All of the definitions in the parent file or any previously included cluster definition file, up to the include: statement, are visible to the included file. This allows deployment-specific definitions (e.g. roles) to be defined in a parent file and deployment-agnostic definitions (e.g. tasks) to be defined in an included file which can be upgraded independently. Comparing this with Capistrano, to update task definitions, one had to manually construct a new Capistrano definition file (Capfile) by cutting and pasting the existing role definitions with the newly updated task definitons. The following is an example cluster.def file that illustrates the use of the include: statement.

    INSTALL_PREFIX=/opt/hypertable
    HYPERTABLE_VERSION=0.9.8.4
    PACKAGE_FILE=/root/packages/hypertable-0.9.8.4-linux-x86_64.tar.gz
    FS=hadoop
    HADOOP_DISTRO=cdh4
    ORIGIN_CONFIG_FILE=/root/hypertable.cfg
    PROMPT_CLEAN=true

    role: source test00
    role: master test[00-02]
    role: hyperspace test[00-02]
    role: slave  test[03-99]
    role: thriftbroker
    role: spare

    include: "core.tasks"

The core.tasks file contains all of the task definition statements and can be updated with bug fixes and enhancements without requiring any modification to the `cluster.def` file.

### Interactive Mode

Arbitrary shell commands or cluster definition tasks can be run remotely on any set of machines using the syntax described below. To run `ht_cluster` in interactive mode, run it without any arguments. Type 'quit' or 'exit' to exit the command interpreter.

    $ ht cluster
    cluster>

**Running a shell command on all roles**

To run a shell command on all hosts specified in all role definitons in the cluster definition file, just enter the command at the `cluster>` prompt, for example:

    cluster> echo "Hello, World!"
    [test00] Hello World!
    [test01] Hello World!
    [test02] Hello World!
    …

**Running a shell command on a specific set of hosts**

To run a shell command on a specific set of hosts, precede the command with `on <hostspec>` at the `cluster>` prompt, where `<hostspec>` is a [host specification pattern](ht_ssh.md#host-specification-pattern). For example:

    cluster> on test[02-04] echo "Hello, World!"
    [test02] Hello World!
    [test03] Hello World!
    [test04] Hello World!

**Running a shell command on a specific set of roles**

To run a shell command on a specific set of roles, precede the command with `with <role-list>` at the `cluster>` prompt, where `<role-list>` is a comma-separated list of role names. For example:

    cluster> with master echo "Hello, World!"
    [test00] Hello World!

**Running a task**

To run a task from the interactive command prompt, just type the ‘!’ character followed by the task name and optional arguments. To run the task on a specific set of hosts, include an `on <hostspec>` clause immediately after the task name (but before the task arguments). For example:

    cluster> !start_hyperspace
    cluster> !start_hyperspace on test02

### Built-in Tasks

`ht_cluster` provides some built-in tasks. These tasks are described below.

**show_variables**

The _show_variables_ task displays all of the global variables defined in the cluster definition file, including the implicit variables generated from the role definitions (e.g. ROLE_<role>). The following shell transcript shows an example of running the show_variables task.

    $ ht cluster show_variables
    FS=hadoop
    HADOOP_DISTRO=cdh4
    HYPERTABLE_VERSION=0.9.8.4
    INSTALL_DIR=/opt/hypertable/0.9.8.4
    INSTALL_PREFIX=/opt/hypertable
    ORIGIN_CONFIG_FILE=/root/hypertable.cfg
    PACKAGE_FILE=/root/packages/hypertable-0.9.8.4-linux-x86_64.tar.gz
    PROMPT_CLEAN=true
    ROLE_hyperspace=test[00-02]
    ROLE_master=test[00-02]
    ROLE_slave=test[03-99] - test37
    ROLE_source=test00
    ROLE_spare=
    ROLE_thriftbroker=
    RSYNC=rsync -av -e 'ssh -o StrictHostKeyChecking=no'
    RS_DUMP_FILE=/tmp/rsdump.txt
    THRIFTBROKER_ARGS=

**with**

The _with_ task provides a way to run a shell command on the hosts of a specific role or set of roles. The following shell transcript shows an example of running the with task to run the hostname command on the master and slave roles.

    $ ht cluster with master,slave hostname
    [test00] test00.admin.hypertable.com
    [test01] test01.admin.hypertable.com
    [test02] test02.admin.hypertable.com
    [test03] test03.admin.hypertable.com
    [test04] test04.admin.hypertable.com
    …

### Task Help

The ht_cluster tool accepts a `–T` (or `-–tasks`) argument that will display all of the known task names along with their brief description. The following shell transcript shows an example of running `ht_cluster` with the `–T` argument.

    $ ht cluster –T

    TASK                          DESCRIPTION
    ============================= =================================================
    destroy ..................... Destroy database removing all tables
    destroy_hyperspace .......... Destroy Hyperspace state
    destroy_masters ............. Destroy master state
    destroy_slaves .............. Destroy slave state
    dist ........................ Distribute installation
    fhsize ...................... FHS-ize the installation
    install_origin_config ....... Install origin configuration file
    install_package ............. Install package on all machines
    kill ........................ Kill all Hypertable processes
    push_config ................. Push config file out to all machines
    rangeserver_dump ............ Dump RangeServer statistics
    restart_ganglia ............. Restart Ganglia
    rsync_config_dir ............ Rsync config dir from source machine to all
    rsync_installation .......... Rsync installation dir from source machine to all
    run_test .................... Run tests
    run_test_dispatcher ......... Start test dispatcher
    set_current ................. Set the symbolic link 'current' to point to $HYPER
    set_hadoop_distro ........... Set Hadoop distro
    start ....................... Start all Hypertable processes
    start_database .............. Start primary Hypertable processes
    start_ganglia ............... Start Ganglia
    start_gmetad ................ Start Ganglia gmetad
    start_gmond ................. Start Ganglia gmond
    start_hyperspace ............ Start hyperspace
    start_masters ............... Start master processes
    start_monitoring ............ Start monitoring server
    start_slaves ................ Start slave processes
    start_test_clients .......... Start test clients
    start_thriftbrokers ......... Start ThriftBrokers
    start_thriftbrokers_only .... Start ThriftBrokers on ThriftBroker-only servers
    start_thriftbrokers_primary . Start ThriftBrokers on primary servers
    stop ........................ Stop all Hypertable processes
    stop_database ............... Stop primary database processes
    stop_fsbrokers .............. Stop FS brokers
    stop_ganglia ................ Stop Ganglia
    stop_gmetad ................. Stop Ganglia gmetad
    stop_gmond .................. Stop Ganglia gmond
    stop_hyperspace ............. Stop Hyperspace
    stop_masters ................ Stop masters
    stop_monitoring ............. Stop monitoring servers
    stop_slaves ................. Stop slaves
    stop_test ................... Stop tests
    stop_thriftbrokers .......... Stop ThriftBrokers
    stop_thriftbrokers_only ..... Stop ThriftBroker on ThriftBroker-only servers
    stop_thriftbrokers_primary .. Stop ThriftBroker on primary servers
    upgrade ..................... Verify and upgrade installation
    upgrade_installation ........ Upgrade installation
    verify_upgrade .............. Verify upgrade

To get the long description of a task the `–e <taskname>` argument may be supplied, for example:

    $ ht cluster –e dist

    dist
    ====
    Distribute installation.  This task writes the value of the variable
    $HADOOP_DISTRO (cdh4) into the conf/hadoop-distro file of the Hypertable
    $HYPERTABLE_VERSION (0.9.8.4) installation and then runs the
    rsync_installation task.
    -- ROLES: source

### Internals

The `ht_cluster` tools is driven off a cluster configuration file that is mostly a bash script with a few additional constructs for defining tasks and roles and for including other configuration files. When `ht_cluster` runs for the first time (and each time the configuration file changes), it will compile the configuration file into a bash script and will store it in a file with the following path name:

    ~/.cluster + <absolute-path-to-cluster-def-file>  + .sh

To get an idea of what the compiled configuration looks like, take a look at the above file, or run `ht_cluster` with the `–-display-script` argument, which will cause the script to be written to the terminal. The generated script is fairly voluminous, so we won’t reproduce it in its entirety here. Some of the important sections are covered below.

**Header**

The script starts out with a comment header such as the one shown below.

    #!/bin/bash
    #
    # version: 0.9.8.4 (v0.9.8.4-0-gdebbc65-dirty)
    # dependency: /opt/hypertable/current/conf/core.tasks

The `version:` and `dependency:` comments are used by `ht_cluster` to determine if the configuration needs to be re-compiled. If the version of `ht_cluster` being run does not match the `version:` comment, or if the modification timestamp of any of the files listed in the `dependency:` comments is newer than the modification timestamp of the compiled script, it will recompile the configuration file.

**Variable definitions**

All global variable declarations are translated to allow them to be overridden by the environment. For example:

    INSTALL_PREFIX=${INSTALL_PREFIX:-/opt/hypertable}
    HYPERTABLE_VERSION=${HYPERTABLE_VERSION:-0.9.8.4}
    PACKAGE_FILE=${PACKAGE_FILE:-/root/packages/hypertable-0.9.8.4-linux-x86_64.tar.gz}
    FS=${FS:-hadoop}
    HADOOP_DISTRO=${HADOOP_DISTRO:-cdh4}
    ORIGIN_CONFIG_FILE=${ORIGIN_CONFIG_FILE:-/root/hypertable.cfg}
    PROMPT_CLEAN=${PROMPT_CLEAN:-true}

**Role definitions**

Role definition statements are translated into simple variable definitions, where the variable name is the name of the role prefixed with `ROLE_`. For example:

    ROLE_source="test00"
    ROLE_master="test[00-02]"
    ROLE_hyperspace="test[00-02]"
    ROLE_slave="test[03-99] - test37"
    ROLE_thriftbroker=""
    ROLE_spare=""

**Task definition**

Tasks compile directly into Bash functions. For example, the `dist` task shown in _Task Example 2_ of the [Cluster Definition Syntax -> Tasks](ht_cluster.md#tasks) section compiles into a Bash function that looks something like the following:

    dist () {
      local _SSH_HOSTS="(${ROLE_source})"
      if [ $# -gt 0 ] && [ $1 == "on" ]; then
        shift
        if [ $# -eq 0 ]; then
          echo "Missing host specification in 'on' argument"
          exit 1
        else
          _SSH_HOSTS="$1"
          shift
        fi
      fi
      echo "dist $@"
      if [ ! -f ${INSTALL_DIR}/conf/hadoop-distro ] ||
         [ "`cat ${INSTALL_DIR}/conf/hadoop-distro`" != "${HADOOP_DISTRO}" ]; then
        /opt/hypertable/current/bin/ht ssh " ${_SSH_HOSTS}" "echo ${HADOOP_DISTRO} > ${INSTALL_DIR}/conf/hadoop-distro"
        if [ $? -ne 0 ]; then
          exit 1
        fi
      fi
      rsync_installation
    }

Notice how the ssh: statement compiles into an invocation of the [ht_ssh](ht_ssh.md) tool and uses the `_SSH_HOSTS` local variable as the host specification. The `_SSH_HOSTS` variable is initialized to the role variables derived from the `roles:` clause of the `task:` statement but can be overridden by passing an `on <hostspec>` argument to the task. Also notice how the invocation of the `rsync_installation` task is just a call to the corresponding Bash function.

**Command-line Argument Parsing**

The compiled Bash script also includes logic to parse command line arguments for task names and invokes the corresponding task Bash function. For example:

    if [ $1 == "clean_hyperspace" ]; then
      shift
      clean_hyperspace $@
    elif [ $1 == "clean_masters" ]; then
      shift
      clean_masters $@
    elif [ $1 == "clean_slaves" ]; then
      shift
      clean_slaves $@
    elif [ $1 == "cleandb" ]; then
      shift
      cleandb $@
    …

This is how `ht_cluster` runs tasks. It simply launches the Bash script, passing the task name along with its arguments as command line parameters to the script.
