FROM openjdk:8u212-jre-alpine

ARG kafka_version=2.7.0
ARG scala_version=2.13
ARG glibc_version=2.31-r0
ARG filebeat_version=7.12.0
ARG metricbeat_version=7.12.0
ARG vcs_ref=unspecified
ARG build_date=unspecified

LABEL org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/wurstmeister/kafka-docker" \
      org.label-schema.vcs-ref="${vcs_ref}" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" \
      maintainer="wurstmeister"

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka \
    GLIBC_VERSION=$glibc_version \
    FILEBEAT_VERSION=$filebeat_version \
    METRICBEAT_VERSION=$metricbeat_version \
    FILEBEAT_HOME=/opt/filebeat \
    METRICBEAT_HOME=/opt/metricbeat

ENV PATH=${PATH}:${KAFKA_HOME}/bin

COPY download-kafka.sh start-kafka.sh broker-list.sh create-topics.sh versions.sh /tmp/

RUN apk add --no-cache bash curl jq docker \
 && chmod a+x /tmp/*.sh \
 && mv /tmp/start-kafka.sh /tmp/broker-list.sh /tmp/create-topics.sh /tmp/versions.sh /usr/bin \
 && sync && /tmp/download-kafka.sh \
 && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
 && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
 && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
 && apk add --no-cache --allow-untrusted glibc-${GLIBC_VERSION}.apk \
 && rm glibc-${GLIBC_VERSION}.apk \
 && wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz -O  /tmp/filebeat.tar.gz  \
 && tar xfz /tmp/filebeat.tar.gz -C /opt \
 && ln -s /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64 ${FILEBEAT_HOME} \
 && wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${METRICBEAT_VERSION}-linux-x86_64.tar.gz -O /tmp/metricbeat.tar.gz \
 && tar xfz /tmp/metricbeat.tar.gz -C /opt \
 && ln -s /opt/metricbeat-${METRICBEAT_VERSION}-linux-x86_64 ${METRICBEAT_HOME} \
 && rm /tmp/*


COPY overrides /opt/overrides

VOLUME ["/kafka"]

# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafka.sh"]
