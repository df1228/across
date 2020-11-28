# ------------ Install go ------------------
#
#
sudo apt-get install -y curl wget
wget https://dl.google.com/go/go1.15.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.15.linux-amd64.tar.gz
echo export PATH=/usr/local/go/bin:$PATH >> ~/.bash_profile
source ~/.bash_profile

# ------------ Build caddy with forked forwardproxy plugin ------------------
#
#              https://github.com/caddyserver/xcaddy
#
go get -u -v github.com/caddyserver/xcaddy/cmd/xcaddy
# 如果不ln,ubuntu 20.04 会报错 go binary not in PATH
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
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

wget -O /etc/systemd/system/caddy.service https://github.com/caddyserver/dist/blob/master/init/caddy.service

sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy
