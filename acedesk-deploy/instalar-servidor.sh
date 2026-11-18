#!/usr/bin/env bash
# ACE Desk — instala tudo numa VM Ubuntu da Oracle Cloud.
# Uso (dentro da VM):  bash instalar-servidor.sh desk.aaccessbr.com
set -euo pipefail
DOMINIO="${1:?Informe o domínio. Ex: bash instalar-servidor.sh desk.aaccessbr.com}"
cd "$(dirname "$0")"

echo "==> 1/5 Instalando Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
fi

echo "==> 2/5 Liberando as portas no firewall da VM"
for p in 80 443 21115 21116 21117; do
  sudo iptables -C INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null || sudo iptables -I INPUT 5 -p tcp --dport $p -j ACCEPT
done
sudo iptables -C INPUT -p udp --dport 21116 -j ACCEPT 2>/dev/null || sudo iptables -I INPUT 5 -p udp --dport 21116 -j ACCEPT
sudo apt-get install -y iptables-persistent >/dev/null 2>&1 || true
sudo netfilter-persistent save || true

echo "==> 3/5 Criando a configuração"
if [ ! -f .env ]; then
  SENHA=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
  printf 'DOMINIO=%s\nADMIN_USUARIO=ace\nADMIN_SENHA=%s\n' "$DOMINIO" "$SENHA" > .env
fi

echo "==> 4/5 Montando e ligando o ACE Desk (demora uns minutos na 1ª vez)"
sudo docker compose up -d --build

echo "==> 5/5 Pronto"
. ./.env
echo
echo "Console:  https://$DOMINIO"
echo "Usuário:  $ADMIN_USUARIO"
echo "Senha:    $ADMIN_SENHA   (troque depois de entrar)"
echo
echo "Chave do servidor (vai nos PCs):"
sleep 15
sudo docker exec acedesk cat /data/rustdesk/id_ed25519.pub || echo "(ainda gerando — rode de novo: sudo docker exec acedesk cat /data/rustdesk/id_ed25519.pub)"
