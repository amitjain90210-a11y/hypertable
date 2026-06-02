
if (JAVAC_VERSION)
  add_test(ThriftClient-java
           bash -c "${INSTALL_DIR}/bin/ht-set-hadoop-distro.sh apache3; ${INSTALL_DIR}/bin/ht-java-run.sh org.hypertable.thrift.BasicClientTest")
endif ()
