## Download the `falcosecurity-packages.asc` file, which is a checksum for the drivers. 
rpm --import https://falco.org/repo/falcosecurity-packages.asc
## Curl the falco repo containing the drivers
curl -s -o /etc/zypp/repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo
## Install the drivers
## Hit "y" at this prompt to install all relevant packages. 
sudo zypper dist-upgrade

sudo zypper -n install dkms make
## Install the kernel headers
sudo zypper -n install kernel-default-devel
## Installs kernel-default-devel-5.14.21-150400.24.33.2.x86_64.rpm
sudo zypper -n install dialog

# Install falco driver

sudo zypper -n install falco
## Verify the installation
sudo systemctl status falco

sudo systemctl daemon-reload
sudo systemctl enable falco
sudo systemctl start falco



helm repo add falcosecurity https://falcosecurity.github.io/charts
## Update the Helm repo to get the latest charts
helm repo update
## Falco deployment
helm install --kubeconfig kube_config_cluster.yml falco falcosecurity/falco --namespace falco --create-namespace --set falco.grpc.enabled=true --set falco.grpc_output.enabled=true

kubectl  exec --stdin -it falco-wpnvg --namespace falco -- /bin/sh

helm install --kubeconfig /etc/rancher/k3s/k3s.yaml falco-exporter --namespace falco --set serviceMonitor.enabled=true falcosecurity/falco-exporter

kubectl port-forward service/falco-exporter --address 0.0.0.0 9376:9376 --namespace falco 
kubectl port-forward service/prometheus-kube-prometheus-prometheus --address 0.0.0.0 9090:9090 --namespace monitoring &

kubectl apply -f falco_service_monitor.yaml
kubectl edit --kubeconfig /etc/rancher/k3s/k3s.yaml prometheus -n monitoring