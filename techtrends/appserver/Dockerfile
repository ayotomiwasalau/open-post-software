FROM python:3.8

COPY . /src

WORKDIR /src

# Dependencies required for psycopg2 (used for Postgres client)
RUN apt update -y && apt install -y build-essential libpq-dev

# Dependencies are installed during build time in the container itself so we don't have OS mismatch
RUN pip install -r requirements.txt

RUN opentelemetry-bootstrap -a install

ENV OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4317
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_SERVICE_NAME=rantzapp

EXPOSE 3111 

CMD ["opentelemetry-instrument", "python", "app.py"]

# CMD ["opentelemetry-instrument", "--traces_exporter", "console", "--metrics_exporter", "console", "--logs_exporter", "console", "--service_name", "rantzapp", "python", "app.py"]