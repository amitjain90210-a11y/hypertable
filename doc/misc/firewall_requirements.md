# Firewall Requirements

Hypertable is a distributed application that consists of multiple processes that communicate with one another over a network. Firewalls can prevent Hypertable from working properly by blocking network traffic between the processes. This document describes the network ports used by Hypertable which need to be opened up in any firewall that sits between Hypertable processes.

### Hypertable Network Ports

Port |  Protocol |  Service
---|---|---
38030 |  TCP |  DFS Broker
38040 |  TCP |  Hyperspace
38040 |  UDP |  Hyperspace
38041 |  TCP |  Hyperspace
38050 |  TCP |  Master
38060 |  TCP |  Range Server
38080 |  TCP |  Thrift Broker
38090 |  TCP |  Monitoring UI

### Hypertable UDP Traffic

Hyperspace exchanges keepalive UDP packets with all of its clients (e.g. Application, RangeServer, Master, etc.). It listens for incoming UDP packets on port 38040 and returns a keepalive response to the originating address. A problem can arise due to the default behavior of clients choosing an arbitrary ephemeral port from which to send the keepalive packet. If your firewall is configured with rules that are very strict in regards to which UDP ports it will allow traffic to, it may block the keepalive responses back to the originating ephemeral port on the client. To force clients to send keepalive packets from a specific UDP port, say 38049, add the following line to your hypertable.cfg file and make sure UDP port 38049 is opened up on your firewall.

    Hyperspace.Client.Datagram.SendPort=38049

### iptables

iptables is the firewall that is built into the Linux kernel. If you have determined that iptables is blocking hypertable network traffic, running a script (as root) such as the following may open up the necessary ports. Consult the iptables documentation to understand exactly what this script does and to make sure it that it will, indeed, properly open up the ports.

    #!/usr/bin/env bash

    iptables -I INPUT 1 -p tcp --dport 38090 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38080 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38060 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38050 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38041 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38040 -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport 38030 -j ACCEPT
    iptables -I INPUT 1 -p udp -j ACCEPT

If these rules are too permissive for your environment, consult the iptables documentation for how to tighten them up.
