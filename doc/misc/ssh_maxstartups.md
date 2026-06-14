# SSH Connection Limit

### MaxStartups

Hypertable is typically administered with Capistrano, a tool that automates tasks over a set of machines through the use of ssh. There is a problem with the default sshd configuration that can cause Capistrano to not work properly. sshd limits the number of simultaneous connections that it allows. Some of the Capistrano tasks cause all of the slave machines to pull data from the admin machine simultaneously, which creates a large number of simultaneous ssh connections to the admin machine, causing many of them to fail. Problem symptoms include error messages such as the following when running certain Capistrano commands.

    *** [err :: uranos4.dq.isl.ntt.co.jp] ssh_exchange_identification:
    Connection closed by remote host
    *** [err :: uranos4.dq.isl.ntt.co.jp] rsync: connection unexpectedly
    closed (0 bytes received so far) [receiver]
    *** [err :: uranos4.dq.isl.ntt.co.jp]
    *** [err :: uranos4.dq.isl.ntt.co.jp] rsync error: unexplained error
    (code 255) at io.c(453) [receiver=2.6.9]
    *** [err :: uranos4.dq.isl.ntt.co.jp]

This problem can be fixed by increasing the value of the _MaxStartups_ property in the sshd configuration file on the admin machine. Here's the man page section for MaxStartups:

**MaxStartups**

Specifies the maximum number of concurrent unauthenticated connections to the sshd daemon. Additional connections will be dropped until authentication succeeds or the LoginGraceTime expires for a connection. The default is 10.

To do this, modify the sshd config file (either `/etc/sshd_config` or `/etc/ssh/sshd_config`) on the admin machine and set the MaxStartups property to something larger than the total number of slaves in the Hypertable cluster. For example, if you have less that 100 nodes, you might change the MaxStartups line in the sshd config file to:

    MaxStartups 100

After you've made this change, you'll need to restart sshd. On RedHat or CentOS based systems, you can issue the following command (as root).

    $ service sshd restart

On Debian-based systems, the following command can be issued (as root).

    $ /etc/init.d/ssh restart
