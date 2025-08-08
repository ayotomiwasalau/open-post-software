helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update
kubectl create ns observability
helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace observability \
    --create-namespace \
    --values jaeger-values.yaml \
    --kubeconfig /etc/rancher/k3s/k3s.yaml
    --history-max 2 \

helm upgrade --install jaeger jaegertracing/jaeger  -n observability   --set storage.type=memory  --set provisionDataStore.cassandra=false --kubeconfig /etc/rancher/k3s/k3s.yaml
helm upgrade --uninstall jaeger jaegertracing/jaeger  -n observability   --kubeconfig /etc/rancher/k3s/k3s.yaml


helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install otel-collector open-telemetry/opentelemetry-collector \
    --namespace observability \
    --values otel-collector.yaml \
    --set image.repository="otel/opentelemetry-collector-k8s"\
    --kubeconfig /etc/rancher/k3s/k3s.yaml

helm upgrade otel-collector open-telemetry/opentelemetry-collector \
    --namespace observability \
    --values otel-collector.yaml \
    --set image.repository="otel/opentelemetry-collector-k8s" \
    --kubeconfig /etc/rancher/k3s/k3s.yaml

kubectl port-forward svc/otel-collector-opentelemetry-collector  --address 0.0.0.0 4317:4317 -n observability --kubeconfig /etc/rancher/k3s/k3s.yaml &

kubectl port-forward svc/otel-collector-opentelemetry-collector  --address 0.0.0.0 4318:4318 -n observability --kubeconfig /etc/rancher/k3s/k3s.yaml &

kubectl port-forward svc/jaeger-query --address 0.0.0.0 16686:16686 -n observability --kubeconfig /etc/rancher/k3s/k3s.yaml &

pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install

opentelemetry-instrument \ 
    --traces_exporter console \
    --metrics_exporter console \
    --logs_exporter console \
    --service_name rantzapp \
    flask run -p 3111