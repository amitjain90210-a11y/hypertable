# Filesystem Hierarchy Standard

The binary packages will install Hypertable entirely under /opt/hypertable/$VERSION. The [Filesystem Hierarchy Standard (FHS)](http://www.pathname.com/fhs/pub/fhs-2.3.html) states that host-specific configuration files for add-on application software packages should reside under /etc/opt and that variable data of the packages (log files, etc.) should reside under /var/opt.

### FHS-izing the Hypertable Installation

Hypertable ships with a script that will modify an installation to conform to the Filesystem Hierachy Standard. If you're running as a user other than root, first create hypertable directories in `/etc/opt` and `/var/opt` and change ownership to the user account under which the binaries will be run. For example:

    $ sudo mkdir /etc/opt/hypertable /var/opt/hypertable
    $ sudo chown doug:staff /etc/opt/hypertable /var/opt/hypertable

The Hypertable distribution comes with a script called `fhsize.sh` which will setup an installation to conform to the Filesystem Hierarchy Standard. The default Capfile includes a task fhsize which will run the script cluster-wide (`cap fhsize`). The following example illustrates how to run `fhsize.sh` on a standalone installation.

    $ /opt/hypertable/0.9.5.3/bin/fhsize.sh
    Setting up /var/opt/hypertable
    Setting up /etc/opt/hypertable

We **strongly** recommend that you fhsize your installation. The nice thing about FHS-izing your installations is that the directories containing the config files, hyperspace, run directory, localBroker root directory, and log archives carry over from one version to the next. Otherwise, you need to copy the contents of the `conf/`, `hyperspace/`, `run/`, `fs/`, and `log/` from your old install to the new one each time you upgrade. When fhsize.sh is run for the first time, it will copy the contents of the `conf/` directory from the binary package to `/etc/opt/hypertable` and it will copy the contents of the `fs/`, `run/`, `hyperspace/`, and `log/` directories to corresponding directories in `/var/opt/hypertable` if they are non-empty. When fhsize.sh is run subsequently, it will detect the existence of files in `/etc/opt/hypertable` and /var/opt/hypertable and will leave them intact. Here's what the installation directory looks like after running fhsize.sh:

    $ ls -l /opt/hypertable/0.9.5.3/
    total 16
    drwxr-xr-x 2 doug staff 4096 2011-04-14 19:44 bin
    lrwxrwxrwx 1 doug staff   15 2011-04-14 19:45 conf -> /etc/opt/hypertable
    drwxr-xr-x 5 doug staff 4096 2011-04-14 19:45 examples
    lrwxrwxrwx 1 doug staff   18 2011-04-14 19:45 fs -> /var/opt/hypertable/fs
    lrwxrwxrwx 1 doug staff   26 2011-04-14 19:45 hyperspace -> /var/opt/hypertable/hyperspace
    drwxr-xr-x 9 doug staff 4096 2011-04-14 19:44 include
    drwxr-xr-x 7 doug staff 4096 2011-04-14 19:45 lib
    lrwxrwxrwx 1 doug staff   19 2011-04-14 19:45 log -> /var/opt/hypertable/log
    lrwxrwxrwx 1 doug staff   19 2011-04-14 19:45 run -> /var/opt/hypertable/run
