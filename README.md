# NetFlow Collect&Visualize
NetFlow Collect&Visualize (Grafana,InfluxDB,fluentd)


``` mermaid
flowchart LR

  NW((Network))
  user(User)

  subgraph Expose Ports
    port5140[5140]
    port8086[8086]
    port3000[3000]
  end

  subgraph Docker Internal-Network
    fluentd[fluentd]
    influxdb[InfluxDB]
    grafana[Grafana]
  end

  NW -- NetFlow --> port5140
  user -- Web Application --> port3000
  user -- Web Application --> port8086
  port5140 .- fluentd
  port8086 .- influxdb
  port3000 .- grafana
  fluentd == Data Store #Write ==> influxdb
  grafana == Data Source #Read ==> influxdb
```

## Attributes

### Softwares
- [Grafana](https://grafana.com)
- [fluentd](https://www.fluentd.org)
- [InfluxDB](https://www.influxdata.com)
  - [fluent-plugin-influxdb](https://github.com/fangli/fluent-plugin-influxdb)
  - [fluent-plugin-netflow](https://github.com/repeatedly/fluent-plugin-netflow)

### Base Docker Images
- [fluentd](https://hub.docker.com/r/fluent/fluentd/)
- [grafana](https://hub.docker.com/r/grafana/grafana/)
- [influxdb](https://hub.docker.com/_/influxdb/)


## Notes
**The passwords contained in this repository are weak and not cryptographically secure.**


## License
MIT License Copyright (c) 2022 yuyosy