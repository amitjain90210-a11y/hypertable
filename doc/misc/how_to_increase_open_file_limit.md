# Open File Limit

### Linux

To increase the open file limit to 65K for all users, edit the file `/etc/security/limits.conf` and add the following lines.

    * - nofile 65536

This will affect the limit for all user accounts and will increase the kernel's memory usage. This is not such a big problem with modern systems containing 8GB of RAM or more, but if your system is tight on memory and/or runs an extraordinarily large number of processes, you might want to restrict this limit change to just the set of user accounts that need it. For example, to just change it for the _hdfs_ and _hypertable_ user accounts, add the following two lines instead.

    hdfs - nofile 65536
    hypertable - nofile 65536

To apply the changes in `/etc/security/limits.conf` on Ubuntu or any other Debian-based systems, add the following line to the `/etc/pam.d/common-session` file:

    session required  pam_limits.so

For the changes to take effect, you'll need to log out and log back in, then restart Hypertable and Hadoop.

### Mac OSX

To change max number of open files run the following command.

    launchctl limit maxfiles 65536 65536

To change the setting permanently add the following line to the file `/etc/launchd.conf`.

    limit maxfiles  65536           65536
