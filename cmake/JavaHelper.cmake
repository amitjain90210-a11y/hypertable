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
# along with Hypertable. If not, see <http://www.gnu.org/licenses/>
#

set(APACHE1_VERSION "1.2.1")
set(APACHE2_VERSION "2.4.1")
set(APACHE3_VERSION "3.4.3")
set(CDH3_VERSION "0.20.2-cdh3u5")
set(CDH4_VERSION "2.0.0-cdh4.2.1")

# Copy Maven source tree to build directory
file(COPY java DESTINATION ${HYPERTABLE_BINARY_DIR} PATTERN pom.xml.in EXCLUDE)

# Top-level pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/pom.xml.in ${HYPERTABLE_BINARY_DIR}/java/pom.xml @ONLY)

# runtime-dependencies/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/pom.xml @ONLY)

# runtime-dependencies/common/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/common/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/common/pom.xml @ONLY)

# runtime-dependencies/apache1/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/apache1/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/apache1/pom.xml @ONLY)

# runtime-dependencies/apache2/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/apache2/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/apache2/pom.xml @ONLY)

# runtime-dependencies/cdh3/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/cdh3/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/cdh3/pom.xml @ONLY)

# runtime-dependencies/cdh4/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/cdh4/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/cdh4/pom.xml @ONLY)

# hypertable-common/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-common/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/pom.xml @ONLY)

# hypertable/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable/pom.xml @ONLY)

# hypertable-cdh3/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-cdh3/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-cdh3/pom.xml @ONLY)

# hypertable-apache1/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-apache1/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-apache1/pom.xml @ONLY)

# hypertable-apache2/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-apache2/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-apache2/pom.xml @ONLY)

# runtime-dependencies/apache3/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/runtime-dependencies/apache3/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/runtime-dependencies/apache3/pom.xml @ONLY)

# hypertable-apache3/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-apache3/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-apache3/pom.xml @ONLY)

# hypertable-examples/pom.xml
configure_file(${HYPERTABLE_SOURCE_DIR}/java/hypertable-examples/pom.xml.in
         ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/pom.xml @ONLY)


if (Thrift_FOUND)

  set(ThriftGenJava_DIR ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/src/main/java/org/hypertable/thriftgen)

  set(ThriftGenJava_SRCS
      ${ThriftGenJava_DIR}/AccessGroupOptions.java
      ${ThriftGenJava_DIR}/AccessGroupSpec.java
      ${ThriftGenJava_DIR}/CellInterval.java
      ${ThriftGenJava_DIR}/Cell.java
      ${ThriftGenJava_DIR}/ClientException.java
      ${ThriftGenJava_DIR}/ClientService.java
      ${ThriftGenJava_DIR}/ColumnFamilyOptions.java
      ${ThriftGenJava_DIR}/ColumnFamilySpec.java
      ${ThriftGenJava_DIR}/ColumnPredicate.java
      ${ThriftGenJava_DIR}/ColumnPredicateOperation.java
      ${ThriftGenJava_DIR}/HqlResult2.java
      ${ThriftGenJava_DIR}/HqlResultAsArrays.java
      ${ThriftGenJava_DIR}/HqlResult.java
      ${ThriftGenJava_DIR}/HqlService.java
      ${ThriftGenJava_DIR}/KeyFlag.java
      ${ThriftGenJava_DIR}/Key.java
      ${ThriftGenJava_DIR}/MutateSpec.java
      ${ThriftGenJava_DIR}/MutatorFlag.java
      ${ThriftGenJava_DIR}/NamespaceListing.java
      ${ThriftGenJava_DIR}/ResultAsArrays.java
      ${ThriftGenJava_DIR}/Result.java
      ${ThriftGenJava_DIR}/ResultSerialized.java
      ${ThriftGenJava_DIR}/RowInterval.java
      ${ThriftGenJava_DIR}/ScanSpec.java
      ${ThriftGenJava_DIR}/Schema.java
      ${ThriftGenJava_DIR}/TableSplit.java
  )

  add_custom_command(
    OUTPUT    ${ThriftGenJava_SRCS}
    COMMAND   thrift
    ARGS      -r -gen java -out ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/src/main/java
              ${ThriftBroker_IDL_DIR}/Hql.thrift
    DEPENDS   ${ThriftBroker_IDL_DIR}/Client.thrift
              ${ThriftBroker_IDL_DIR}/Hql.thrift
    COMMENT   "thrift2java"
  )
endif ()


add_custom_target(HypertableHadoopCDH3 ALL mvn -f java/pom.xml -Dmaven.test.skip=true -Pcdh3 package
                  DEPENDS ${ThriftGenJava_SRCS})

add_custom_target(CleanBuild0 ALL rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/target/classes
                  COMMAND rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/classes
                  DEPENDS HypertableHadoopCDH3)

add_custom_target(HypertableHadoopApache1 ALL mvn -f java/pom.xml -Dmaven.test.skip=true -Papache1 package
                  DEPENDS CleanBuild0)

add_custom_target(CleanBuild1 ALL rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/target/classes
                  COMMAND rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/classes
                  DEPENDS HypertableHadoopApache1)

add_custom_target(HypertableHadoopApache2 ALL mvn -f java/pom.xml -Dmaven.test.skip=true -Papache2 package
                  DEPENDS CleanBuild1)

add_custom_target(CleanBuild2 ALL rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-common/target/classes
                  COMMAND rm -rf ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/classes
                  DEPENDS HypertableHadoopApache2)

add_custom_target(HypertableHadoopApache3 ALL mvn -f java/pom.xml -Dmaven.test.skip=true -Papache3 package
                  DEPENDS CleanBuild2)

add_custom_target(RuntimeDependencies ALL mvn -f java/runtime-dependencies/pom.xml -Dmaven.test.skip=true package
                  DEPENDS HypertableHadoopApache3)

add_custom_target(java)
add_dependencies(java RuntimeDependencies)

# ---------------------------------------------------------------------------
# Populate lib/java/ in the build tree so tests run without 'make install'.
# Mirrors the install() rules below, but uses symlinks at configure time.
# ---------------------------------------------------------------------------
string(REPLACE "~" "$ENV{HOME}" _maven_repo "${MAVEN_REPOSITORY}")
set(_jlib ${HYPERTABLE_BINARY_DIR}/lib/java)
file(MAKE_DIRECTORY ${_jlib}/common ${_jlib}/apache2 ${_jlib}/apache3 ${_jlib}/specific)

macro(_java_link _src _dst)
  if(NOT IS_SYMLINK "${_dst}")
    file(CREATE_LINK "${_src}" "${_dst}" SYMBOLIC)
  endif()
endmacro()

# common
_java_link(${_maven_repo}/org/apache/thrift/libthrift/0.19.0/libthrift-0.19.0.jar                              ${_jlib}/common/libthrift-0.19.0.jar)
_java_link(${_maven_repo}/commons-cli/commons-cli/1.2/commons-cli-1.2.jar                                      ${_jlib}/common/commons-cli-1.2.jar)
_java_link(${_maven_repo}/commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.jar          ${_jlib}/common/commons-collections-3.2.1.jar)
_java_link(${_maven_repo}/commons-configuration/commons-configuration/1.6/commons-configuration-1.6.jar        ${_jlib}/common/commons-configuration-1.6.jar)
_java_link(${_maven_repo}/commons-io/commons-io/2.1/commons-io-2.1.jar                                        ${_jlib}/common/commons-io-2.1.jar)
_java_link(${_maven_repo}/commons-lang/commons-lang/2.6/commons-lang-2.6.jar                                  ${_jlib}/common/commons-lang-2.6.jar)
_java_link(${_maven_repo}/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar                     ${_jlib}/common/commons-logging-1.1.1.jar)
_java_link(${_maven_repo}/log4j/log4j/1.2.17/log4j-1.2.17.jar                                                 ${_jlib}/common/log4j-1.2.17.jar)
_java_link(${_maven_repo}/org/slf4j/slf4j-api/1.7.5/slf4j-api-1.7.5.jar                                       ${_jlib}/common/slf4j-api-1.7.5.jar)
_java_link(${_maven_repo}/org/slf4j/slf4j-log4j12/1.7.5/slf4j-log4j12-1.7.5.jar                               ${_jlib}/common/slf4j-log4j12-1.7.5.jar)
_java_link(${_maven_repo}/org/fusesource/sigar/1.6.4/sigar-1.6.4.jar                                          ${_jlib}/common/sigar-1.6.4.jar)

# apache2 — Hadoop JARs from Maven repo + Hypertable JARs from build tree
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-annotations/${APACHE2_VERSION}/hadoop-annotations-${APACHE2_VERSION}.jar               ${_jlib}/apache2/hadoop-annotations-${APACHE2_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-auth/${APACHE2_VERSION}/hadoop-auth-${APACHE2_VERSION}.jar                             ${_jlib}/apache2/hadoop-auth-${APACHE2_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-common/${APACHE2_VERSION}/hadoop-common-${APACHE2_VERSION}.jar                         ${_jlib}/apache2/hadoop-common-${APACHE2_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-hdfs/${APACHE2_VERSION}/hadoop-hdfs-${APACHE2_VERSION}.jar                             ${_jlib}/apache2/hadoop-hdfs-${APACHE2_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-mapreduce-client-core/${APACHE2_VERSION}/hadoop-mapreduce-client-core-${APACHE2_VERSION}.jar  ${_jlib}/apache2/hadoop-mapreduce-client-core-${APACHE2_VERSION}.jar)
_java_link(${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-apache2.jar                   ${_jlib}/apache2/hypertable-${VERSION}-apache2.jar)
_java_link(${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-apache2.jar ${_jlib}/apache2/hypertable-examples-${VERSION}-apache2.jar)

# apache3 — Hadoop 3 JARs from Maven repo + Hypertable JARs from build tree
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-annotations/${APACHE3_VERSION}/hadoop-annotations-${APACHE3_VERSION}.jar               ${_jlib}/apache3/hadoop-annotations-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-auth/${APACHE3_VERSION}/hadoop-auth-${APACHE3_VERSION}.jar                             ${_jlib}/apache3/hadoop-auth-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-common/${APACHE3_VERSION}/hadoop-common-${APACHE3_VERSION}.jar                         ${_jlib}/apache3/hadoop-common-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-hdfs/${APACHE3_VERSION}/hadoop-hdfs-${APACHE3_VERSION}.jar                             ${_jlib}/apache3/hadoop-hdfs-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-hdfs-client/${APACHE3_VERSION}/hadoop-hdfs-client-${APACHE3_VERSION}.jar               ${_jlib}/apache3/hadoop-hdfs-client-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/org/apache/hadoop/hadoop-mapreduce-client-core/${APACHE3_VERSION}/hadoop-mapreduce-client-core-${APACHE3_VERSION}.jar  ${_jlib}/apache3/hadoop-mapreduce-client-core-${APACHE3_VERSION}.jar)
_java_link(${_maven_repo}/com/fasterxml/woodstox/woodstox-core/5.4.0/woodstox-core-5.4.0.jar                  ${_jlib}/apache3/woodstox-core-5.4.0.jar)
_java_link(${_maven_repo}/org/codehaus/woodstox/stax2-api/4.2.1/stax2-api-4.2.1.jar                           ${_jlib}/apache3/stax2-api-4.2.1.jar)
_java_link(${_maven_repo}/org/apache/commons/commons-collections4/4.4/commons-collections4-4.4.jar            ${_jlib}/apache3/commons-collections4-4.4.jar)
_java_link(${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-apache3.jar                   ${_jlib}/apache3/hypertable-${VERSION}-apache3.jar)
_java_link(${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-apache3.jar ${_jlib}/apache3/hypertable-examples-${VERSION}-apache3.jar)

# specific
_java_link(${_maven_repo}/com/google/protobuf/protobuf-java/2.4.0a/protobuf-java-2.4.0a.jar                    ${_jlib}/specific/protobuf-java-2.4.0a.jar)
_java_link(${_maven_repo}/com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar                      ${_jlib}/specific/protobuf-java-2.5.0.jar)
_java_link(${_maven_repo}/com/google/guava/guava/11.0.2/guava-11.0.2.jar                                       ${_jlib}/specific/guava-11.0.2.jar)


# Common jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/thrift/libthrift/0.19.0/libthrift-0.19.0.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-cli/commons-cli/1.2/commons-cli-1.2.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-configuration/commons-configuration/1.6/commons-configuration-1.6.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-io/commons-io/2.1/commons-io-2.1.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-lang/commons-lang/2.6/commons-lang-2.6.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/log4j/log4j/1.2.17/log4j-1.2.17.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/org/slf4j/slf4j-api/1.7.5/slf4j-api-1.7.5.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/org/slf4j/slf4j-log4j12/1.7.5/slf4j-log4j12-1.7.5.jar
              DESTINATION lib/java/common)
install(FILES ${MAVEN_REPOSITORY}/org/fusesource/sigar/1.6.4/sigar-1.6.4.jar
              DESTINATION lib/java/common)

# Distro specific jars
install(FILES ${MAVEN_REPOSITORY}/com/google/protobuf/protobuf-java/2.4.0a/protobuf-java-2.4.0a.jar
              DESTINATION lib/java/specific)
install(FILES ${MAVEN_REPOSITORY}/com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar
              DESTINATION lib/java/specific)
install(FILES ${MAVEN_REPOSITORY}/com/google/guava/guava/11.0.2/guava-11.0.2.jar
              DESTINATION lib/java/specific)

# Apache Hadoop 1 jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-core/${APACHE1_VERSION}/hadoop-core-${APACHE1_VERSION}.jar
              DESTINATION lib/java/apache1)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-apache1.jar
              DESTINATION lib/java/apache1)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-apache1.jar
              DESTINATION lib/java/apache1)

# Apache Hadoop 2 jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-annotations/${APACHE2_VERSION}/hadoop-annotations-${APACHE2_VERSION}.jar
              DESTINATION lib/java/apache2)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-auth/${APACHE2_VERSION}/hadoop-auth-${APACHE2_VERSION}.jar
              DESTINATION lib/java/apache2)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-common/${APACHE2_VERSION}/hadoop-common-${APACHE2_VERSION}.jar
              DESTINATION lib/java/apache2)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-hdfs/${APACHE2_VERSION}/hadoop-hdfs-${APACHE2_VERSION}.jar
              DESTINATION lib/java/apache2)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-mapreduce-client-core/${APACHE2_VERSION}/hadoop-mapreduce-client-core-${APACHE2_VERSION}.jar
              DESTINATION lib/java/apache2)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-apache2.jar
              DESTINATION lib/java/apache2)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-apache2.jar
              DESTINATION lib/java/apache2)

# Apache Hadoop 3 jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-annotations/${APACHE3_VERSION}/hadoop-annotations-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-auth/${APACHE3_VERSION}/hadoop-auth-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-common/${APACHE3_VERSION}/hadoop-common-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-hdfs/${APACHE3_VERSION}/hadoop-hdfs-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-hdfs-client/${APACHE3_VERSION}/hadoop-hdfs-client-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-mapreduce-client-core/${APACHE3_VERSION}/hadoop-mapreduce-client-core-${APACHE3_VERSION}.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/com/fasterxml/woodstox/woodstox-core/5.4.0/woodstox-core-5.4.0.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/codehaus/woodstox/stax2-api/4.2.1/stax2-api-4.2.1.jar
              DESTINATION lib/java/apache3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/commons/commons-collections4/4.4/commons-collections4-4.4.jar
              DESTINATION lib/java/apache3)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-apache3.jar
              DESTINATION lib/java/apache3)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-apache3.jar
              DESTINATION lib/java/apache3)

# CDH3 jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-core/${CDH3_VERSION}/hadoop-core-${CDH3_VERSION}.jar
              DESTINATION lib/java/cdh3)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable/target/hypertable-${VERSION}-cdh3.jar
              DESTINATION lib/java/cdh3)
install(FILES ${HYPERTABLE_BINARY_DIR}/java/hypertable-examples/target/hypertable-examples-${VERSION}-cdh3.jar
              DESTINATION lib/java/cdh3)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/thirdparty/guava/guava/r09-jarjar/guava-r09-jarjar.jar
              DESTINATION lib/java/cdh3)

# CDH4 jars
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-annotations/${CDH4_VERSION}/hadoop-annotations-${CDH4_VERSION}.jar
              DESTINATION lib/java/cdh4)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-auth/${CDH4_VERSION}/hadoop-auth-${CDH4_VERSION}.jar
              DESTINATION lib/java/cdh4)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-common/${CDH4_VERSION}/hadoop-common-${CDH4_VERSION}.jar
              DESTINATION lib/java/cdh4)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-hdfs/${CDH4_VERSION}/hadoop-hdfs-${CDH4_VERSION}.jar
             DESTINATION lib/java/cdh4)
install(FILES ${MAVEN_REPOSITORY}/org/apache/hadoop/hadoop-mapreduce-client-core/${CDH4_VERSION}/hadoop-mapreduce-client-core-${CDH4_VERSION}.jar
              DESTINATION lib/java/cdh4)
