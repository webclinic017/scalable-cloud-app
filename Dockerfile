# syntax=docker/dockerfile:1
FROM python:latest
RUN mkdir /app
COPY . /app
WORKDIR /app
LABEL Maintainer="gg18045.scalable-cloud-app"
RUN /usr/local/bin/python -m pip install --upgrade pip
RUN pip install -r requirements.txt
CMD [ "sh", "./start_ec2_autoscaling.sh"]
CMD [ "python", "./start_cluster.py"]
CMD ["lsmod | grep br_netfilter"]


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: default-token
  annotations:
    kubernetes.io/service-account.name: default
type: kubernetes.io/service-account-token
EOF

kubectl describe secret default-token | grep -E '^token' | cut -f2 -d':' | tr -d " "