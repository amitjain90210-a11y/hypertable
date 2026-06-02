<?php
#
# Copyright (C) 2007-2016 Hypertable, Inc.
#
# This file is part of Hypertable.
#
# Hypertable is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or any later version.
#
# Hypertable is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#

$thriftLibDir = '/usr/lib/php';
$genPhpDir = $GLOBALS['THRIFT_ROOT'] . '/gen-php';

spl_autoload_register(function ($class) use ($thriftLibDir, $genPhpDir) {
  if (strpos($class, 'Thrift\\') === 0) {
    $relative = substr($class, strlen('Thrift\\'));
    $file = $thriftLibDir . '/' . str_replace('\\', '/', $relative) . '.php';
    if (file_exists($file)) {
      require_once $file;
      return true;
    }
  } elseif (strpos($class, 'Hypertable_ThriftGen2\\') === 0) {
    $base = substr($class, strlen('Hypertable_ThriftGen2\\'));
    $file = $genPhpDir . '/Hypertable_ThriftGen2/' . $base . '.php';
    if (file_exists($file)) {
      require_once $file;
      return true;
    }
  } elseif (strpos($class, 'Hypertable_ThriftGen\\') === 0) {
    $base = substr($class, strlen('Hypertable_ThriftGen\\'));
    $file = $genPhpDir . '/Hypertable_ThriftGen/' . $base . '.php';
    if (file_exists($file)) {
      require_once $file;
      return true;
    }
  }
  return false;
});

use Thrift\Transport\TSocket;
use Thrift\Transport\TFramedTransport;
use Thrift\Protocol\TBinaryProtocol;

class Hypertable_ThriftClient extends \Hypertable_ThriftGen2\HqlServiceClient {
  function __construct($host, $port, $timeout_ms = 300000, $do_open = true) {
    $socket = new TSocket($host, $port);
    $socket->setSendTimeout($timeout_ms);
    $socket->setRecvTimeout($timeout_ms);
    $this->transport = new TFramedTransport($socket);
    $protocol = new TBinaryProtocol($this->transport);
    parent::__construct($protocol);

    if ($do_open)
      $this->open();
  }

  function __destruct() { $this->close(); }

  function open() {
    $this->transport->open();
    $this->do_close = true;
  }

  function close() {
    if ($this->do_close)
      $this->transport->close();
  }
}
