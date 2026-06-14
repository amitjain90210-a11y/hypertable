# Multi-host ssh tool

The `ht_ssh` program proivdes an efficient way to run a command on a set of hosts in parallel.

## Table of Contents

### Features

**Optimum Performance**

It is built with libssh 0.6.3 ([http://www.libssh.org/](https://www.libssh.org/)) and is designed for maximum performance. The establishment of ssh connections and command execution happen _asynchronously_ and _in parallel_ using the most efficient polling mechanism available (e.g. epoll on Linux, kqueue on OSX).

**Host Specification Pattern**

The set of hosts on which to run the command is given with a concise host specification pattern. Assuming that the hosts in your cluster follow a naming convention such as `test00`, `test01`, ... `test99`, the specification pattern allows you to specify a large number of hosts in a very concise way, providing '+' and '-' operators to include and exclude hosts. For example, the pattern test[00-99]-test37 expands to test00, test01, ... test99, exlucding test37.

**Stable Output**

If the output of the command that you run is stable, then the output of ht_ssh will be stable on succcessful runs. It achieves this by buffering the command output from all hosts and then dumping the output to the terminal in sorted order of host name. For example, the command

    ht ssh test[08-15] hostname

will consistenly produce stable output similar to the following:

    [test08] test08.admin.hypertable.com
    [test09] test09.admin.hypertable.com
    [test10] test10.admin.hypertable.com
    [test11] test11.admin.hypertable.com
    [test12] test12.admin.hypertable.com
    [test13] test13.admin.hypertable.com
    [test14] test14.admin.hypertable.com
    [test15] test15.admin.hypertable.com

**Random Start Delay**

A thundering herd problem is a problem that occurs when a large set of processes simultaneously access a central resource and overwhelm it. The central resource may be a master server that can fail if bombarded with too many simultaneous requests. To avoid the thundering herd problems, the `--random-start-delay <millis>` option can be provided. This option will delay the start of the command on each host by a random time interval between `0` and `<millis>` milliseconds.

### Usage

    usage: ht_ssh [options] <hosts-specification> <command>

    options:
      --debug   Turn on verbose debugging output
      --random-start-delay <millis>
                Wait a random amount of time between 0 and <millis>
                prior to starting each command

### Running the Tool

The `ht_ssh` tool ships with the latest version of Hypertable which can be downloaded from the [Hypertable Download](http://hypertable.com/download) page. Package formats include `.rpm`, `.deb`, and `.tar.bz`. The dependent shared libraries for all of the tools included in the package are bundled inside the installation. In the installation `bin/` directory you will find a simple wrapper script, `ht`, that should be used to launch any of the Hypertable tools. Prior to launching the tool, the `ht` wrapper script will set up `LD_LIBRARY_PATH` (or `DYLD_LIBRARY_PATH` on OSX) environment variable to include the `lib/` directory when the dependent libraries can be found. We recommend that you add the Hypertable `bin/` directory to your path. For example, let's say you've installed version 0.9.8.3 of the Hypertable package in the following location:

    /opt/hypertable/0.9.8.3

Create a "current" link that points to the installed version as follows:

    cd /opt/hypertable
    ln -sf 0.9.8.3 current

Then edit the `PATH` environment variable in your shell startup script to include the path `/opt/hypertable/current/bin`. For example, with bash, you would add the following line to your `.bashrc` file:

    export PATH=$PATH:/opt/hypertable/current/bin

Once you've done this (and log out and log back in to pick up the `PATH` change), you can run the ht_ssh tool as follows:

    ht ssh

### Host Specification Pattern

The host specification syntax allows you to concisely specify a large number of hosts that match a host name pattern. The syntax supports a numeric range specifier (e.g. `[00-10]`) to specify a range of hosts containing a numeric field in their name. Operators '+' and '-' minus can be used to include or exclude patterns and parenthesis '(' and ')' can be used to group patterns. The ',' operator or lack of any operator between two host patterns is equivalent to the '+' operator. The best way to illustrate the host specification pattern syntax is through a set of examples (see table below).

**Host Specification Pattern Examples**

Pattern | Expansion
---|---
` host[07-12]` |  ` host07 host08 host09 host10 host11 host12`
` host[7-12]` |  ` host7 host8 host9 host10 host11 host12`
` host[1-3].bar.com` |  ` host1.bar.com host2.bar.com host3.bar.com`
` host[01-10] - host[04-07]` |  ` host01 host02 host03 host08 host09 host10`
` host[01-10] - (host[02-05] + host07)` |  ` host01 host06 host08 host09 host10`
` host1, host2, host[3-5]` |  ` host1 host2 host3 host4 host5`
` host1 host2 host[3-5]` |  ` host1 host2 host3 host4 host5`
` 192.168.17.[9-11]` |  ` 192.168.17.9 192.168.17.10 192.168.17.11`

### Examples

The best way to learn ht_ssh is to play around with it. But here are some examples to get you started. The following simple example displays short hostnames.

    $ ht ssh test[10-15] hostname -s
    [test10] test10
    [test11] test11
    [test12] test12
    [test13] test13
    [test14] test14
    [test15] test15

To supply a host specification pattern that contains space characters, supply the host specification as a single argument enclosed by quotes:

    $ ht ssh "test[10-15] - test12" hostname -s
    [test10] test10
    [test11] test11
    [test13] test13
    [test14] test14
    [test15] test15

Shell variables and command substitution happens locally if not properly escaped. For example, the following two commands, when run on host `test08.admin.hypertable.com`:

    ht ssh "test[10-15]" "echo hostname=$HOSTNAME"
    ht ssh "test[10-15]" "echo hostname=`hostname`"

will produce the following output.

    [test10] hostname=test08.admin.hypertable.com
    [test11] hostname=test08.admin.hypertable.com
    [test12] hostname=test08.admin.hypertable.com
    [test13] hostname=test08.admin.hypertable.com
    [test14] hostname=test08.admin.hypertable.com
    [test15] hostname=test08.admin.hypertable.com

To force variable expansion and command substitution to happen on the remote machine, escape the variable names and backticks with a backslash character. For exmaple, the following two commands, when run on host `test08.admin.hypertable.com`:

    ht ssh "test[10-15]" "echo hostname=\$HOSTNAME"
    ht ssh "test[10-15]" "echo hostname=\`hostname\`"

will produce the following output:

    [test10] hostname=test10.admin.hypertable.com
    [test11] hostname=test11.admin.hypertable.com
    [test12] hostname=test12.admin.hypertable.com
    [test13] hostname=test13.admin.hypertable.com
    [test14] hostname=test14.admin.hypertable.com
    [test15] hostname=test15.admin.hypertable.com

### Exit Status

If all of the comands run successfully and return exit status `0`, then `ht_ssh` will exit with status `0`. If there are any failures during the connection establishment phase, `ht_ssh` will exit with status `1`. If there are any failures during the command execution phase, the names of the hosts that failed will be collected and written as a comma-separated list to stderr at the end of all of the other output and `ht_ssh` will return exit status `2`. This last behavior can be seen by hitting `ctrl-c` during command execution:

    $ ht ssh test[10-15] "if [ \`hostname -s\` == \"test12\" ]; then sleep 5; fi; hostname"
    [test10] test10.admin.hypertable.com
    [test11] test11.admin.hypertable.com
    ^C[test13] test13.admin.hypertable.com
    [test14] test14.admin.hypertable.com
    [test15] test15.admin.hypertable.com
    Command failed on hosts:  test12

    $ echo $?
    2
