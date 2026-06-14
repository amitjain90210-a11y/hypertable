# Password-less SSH Login

### Generating Keys on Source Machine

On the source machine from which you want to initiate password-less ssh connections (admin), run ssh-keygen to generate a public and private key pair. The following is an example session showing the creation of a personal private/public key pair.

    [chris@admin ~]$ ssh-keygen -t rsa
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/chris/.ssh/id_rsa):
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/chris/.ssh/id_rsa.
    Your public key has been saved in /home/chris/.ssh/id_rsa.pub.
    The key fingerprint is:
    f6:61:a8:27:35:cf:4c:6d:13:22:70:cf:4c:c8:a0:23 chris@admin

The command `ssh-keygen -t rsa` initiated the creation of the key pair. No passphrase was entered (_Enter_ key was pressed instead). The private key was saved in `.ssh/id_rsa`. This file is read-only and should be kept private, no one else must see the content of this file, as it is used to decrypt all correspondence encrypted with the public key `.ssh/id_rsa.pub`.

### Adding Public Key to Target Machines

The public key is save in `.ssh/id_rsa.pub`. The contents of this file might look something like the following.

    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEArkwv9X8eTVK4F7pMlSt45pWoiakFkZMw
    G9BjydOJPGH0RFNAy1QqIWBGWv7vS5K2tr+EEO+F8WL2Y/jK4ZkUoQgoi+n7DWQVOHsR
    ijcS3LvtO+50Np4yjXYWJKh29JL6GHcp8o7+YKEyVUMB2CSDOP99eF9g5Q0d+1U2WVdB
    WQM= chris@admin

It is one line in length. To enable password-less ssh logins to a set of machines, slave01, slave02, and slave03, copy the `.ssh/id_rsa.pub` file to all three machines and then concatenate it to the file `~/.ssh/authorized_keys` on each of the three machines. Make sure the file access permissions are correct on all the ssh files and directories. On the source machine (admin):

    $ chmod 755 ~
    $ chmod 700 ~/.ssh
    $ chmod 600 ~/.ssh/id_rsa

On the target machines (slave01, slave02, slave03):

    $ chmod 755 ~
    $ chmod 700 ~/.ssh
    $ chmod 400 ~/.ssh/authorized_keys
