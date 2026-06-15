{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{- define "alluxio.log4j2" -}}
<?xml version="1.0" encoding="UTF-8"?>
<!--

    The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
    (the "License"). You may not use this work except in compliance with the License, which is
    available at www.apache.org/licenses/LICENSE-2.0

    This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied, as more fully set forth in the License.

    See the NOTICE file distributed with this work for information regarding copyright ownership.

-->
<Configuration status="WARN" monitorInterval="30">
    <Properties>
        <Property name="additional.logger.type">${sys:alluxio.additional.logger.type:-}</Property>
        <Property name="logger.type">${sys:alluxio.logger.type:-}</Property>
        <Property name="logs.dir">${sys:alluxio.logs.dir:-/opt/alluxio/logs}</Property>
        <Property name="user.logs.dir">${sys:alluxio.user.logs.dir:-${logs.dir}/user}</Property>
        <Property name="audit.logs.dir">${sys:alluxio.audit.logs.dir:-${logs.dir}/audit}</Property>
        <Property name="access.logs.dir">${sys:alluxio.access.logs.dir:-${logs.dir}/access}</Property>
        <Property name="username">${sys:user.name:-unknown}</Property>
    </Properties>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="${logger.type}"/>
            <AppenderRef ref="${additional.logger.type}"/>
        </Root>
        <!-- Logger for parquet writer -->
        <Logger name="org.apache.parquet.hadoop.InternalParquetRecordWriter" level="warn"/>

        <!-- Logger for parquet reader -->
        <Logger name="org.apache.parquet.hadoop.InternalParquetRecordReader" level="warn"/>

        <!-- Disable noisy DEBUG logs -->
        <!-- Logger for AWS instance metadata -->
        <Logger name="com.amazonaws.internal.InstanceMetadataServiceResourceFetcher" level="off"/>

        <!-- Logger for AWS EC2 metadata utils -->
        <Logger name="com.amazonaws.util.EC2MetadataUtils" level="off"/>

        <!-- Logger for gRPC Netty server handler -->
        <Logger name="io.grpc.netty.NettyServerHandler" level="off"/>

        <!-- Disable noisy INFO logs from ratis -->
        <Logger name="org.apache.ratis.grpc.server.GrpcLogAppender" level="error"/>
        <Logger name="org.apache.ratis.grpc.server.GrpcServerProtocolService" level="warn"/>
        <Logger name="org.apache.ratis.server.impl.FollowerInfo" level="warn"/>
        <Logger name="org.apache.ratis.server.leader.FollowerInfo" level="warn"/>
        <Logger name="org.apache.ratis.server.impl.RaftServerImpl" level="warn"/>
        <Logger name="org.apache.ratis.server.RaftServer$Division" level="warn"/>

        <!-- Logger for Alluxio Security -->
        <Logger name="alluxio.security" level="info"/>

        <!-- Logger for Worker Access log -->
        <Logger name="alluxio.access.worker" level="info" additivity="false">
            <AppenderRef ref="WORKER_ACCESS_LOG"/>
        </Logger>

        <!-- Logger for HADOOP_FS Audit Log -->
        <Logger name="alluxio.audit.hadoop.fs" level="info" additivity="false">
            <AppenderRef ref="HADOOP_FS_AUDIT_LOG"/>
        </Logger>

        <!-- Logger for Fuse Audit Log -->
        <Logger name="alluxio.audit.fuse" level="info" additivity="false">
            <AppenderRef ref="FUSE_AUDIT_LOG"/>
        </Logger>

        <!-- Logger for REST Audit Log -->
        <Logger name="alluxio.audit.rest" level="info" additivity="false">
            <AppenderRef ref="REST_AUDIT_LOG"/>
        </Logger>

        <!-- Logger for S3 Audit Log -->
        <Logger name="alluxio.audit.s3" level="info" additivity="false">
            <AppenderRef ref="S3_AUDIT_LOG"/>
        </Logger>

        <!-- Logger for UFS Error Log -->
        <Logger name="alluxio.underfs.s3a.AlluxioS3V2Exception" level="info" additivity="false">
            <AppenderRef ref="UFS_ERROR_LOGGER"/>
        </Logger>
        <Logger name="alluxio.underfs.bos.AlluxioBOSException" level="info" additivity="false">
            <AppenderRef ref="UFS_ERROR_LOGGER"/>
        </Logger>

        <!-- Logger for Async persist -->
        <Logger name="alluxio.worker.writebuffer.persist" level="info" additivity="false">
            <AppenderRef ref="ASYNC_PERSIST_LOGGER"/>
        </Logger>

        {{- range $logger, $level := .Values.loggers }}
        <Logger name="{{ $logger }}" level="{{ $level }}"/>
        {{- end }}
    </Loggers>
    <Appenders>
        <!-- Configures an appender whose name is "" (empty string) to be NullAppender.
             By default, if a Java class does not specify a particular appender, log4j will
             use "" as the appender name, then it will use Null appender. -->
        <Null name=""/>

        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
        </Console>

        <!-- Appender for Coordinator -->
        <RollingFile name="COORDINATOR_LOGGER" fileName="${logs.dir}/coordinator.log" filePattern="${logs.dir}/coordinator-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="50MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="coordinator-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="20" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Worker -->
        <RollingFile name="WORKER_LOGGER" fileName="${logs.dir}/worker.log" filePattern="${logs.dir}/worker-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="50MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="worker-[0-9]*.log.gz" />
                    <IfAccumulatedFileCount exceeds="20" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Security server -->
        <RollingFile name="SECURITY_SERVER_LOGGER" fileName="${logs.dir}/security_server.log" filePattern="${logs.dir}/security_server-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="10MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="security_server-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="100" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for User -->
        <RollingFile name="USER_LOGGER" fileName="${user.logs.dir}/user_${username}.log" filePattern="${user.logs.dir}/user_${username}-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="10MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${user.logs.dir}" maxDepth="1">
                    <IfFileName glob="user_*-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="100" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Fuse -->
        <RollingFile name="FUSE_LOGGER" fileName="${logs.dir}/${env:HOSTNAME}/fuse.log" filePattern="${logs.dir}/${env:HOSTNAME}/fuse-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} [${env:FUSE_IDENTIFIER}] %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}/${env:HOSTNAME}/" maxDepth="1">
                    <IfFileName glob="fuse-[0-9]*.log.gz" />
                    <IfAccumulatedFileCount exceeds="10" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for UCP Server -->
        <RollingFile name="UCPSERVER_LOGGER" fileName="${logs.dir}/ucpserver.log" filePattern="${logs.dir}/ucpserver-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p [%t](%F:%L) - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="10MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="ucpserver-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="100" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for UCP Client -->
        <RollingFile name="UCPCLIENTTEST_LOGGER" fileName="${logs.dir}/ucpclienttest.log" filePattern="${logs.dir}/ucpclienttest-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p [%t](%F:%L) - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="10MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="ucpclienttest-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="100" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Worker Access Log -->
        <RollingFile name="WORKER_ACCESS_LOG" fileName="${access.logs.dir}/worker-access.log"
                     filePattern="${access.logs.dir}/worker-access-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout>
                <Pattern>%m%n</Pattern>
            </PatternLayout>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy fileIndex="nomax">
                <Delete basePath="${access.logs.dir}" maxDepth="1">
                    <IfFileName glob="worker-access-*.log.gz" />
                    <IfAny>
                        <!-- Delete if older than 7 days OR total size exceeds 10GB -->
                        <IfLastModified age="7d" />
                        <IfAccumulatedFileSize exceeds="10GB" />
                    </IfAny>
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Hadoop FS Audit Log -->
        <RollingFile name="HADOOP_FS_AUDIT_LOG" fileName="${audit.logs.dir}/hadoop-fs-audit.log"
                     filePattern="${audit.logs.dir}/hadoop-fs-audit-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout>
                <Pattern>%m%n</Pattern>
            </PatternLayout>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy fileIndex="nomax">
                <Delete basePath="${audit.logs.dir}" maxDepth="1">
                    <IfFileName glob="hadoop-fs-audit-*.log.gz" />
                    <IfAny>
                        <!-- Delete if older than 7 days OR total size exceeds 10GB -->
                        <IfLastModified age="7d" />
                        <IfAccumulatedFileSize exceeds="10GB" />
                    </IfAny>
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Fuse Audit Log -->
        <RollingFile name="FUSE_AUDIT_LOG" fileName="${logs.dir}/${env:HOSTNAME}/audit/fuse-audit.log"
                     filePattern="${logs.dir}/${env:HOSTNAME}/audit/fuse-audit-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout>
                <Pattern>%m%n</Pattern>
            </PatternLayout>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy fileIndex="nomax">
                <Delete basePath="${logs.dir}/${env:HOSTNAME}/audit/" maxDepth="1">
                    <IfFileName glob="fuse-audit-*.log.gz" />
                    <IfAny>
                        <!-- Delete if older than 7 days OR total size exceeds 10GB -->
                        <IfLastModified age="7d" />
                        <IfAccumulatedFileSize exceeds="10GB" />
                    </IfAny>
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for REST Audit Log -->
        <RollingFile name="REST_AUDIT_LOG" fileName="${audit.logs.dir}/rest-audit.log"
                     filePattern="${audit.logs.dir}/rest-audit-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout>
                <Pattern>%m%n</Pattern>
            </PatternLayout>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy fileIndex="nomax">
                <Delete basePath="${audit.logs.dir}" maxDepth="1">
                    <IfFileName glob="rest-audit-*.log.gz" />
                    <IfAny>
                        <!-- Delete if older than 7 days OR total size exceeds 10GB -->
                        <IfLastModified age="7d" />
                        <IfAccumulatedFileSize exceeds="10GB" />
                    </IfAny>
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Northbound S3 Audit Log -->
        <RollingFile name="S3_AUDIT_LOG" fileName="${audit.logs.dir}/s3-audit.log"
                     filePattern="${audit.logs.dir}/s3-audit-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout>
                <Pattern>%m%n</Pattern>
            </PatternLayout>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy fileIndex="nomax">
                <Delete basePath="${audit.logs.dir}" maxDepth="1">
                    <IfFileName glob="s3-audit-*.log.gz" />
                    <IfAny>
                        <!-- Delete if older than 7 days OR total size exceeds 10GB -->
                        <IfLastModified age="7d" />
                        <IfAccumulatedFileSize exceeds="10GB" />
                    </IfAny>
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for UFS -->
        <RollingFile name="UFS_ERROR_LOGGER" fileName="${logs.dir}/ufs-error.log" filePattern="${logs.dir}/ufs-error-%d{yyyy-MM-dd}-%i.log.gz" createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} [PID:%pid] %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="100MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="ufs-error-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="20" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>

        <!-- Appender for Async Persist Logger -->
        <RollingFile name="ASYNC_PERSIST_LOGGER"
                     fileName="${logs.dir}/async_persist.log"
                     filePattern="${logs.dir}/async_persist-%d{yyyy-MM-dd}-%i.log.gz"
                     createOnDemand="true">
            <PatternLayout pattern="%d{ISO8601} %-5p %c{1} - %m%n"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="10MB"/>
            </Policies>
            <!-- Set max to a large value to rely on Delete policy -->
            <DefaultRolloverStrategy max="10000">
                <Delete basePath="${logs.dir}" maxDepth="1">
                    <IfFileName glob="async_persist-*.log.gz" />
                    <IfAccumulatedFileCount exceeds="100" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>
    </Appenders>
</Configuration>
{{- end }}
