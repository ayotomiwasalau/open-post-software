kubectl create namespace sentry
helm uninstall --namespace sentry sentry -f ./values.yaml sentry/sentry --kubeconfig /etc/rancher/k3s/k3s.yaml