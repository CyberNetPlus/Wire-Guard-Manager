#!/bin/bash
#───────────────────────────────────────────────
# WireGuard Manager v2.5 — Full English Menu
# Author: Cyber Net Plus (Babak Khedri) 
# YouTube: https://www.youtube.com/@Cyber_Net_Plus
#───────────────────────────────────────────────

CONFIG_DIR="/etc/wireguard"
CONFIG_FILE="$CONFIG_DIR/wg0.conf"
DEFAULT_PORT=51820

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗"
    echo -e "║                WireGuard Manager                  ║"
    echo -e "╚════════════════════════════════════════════════════╝${RESET}"
    echo -e "1) Install WireGuard"
    echo -e "2) Generate new configuration"
    echo -e "3) Show WireGuard status"
    echo -e "4) Show full configuration"
    echo -e "5) Enable and start WireGuard"
    echo -e "6) Delete all configurations and keys"
    echo -e "7) Show Server A & B keys and ports"
    echo -e "0) Exit"
    echo -ne "\nSelect an option: "
}

install_wireguard() {
    echo -e "${YELLOW}Installing WireGuard...${RESET}"
    sudo apt update -y && sudo apt install -y wireguard
    echo -e "${GREEN}✅ WireGuard installed successfully.${RESET}"
    read -p "Press Enter to continue..."
}

generate_config() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗"
    echo -e "║             Generate WireGuard Configuration              ║"
    echo -e "║       Author: Cyber Net Plus (Babak Khedri)               ║"
    echo -e "║    YouTube: https://www.youtube.com/@Cyber_Net_Plus       ║"
    echo -e "╚════════════════════════════════════════════════════╝${RESET}"

    cd "$CONFIG_DIR" || exit 1

    echo -e "${YELLOW}Generating keys...${RESET}"
    wg genkey | tee privatekey | wg pubkey > publickey

    PRIVATE_KEY=$(cat privatekey)
    read -p "Enter MikroTik PublicKey: " PUBLIC_KEY_server_B
    read -p "Enter MikroTik Endpoint IP: " server-b-Endpoint
    read -p "Enter MikroTik Port (e.g., 51820): " server_PORT
    read -p "Enter Server A Address (e.g., 10.100.100.2/24): " SERVER_A_IP
    read -p "Enter Server A Listening Port (or press Enter for default $DEFAULT_PORT): " SERVER_A_PORT
    SERVER_A_PORT=${SERVER_A_PORT:-$DEFAULT_PORT}
    read -p "Enter Server B Address (e.g., 10.100.100.3/24): " SERVER_B_IP

    echo -e "${YELLOW}Creating configuration file...${RESET}"
    cat > "$CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $SERVER_A_IP
ListenPort = $SERVER_A_PORT
#DNS = 8.8.8.8

[Peer]
PublicKey = $PUBLIC_KEY_server_B
Endpoint = $server-b-Endpoint:$serverB_PORT
AllowedIPs = $SERVER_B_IP
PersistentKeepalive = 25
EOF

    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✅ Configuration saved at:${RESET} $CONFIG_FILE"
    read -p "Press Enter to continue..."
}

show_status() {
    echo -e "${CYAN}WireGuard Status:${RESET}"
    sudo wg show
    read -p "Press Enter to continue..."
}

show_full_config() {
    echo -e "${CYAN}Full WireGuard Configuration:${RESET}"
    echo -e "-----------------------------------------"
    cat "$CONFIG_FILE"
    echo -e "-----------------------------------------"
    read -p "Press Enter to continue..."
}

enable_service() {
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0
    echo -e "${GREEN}✅ WireGuard service started and enabled.${RESET}"
    read -p "Press Enter to continue..."
}

delete_all() {
    read -p "Are you sure you want to delete all configs and keys? [y/N]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sudo systemctl stop wg-quick@wg0
        sudo rm -f "$CONFIG_FILE" "$CONFIG_DIR/privatekey" "$CONFIG_DIR/publickey"
        echo -e "${RED}⚠ All WireGuard configurations and keys deleted.${RESET}"
    else
        echo -e "${YELLOW}❌ Operation cancelled.${RESET}"
    fi
    read -p "Press Enter to continue..."
}

show_keys_and_ports() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗"
    echo -e "║           WireGuard Server A & B Info             ║"
    echo -e "╚════════════════════════════════════════════════════╝${RESET}"

    if [[ -f "$CONFIG_DIR/privatekey" && -f "$CONFIG_DIR/publickey" ]]; then
        PRIVATE_KEY=$(cat "$CONFIG_DIR/privatekey")
        PUBLIC_KEY=$(cat "$CONFIG_DIR/publickey")

        # ListenPort را بخوان و اگر خالی بود، مقدار پیش‌فرض بده
        LISTEN_PORT=$(grep -E '^[[:space:]]*ListenPort[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        if [[ -z "$LISTEN_PORT" ]]; then
            LISTEN_PORT=$DEFAULT_PORT
            echo "ListenPort=$LISTEN_PORT" | sudo tee -a "$CONFIG_FILE" >/dev/null
        fi

        ENDPOINT=$(grep -E '^[[:space:]]*Endpoint[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        ALLOWED_IPS=$(grep -E '^[[:space:]]*AllowedIPs[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')

        echo -e "${YELLOW}Private Key (Server A):${RESET} $PRIVATE_KEY"
        echo -e "${YELLOW}Public Key (Server A):${RESET} $PUBLIC_KEY"
        echo -e "${YELLOW}Listening Port (Server A):${RESET} $LISTEN_PORT"
        echo -e "${YELLOW}Server B Endpoint:${RESET} $ENDPOINT"
        echo -e "${YELLOW}Server B AllowedIPs:${RESET} $ALLOWED_IPS"
    else
        echo -e "${RED}⚠ Keys not found. Generate configuration first.${RESET}"
    fi

    read -p "Press Enter to continue..."
}

while true; do
    show_menu
    read choice
    case $choice in
        1) install_wireguard ;;
        2) generate_config ;;
        3) show_status ;;
        4) show_full_config ;;
        5) enable_service ;;
        6) delete_all ;;
        7) show_keys_and_ports ;;
        0) echo -e "${YELLOW}Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
    esac
done

