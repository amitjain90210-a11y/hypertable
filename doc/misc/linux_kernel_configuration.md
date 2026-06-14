# Linux Kernel Configuration

The Linux operating system is a general purpose operating system that is designed for a wide variety of use cases rangng from interactive desktop environments to backend server operation. The Linux kernel exposes some configuration parameters that can be tuned to optimize the behavior of the kernel for the specific workload which the operating system will be handling. The default parameters configured in most LInux distributions represent a trade-off between the desktop and backend server enviroments. This document describes how to configure these kernel parameters to get maximum efficiency for the Hypertable server machines.

### Tuning the Kernel

To tune the Hypertable server machines for maximum efficiency, we recommend making the following changes to the kernel configuration parameters. You must be logged in as root to run the following comands.

    sysctl -w net.core.somaxconn=4000
    sysctl -w net.ipv4.tcp_fin_timeout=20
    sysctl -w net.ipv4.tcp_max_syn_backlog=40000
    sysctl -w net.ipv4.tcp_sack=1
    sysctl -w net.ipv4.tcp_timestamps=0
    sysctl -w net.ipv4.tcp_tw_reuse=1
    sysctl -w net.ipv4.tcp_window_scaling=1
    sysctl -w vm.swappiness=0

NOTE: We recommend that you first try these settings to make sure they work well. We've seen problems with the vm.swappiness parameter change that cause some processes to excessive disk I/O. If you experience the same problem, try setting all of the parameters above except for vm.swappiness.

### Making the changes permanent

Once you've tested your system with the above parameter changes and have verified that they work well, you can make these changes permanent on your systems by adding the following lines to /etc/sysctl.conf:

    net.core.somaxconn = 4000
    net.ipv4.tcp_fin_timeout = 20
    net.ipv4.tcp_max_syn_backlog = 40000
    net.ipv4.tcp_sack = 1
    net.ipv4.tcp_timestamps = 0
    net.ipv4.tcp_tw_reuse = 1
    net.ipv4.tcp_window_scaling = 1
    vm.swappiness = 0
