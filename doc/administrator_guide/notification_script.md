# Notification Script

This document describes how to install a notification script.

###

The Hypertable Master will invoke a notification script (`conf/notification-hook.sh`) to inform the Hypertable administrator of certain events such as machine failure or any problems that may have been encountered during machine failure recovery. The script accepts two arguments, a subject string and a message body string. The prefix of the subject line string can be examined to determine the type of notification, "NOTICE" indicating a notification of abnormal condition, and "ERROR" indicating a hard error that requires intervention. The following is an example notification script (`/opt/hypertable/current/conf/notification-hook.sh`) that can be used to email notificaiton to a list of administrators:

    #!/usr/bin/env bash

    recipients="root"
    subject=$1
    message=$2
    echo -e $message | mail -s "$subject" ${recipients}

Modify the _recipients_ variable to contain the the list of recipients to whom notificaiton messages are to be sent. Verify that the script works properly by testing it manually:

    /opt/hypertable/current/conf/notification-hook.sh "Test Message" "This is a test."

Once the script is working properly, you can distribute it to all appropriate machines with:

    ht cluster push_config
