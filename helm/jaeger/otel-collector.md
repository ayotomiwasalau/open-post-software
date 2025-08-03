mode: "deployment"
config:
  exporters:
    # Export traces to Jaeger using the jaeger exporter
    jaeger:
      endpoint: jaeger-collector.observability.svc.cluster.local:14250
      tls:
        insecure: true
    # Optional: Keep console exporter for debugging
    logging:
      loglevel: debug
  extensions:
    health_check:
      endpoint: ${env:MY_POD_IP}:13133
  processors:
    # Define the batch processor
    batch:
      timeout: 1s
      send_batch_size: 1024
    # Optional: Add memory limiter
    memory_limiter:
      limit_mib: 128
  receivers:
    # Receive traces from applications via OTLP
    otlp:
      protocols:
        grpc:
          endpoint: ${env:MY_POD_IP}:4317
        http:
          endpoint: ${env:MY_POD_IP}:4318
    # Optional: Keep Jaeger receivers for legacy applications
    jaeger:
      protocols:
        grpc:
          endpoint: ${env:MY_POD_IP}:14250
        thrift_http:
          endpoint: ${env:MY_POD_IP}:14268
        thrift_compact:
          endpoint: ${env:MY_POD_IP}:6831
  service:
    extensions: [health_check, memory_limiter]
    pipelines:
      traces:
        receivers: [otlp, jaeger]
        processors: [memory_limiter, batch]
        exporters: [jaeger, logging]