# Upgrade

This document describes how to upgrade a Hypertable installation.

## Table of Contents

### Determine if Upgrade is Format Compatible

To determine whether your existing Hypertable installation is format-compatible with a version that you are trying to upgrade to, we've provided a script, `ugrade-ok.sh`, to help you make that determination. The script has the following usage:

    $ ht-upgrade-ok.sh

    usage: ht-upgrade-ok.sh

    description:
      Determines whether or not the upgrade from Hypertable
      version  to version  is valid.   and
      are assumed to be Hypertable installation directories
      whose last path component is either a version number or
      the symbolic link "current" which points to a Hypertable
      installation directory whose last path component is a
      version number.

    return:
      Zero if upgrade is OK, non-zero otherwise

You can test the current installation against a particular version (e.g. 0.9.8.3) with a command such as the following:

    $ ht-upgrade-ok.sh /opt/hypertable/current 0.9.8.3
    $ echo $?
    0

You can test a specific version against another one with a command such as the following:

    $ ht-upgrade-ok.sh 0.9.3.0 0.9.4.0
    Incompatible upgrade a: 0.9.3.0 -> 0.9.4.0
    $ echo $?
    1

### Format Compatible Upgrade

If you're upgrading to a new release of Hypertable that is format compatible with your old one, upgrading is quick and painless, just follow the four steps listed below.

####  Step 1 - Stop Hypertable

For cluster installations, use the following command:

    $ ht cluster stop

For standalone installations, use the following command:

    $ ht-stop-servers.sh

####  Step 2 - Install the New Package

_Cluster Installation_

The Hypertable binaries can either be downloaded prepackaged, or you can compile them from source code. To install the prepackaged version, [download](http://hypertable.com/download) the Hypertable package (.dmg, .rpm, or .tar.bz2) that you want to install and put it somewhere accessible on the source machine (admin1 in this example). Modify the `HYPERTABLE_VERSION` and `PACKAGE_FILE` variables at the top of the `cluster.def` file to contain the version of Hypertable you are installing and the absolute path to the package file on the source machine, respectively. For example, if you're upgrading to version 0.9.8.3 and using the RPM package with absolute path `/root/packages/hypertable-0.9.8.3-linux-x86_64.rpm`, set the variables as follows:

    HYPERTABLE_VERSION=0.9.8.3
    PACKAGE_FILE=/root/packages/hypertable-0.9.8.3-linux-x86_64.rpm

To distribute and install the binary package on all necessary machines, issue the following command. This command will cause the package to get rsync'ed to all participating machines and installed with the appropriate package manager (`rpm`, `dpkg`, or `tar`) depending on the package type.

    $ ht cluster install_package

An alternate approach to installing the package on all machines is to install the package on the admin machine and rsync it to the rest of the cluster with `ht cluster`. On admin1 (the machine from which you administer the cluster) be sure Hypertable is installed (see Standalone installation below) in the location specified by the `INSTALL_PREFIX` variable at in cluster.def and the `HYPERTABLE_VERSION` variable matches the version you are installing (`/opt/hypertable` and `0.9.8.3` in this example). Then distribute the binaries with the following command.

    $ ht cluster dist

_Standalone Installation_

To begin the package installation, switch to the directory containing the package file and then issue the command listed below for your operating system.

**Redhat, CentOS, or SUSE Installation**

    $ sudo rpm -ivh --replacepkgs --nomd5 _package_.rpm

**Debian or Ubuntu Installation**

    $ sudo dpkg --install _package_.deb

**Bzipped Archive Installation**

    $ sudo tar xjvf _package_.tar.bz2

**Mac installation**

Double-click the _package_`.dmg` file and follow the instructions

The Redhat, Debian, and Mac packages will install Hypertable under a directory by the name of /opt/hypertable/$VERSION by default. You will need to change the ownership of the installation files and directories to the owner that you plan to launch the services as. For example:

    $ sudo chown -R john:staff /opt/hypertable/0.9.8.3

####  Step 3 - Upgrade

_Cluster Installation_

For cluster installations, run the following command:

    $ ht cluster upgrade

This command performs the following actions:

  1. Verifies that the upgrade is format compatible
  2. Copies the contents of the conf/, hyperspace/, fs/, run/, and log/ directories from the old installation (referenced from the current symlink) into the new installation. If any of these directories are symlinked, then an identical symlink will be created in the new installation and the contents are not copied for that directory.
  3. Sets the _current_ symlink on all machines to point to the new installation

_Standalone Installation_

For standalone installations, run the following commands (change 0.9.8.3 to the version that you're installing):

    ht-upgrade.sh /opt/hypertable/current 0.9.8.3
    rm -f /opt/hypertable/current
    ln -s /opt/hypertable/0.9.8.3 /opt/hypertable/current

####  Step 4 - Start Hypertable

For cluster installations, run the following command:

    $ ht cluster start

For standalone installations, run the following command:

    ht-start-all-servers.sh local

### Format Incompatible upgrade

If the new release you are installing is incompatible with the old release, you will need to backup and restore all of your tables. See the section on how to backup and restore tables. Here's the basic upgrade sequence:

  1. Backup your tables using the `backup.sh` script shown under [Backup and Restore](../administrator_guide/backing_up_and_restoring_tables.md)
  2. Remove existing installation (e.g. `rm -rf /opt/hypertable/$OLDVERSION`)
  3. Install the new release (see [Installation](index.md))
  4. Restore your tables using the `restore.sh` script shown under [Backup and Restore](../administrator_guide/backing_up_and_restoring_tables.md)
