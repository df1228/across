#!/usr/bin/env bash

GO_VERSION=1.15

[[ $# == 1 ]] && domain="$1" || { echo Err !!! Useage: bash this_script.sh my.domain.com; exit 1; }

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

if command_exists yum; then
    sudo yum update -y && sudo yum install -y curl wget git
elif command_exists apt-get; then
    sudo apt-get update -y && sudo apt-get install -y curl wget git
else
    echo "Error: this installer scripts only supports yum or apt based system"
    exit 1
fi

# ------------ Install go ------------------
#
#
wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo export PATH=/usr/local/go/bin:$PATH >> ~/.bash_profile
source ~/.bash_profile

# ------------ Build caddy with forked forwardproxy plugin ------------------
#
#              https://github.com/caddyserver/xcaddy
#
# 如果不ln,ubuntu 20.04 会报错 go binary not in PATH
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
sudo ln -sf /usr/local/go/bin/go /usr/bin/go
# sudo cp -f /usr/local/go/bin/go /usr/local/bin/go
go get -u -v github.com/caddyserver/xcaddy/cmd/xcaddy
sudo ~/go/bin/xcaddy build --output /usr/bin/caddy --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
sudo setcap cap_net_bind_service=+ep /usr/bin/caddy
sudo chmod +x /usr/bin/caddy

# ------------ Install systemd unit ------------------
#
#             https://caddyserver.com/docs/install
#
sudo mv caddy /usr/bin/
sudo groupadd --system caddy
sudo useradd --system \
    --gid caddy \
    --create-home \
    --home-dir /var/lib/caddy \
    --shell /usr/sbin/nologin \
    --comment "Caddy web server" \
    caddy
sudo wget -O /etc/systemd/system/caddy.service https://raw.githubusercontent.com/caddyserver/dist/master/init/caddy.service


# Caddyfile
sudo mkdir -p /usr/share/caddy
sudo mkdir -p /etc/caddy
echo "Hello, 世界!" | sudo tee /usr/share/caddy/index.html
echo

username="$(tr -dc 'a-z0-9A-Z' </dev/urandom | head -c 16)"
password="$(tr -dc 'a-z0-9A-Z' </dev/urandom | head -c 16)"

# config caddy json
cat <<EOF | sudo tee /etc/caddy/Caddyfile
:443, $domain
route {
  forward_proxy {
    basic_auth $username $password
    hide_ip
    hide_via
    probe_resistance
  }
  file_server { root /usr/share/caddy }
}
EOF

sudo systemctl daemon-reload  && \
sudo systemctl enable caddy  && \
sudo systemctl restart caddy  && \
sudo systemctl status --no-pager --full caddy | grep -A 2 "caddy.service" 

# journalctl -f -u caddy

echo; 
echo $(date); 
echo username: $username; 
echo password: $password;  
echo proxy: https://$username:$password@$domain
echo
echo
echo "Project URL: https://github.com/klzgrad/naiveproxy"
echo
echo you may want to config your clientlike this:
echo
cat <<-EOF
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://$username:$password@$domain"
}
EOF
echo
echo
