#!/usr/bin/env bash

VERSION=0.1.3

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

wget -O shadowsocks2-linux.gz https://github.com/shadowsocks/go-shadowsocks2/releases/download/v${VERSION}/shadowsocks2-linux.gz
gzip -d shadowsocks2-linux.gz
sudo chmod +x shadowsocks2-linux
sudo mv shadowsocks2-linux /usr/local/bin/go-shadowsocks2


# sudo -i 
install_systemd_unit() {
  sudo wget -O /etc/systemd/system/go-shadowsocks2.service https://github.com/dfang/go-shadowsocks2/raw/develop/examples/systemd.example
  sudo systemctl daemon-reload  && \
  sudo systemctl enable go-shadowsocks2  && \
  sudo systemctl restart go-shadowsocks2  && \
  sudo systemctl status --no-pager --full go-shadowsocks2 | grep -A 2 "go-shadowsocks2.service" 
}

run_server_like_this() {
  echo go-shadowsocks2 -s 'ss://AEAD_CHACHA20_POLY1305:pa$$w0rd@:80' -verbose
}

while true; do
    read -p "Do you wish to install systemd service unit?" yn
    case $yn in
        [Yy]* ) install_systemd_unit; break;;
        [Nn]* ) echo "you can run server like this: "; run_server_like_this; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

IP=$(curl https://api.ipify.org/)

echo
echo "if you want to customize port and encryption method, you can edit /etc/systemd/system/go-shadowsocks2.service"
echo "don't forget to restart service after edit !!!!!!"
echo
echo "how to tail logs ? "
echo "journalctl -f -u go-shadowsocks2"
echo 
echo "go-shadowsocks2 project url:  https://github.com/shadowsocks/go-shadowsocks2"
echo
echo "you can run client like this: "
echo
echo go-shadowsocks2 -c "ss://AEAD_CHACHA20_POLY1305:passw0rd@${IP}:80" \
    -verbose -socks :1080
echo
echo
