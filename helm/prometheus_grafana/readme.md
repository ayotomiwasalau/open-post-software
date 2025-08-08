kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --kubeconfig /etc/rancher/k3s/k3s.yaml
kubectl port-forward service/prometheus-grafana --address 0.0.0.0 3001:80 --namespace monitoring &
kubectl port-forward service/prometheus-kube-prometheus-prometheus --address 0.0.0.0 9090:9090 --namespace monitoring &

