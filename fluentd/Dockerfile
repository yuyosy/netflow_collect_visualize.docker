FROM fluent/fluentd:v1.14-1
EXPOSE 5140
USER root
RUN fluent-gem install fluent-plugin-netflow
RUN fluent-gem install fluent-plugin-influxdb-v2
COPY ./fluentd.conf /fluentd/etc/fluent.conf
