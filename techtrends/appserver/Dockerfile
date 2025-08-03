FROM python:3.8

COPY . /src

WORKDIR /src

# Dependencies required for psycopg2 (used for Postgres client)
RUN apt update -y && apt install -y build-essential libpq-dev

# Dependencies are installed during build time in the container itself so we don't have OS mismatch
RUN pip install -r requirements.txt

# Environment variables for manual OpenTelemetry instrumentation
ENV OTEL_SERVICE_NAME=rantzapp
ENV OTEL_SERVICE_VERSION=1.0.0
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=rantzapp,service.version=1.0.0
# ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4317

EXPOSE 3111 

# Use standard Python command for manual instrumentation
CMD ["python", "app.py"]