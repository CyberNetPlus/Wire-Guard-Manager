#!/bin/bash
# ────────────────────────────────────────────────
# WireGuard 
# Author: Cyber Net Plus (Babak Khedri)
# YouTube: https://www.youtube.com/@Cyber_Net_Plus
# ────────────────────────────────────────────────

# Colors and Formatting (Minimalist Palette)
RST='\033[0m'       # Reset
RED='\033[0;31m'    # Red for errors/inactive
GRN='\033[0;32m'    # Green for success/active
YLW='\033[1;33m'    # Yellow for prompts/warnings
BLU='\033[0;34m'    # Blue for menu structure
CYN='\033[0;36m'    # Cyan for headers
WHT='\033[1;37m'    # Bold White for important text
BRED='\033[1;31m'   # Bold Red
BGRN='\033[1;32m'   # Bold Green
BCYN='\033[1;36m'   # Bold Cyan

# Configuration Variables
CONFIG_DIR="/etc/wireguard"
CONFIG_FILE="$CONFIG_DIR/wg0.conf"
DEFAULT_PORT=51820

# ------------------------------------------------
# Utility Functions
# ------------------------------------------------

# Function to read input without color issues
read_input() {
    local prompt="$1"
    local var_name="$2"
    read -rp "$prompt" "$var_name"
}

# Function to display menu (Minimalist)
show_menu() {
    clear
    
    # Header
    echo -e "${BCYN}======================================================${RST}"
    echo -e "${WHT}WIREGUARD ${RST}"
    echo -e "${CYN}A Project by Cyber Net Plus${RST}"
    echo -e "${CYN}YouTube: https://www.youtube.com/@Cyber_Net_Plus${RST}"
    echo -e "${BCYN}======================================================${RST}"
    echo

    # Menu
    echo -e "${WHT}Select an option:${RST}"
    echo -e "${BLU}------------------------------------------------------${RST}"
    
    # Options
    echo -e " ${YLW}1)${RST} Install WireGuard"
    echo -e " ${YLW}2)${RST} Generate new configuration"
    echo -e " ${YLW}3)${RST} Show WireGuard status"
    echo -e " ${YLW}4)${RST} Show full configuration"
    echo -e " ${YLW}5)${RST} Enable and start WireGuard"
    echo -e " ${YLW}6)${RST} Delete all configurations and keys"
    echo -e " ${YLW}7)${RST} Show Server A & B keys and ports"
    echo -e " ${YLW}8)${RST} Edit current configuration"
    echo -e "${BLU}------------------------------------------------------${RST}"
    echo -e " ${BRED}0)${RST} Exit"
    echo -e "${BLU}------------------------------------------------------${RST}"
    echo
}

install_wireguard() {
    echo -e "${CYN}--- 1) Install WireGuard ---${RST}"
    echo -e "${YLW}Installing WireGuard...${RST}"
    sudo apt update -y && sudo apt install -y wireguard
    echo -e "${BGRN}✅ WireGuard installed successfully.${RST}"
    read_input "Press Enter to continue..." DUMMY
}

generate_config() {
    echo -e "${CYN}--- 2) Generate New Configuration ---${RST}"

    cd "$CONFIG_DIR" 2>/dev/null || { echo -e "${BRED}Error: Configuration directory $CONFIG_DIR not found.${RST}"; read_input "Press Enter to continue..." DUMMY; return; }

    echo -e "${YLW}Generating keys...${RST}"
    wg genkey | tee privatekey | wg pubkey > publickey

    PRIVATE_KEY=$(cat privatekey)
    
    read_input "Enter MikroTik PublicKey: " PUBLIC_KEY_server_B
    read_input "Enter MikroTik Endpoint IP: " server_b_Endpoint
    read_input "Enter MikroTik Port (e.g., 51820): " serverB_PORT
    read_input "Enter Server A Address (e.g., 10.100.100.2/24): " SERVER_A_IP
    read_input "Enter Server A Listening Port (or press Enter for default $DEFAULT_PORT): " SERVER_A_PORT
    SERVER_A_PORT=${SERVER_A_PORT:-$DEFAULT_PORT}
    read_input "Enter Server B Address (e.g., 10.100.100.3/24): " SERVER_B_IP

    echo -e "${YLW}Creating configuration file...${RST}"
    cat > "$CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $SERVER_A_IP
ListenPort = $SERVER_A_PORT
#DNS = 8.8.8.8

[Peer]
PublicKey = $PUBLIC_KEY_server_B
Endpoint = $server_b_Endpoint:$serverB_PORT
AllowedIPs = $SERVER_B_IP
PersistentKeepalive = 25
EOF

    chmod 600 "$CONFIG_FILE"
    echo -e "${BGRN}✅ Configuration saved at: ${WHT}$CONFIG_FILE${RST}"
    read_input "Press Enter to continue..." DUMMY
}

show_status() {
    echo -e "${CYN}--- 3) WireGuard Status ---${RST}"
    if [[ -f "$CONFIG_FILE" ]]; then
        sudo wg show
    else
        echo -e "${BRED}⚠ Configuration file not found. Please generate it first.${RST}"
    fi
    read_input "Press Enter to continue..." DUMMY
}

show_full_config() {
    echo -e "${CYN}--- 4) Full Configuration ---${RST}"
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${BLU}----------------------------------------${RST}"
        cat "$CONFIG_FILE"
        echo -e "${BLU}----------------------------------------${RST}"
    else
        echo -e "${BRED}⚠ Configuration file not found. Please generate it first.${RST}"
    fi
    read_input "Press Enter to continue..." DUMMY
}

enable_service() {
    echo -e "${CYN}--- 5) Enable and Start Service ---${RST}"
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0
    echo -e "${BGRN}✅ WireGuard service started and enabled.${RST}"
    read_input "Press Enter to continue..." DUMMY
}

delete_all() {
    echo -e "${CYN}--- 6) Delete All Configurations ---${RST}"
    read_input "${BRED}WARNING: Are you sure you want to delete all configs and keys? (y/N): ${RST}" confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sudo systemctl stop wg-quick@wg0 2>/dev/null
        sudo rm -f "$CONFIG_FILE" "$CONFIG_DIR/privatekey" "$CONFIG_DIR/publickey"
        echo -e "${BRED}⚠ All WireGuard configurations and keys deleted.${RST}"
    else
        echo -e "${YLW}❌ Operation cancelled.${RST}"
    fi
    read_input "Press Enter to continue..." DUMMY
}

show_keys_and_ports() {
    echo -e "${CYN}--- 7) Server A & B Info ---${RST}"

    if [[ -f "$CONFIG_DIR/privatekey" && -f "$CONFIG_DIR/publickey" && -f "$CONFIG_FILE" ]]; then
        PRIVATE_KEY=$(cat "$CONFIG_DIR/privatekey")
        PUBLIC_KEY=$(cat "$CONFIG_DIR/publickey")

        # Extracting details from wg0.conf
        ADDRESS=$(grep -E '^[[:space:]]*Address[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        LISTEN_PORT=$(grep -E '^[[:space:]]*ListenPort[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        ENDPOINT=$(grep -E '^[[:space:]]*Endpoint[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        ALLOWED_IPS=$(grep -E '^[[:space:]]*AllowedIPs[[:space:]]*=' "$CONFIG_FILE" | head -n1 | awk -F= '{gsub(/ /,"",$2); print $2}')
        
        # Fallback for ListenPort if not explicitly set
        if [[ -z "$LISTEN_PORT" ]]; then
            LISTEN_PORT=$DEFAULT_PORT
        fi

        echo -e "${BLU}----------------------------------------${RST}"
        echo -e "${WHT}Server A (Local) Info:${RST}"
        echo -e "  ${YLW}Private Key:${RST} $PRIVATE_KEY"
        echo -e "  ${YLW}Public Key:${RST}  $PUBLIC_KEY"
        echo -e "  ${YLW}Address:${RST}     $ADDRESS"
        echo -e "  ${YLW}Listen Port:${RST} $LISTEN_PORT"
        echo -e "${BLU}----------------------------------------${RST}"
        echo -e "${WHT}Server B (Peer) Info:${RST}"
        echo -e "  ${YLW}Endpoint:${RST}    $ENDPOINT"
        echo -e "  ${YLW}Allowed IPs:${RST} $ALLOWED_IPS"
        echo -e "${BLU}----------------------------------------${RST}"

    else
        echo -e "${BRED}⚠ Keys or configuration file not found. Please generate configuration first.${RST}"
    fi

    read_input "Press Enter to continue..." DUMMY
}

edit_config() {
    echo -e "${CYN}--- 8) Edit Configuration ---${RST}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${BRED}⚠ Configuration file not found! Please generate it first.${RST}"
        read_input "Press Enter to continue..." DUMMY
        return
    fi

    # Extract current values
    PRIVATE_KEY=$(grep -E 'PrivateKey' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}')
    ADDRESS=$(grep -E 'Address' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}')
    LISTEN_PORT=$(grep -E 'ListenPort' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}')
    PUBLIC_KEY=$(grep -E 'PublicKey' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}') # This is Server B's Public Key
    ENDPOINT=$(grep -E 'Endpoint' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}')
    ALLOWED_IPS=$(grep -E 'AllowedIPs' "$CONFIG_FILE" | awk -F= '{gsub(/ /,"",$2); print $2}')
    
    # Fallback for ListenPort
    if [[ -z "$LISTEN_PORT" ]]; then
        LISTEN_PORT=$DEFAULT_PORT
    fi

    echo -e "${YLW}Current Address:${RST} $ADDRESS"
    read_input "New Address (or press Enter to keep current): " new_ADDRESS
    ADDRESS=${new_ADDRESS:-$ADDRESS}

    echo -e "${YLW}Current ListenPort:${RST} $LISTEN_PORT"
    read_input "New ListenPort (or press Enter to keep current): " new_PORT
    LISTEN_PORT=${new_PORT:-$LISTEN_PORT}

    echo -e "${YLW}Current Endpoint:${RST} $ENDPOINT"
    read_input "New Endpoint (or press Enter to keep current): " new_ENDPOINT
    ENDPOINT=${new_ENDPOINT:-$ENDPOINT}

    echo -e "${YLW}Current AllowedIPs:${RST} $ALLOWED_IPS"
    read_input "New AllowedIPs (or press Enter to keep current): " new_ALLOWED
    ALLOWED_IPS=${new_ALLOWED:-$ALLOWED_IPS}

    echo -e "${YLW}Updating configuration...${RST}"
    cat > "$CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $ADDRESS
ListenPort = $LISTEN_PORT

[Peer]
PublicKey = $PUBLIC_KEY
Endpoint = $ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

    chmod 600 "$CONFIG_FILE"
    echo -e "${BGRN}✅ Configuration updated successfully.${RST}"
    read_input "Press Enter to continue..." DUMMY
}

# ------------------------------------------------
# Main Loop
# ------------------------------------------------

while true; do
    show_menu
    read_input "→ Enter your choice [0-8]: " choice
    
    case $choice in
        1) install_wireguard ;;
        2) generate_config ;;
        3) show_status ;;
        4) show_full_config ;;
        5) enable_service ;;
        6) delete_all ;;
        7) show_keys_and_ports ;;
        8) edit_config ;;
        0) echo -e "${BGRN}Thank you for using WireGuard Manager. Goodbye!${RST}"; exit 0 ;;
        *) echo -e "${BRED}Invalid option! Please select a number between 0 and 8.${RST}"; sleep 1 ;;
    esac
done
