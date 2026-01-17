# Monitoring Visual Guide (Linux Stack)

This guide summarizes the UI endpoints and the key visual checks for Grafana, Prometheus, and Kafka (via exporter metrics) after the Linux-based Docker Compose changes.

## Grafana

**URL:** `http://localhost:13030`

**What to verify visually**
- **Login screen** appears with the configured admin credentials.
- **Dashboards list** loads after login.
- **Data source connectivity**: add Prometheus as a data source with URL `http://linux-prometheus:9090` and verify the “Save & Test” status.

## Prometheus

**URL:** `http://localhost:19090`

**What to verify visually**
- **Status → Targets** shows `linux-prometheus` itself as **UP**.
- **Graph** page can render a simple query (e.g., `up`) and show time-series output.

## Kafka (via Exporter + Prometheus)

Kafka does not ship with a standalone UI in this stack. Use the exporter metrics in Prometheus and Grafana to visually confirm Kafka activity.

**Exporter metrics endpoint (raw):** `http://localhost:19308/metrics`

**Visual checks**
- **Prometheus → Status → Targets** shows `linux-kafka-exporter` as **UP**.
- **Prometheus → Graph** queries Kafka metrics (examples):
  - `kafka_brokers`
  - `kafka_topic_partitions`
- **Grafana dashboards** (after adding Prometheus data source) can graph the Kafka exporter metrics above for a visual confirmation.

## Port Summary (Host → Container)

| Service | Host Port | Container Port |
| --- | --- | --- |
| Grafana | 13030 | 3000 |
| Prometheus | 19090 | 9090 |
| Kafka Broker | 29092 | 9092 |
| Zookeeper | 22181 | 2181 |
| Kafka Exporter | 19308 | 9308 |
