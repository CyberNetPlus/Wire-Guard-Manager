#!/bin/bash
# ────────────────────────────────────────────────
# Tunnel Manager — Full Graphic v6.1
# Author: Mikhaieel
# YouTube: https://youtube.com/@Mikhaieel
# ────────────────────────────────────────────────

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; RESET='\033[0m'

# Defaults for tunnels
DEFAULT_6TO4_IPV6="fd00:154::2/64"
DEFAULT_LOCAL="fd00:154::2"
DEFAULT_REMOTE="fd00:154::1"
DEFAULT_IPIP_IPV4="192.168.140.2/30"
DEFAULT_GRE_IPV4="192.168.150.2/30"

# ────────────── تابع نمایش وضعیت تونل‌ها ──────────────
function show_tunnel_status() {
    local TUN=$1
    local TUN_NAME=$2

    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════╗${RESET}"
    if ip link show $TUN &>/dev/null; then
        echo -e "║ ${GREEN}[✔] $TUN_NAME Installed${RESET}"
        echo -e "║ ${CYAN}IPv4:${RESET}"
        ip addr show dev $TUN | grep inet | awk '{print "║    "$2}' || echo "║    None"
        echo -e "║ ${CYAN}IPv6:${RESET}"
        ip -6 addr show dev $TUN | grep inet6 | awk '{print "║    "$2}' || echo "║    None"
    else
        echo -e "║ ${RED}[✖] $TUN_NAME Not Installed${RESET}"
    fi
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════╝${RESET}"
    echo
}

# ────────────── حلقه منو اصلی ──────────────
while true; do
    clear
    # وضعیت تونل‌ها
    STATUS_6TO4=$(ip link show 6to4 &>/dev/null && echo -e "${GREEN}Installed${RESET}" || echo -e "${RED}Not Installed${RESET}")
    STATUS_IPIP=$(ip link show ipip6 &>/dev/null && echo -e "${GREEN}Installed${RESET}" || echo -e "${RED}Not Installed${RESET}")
    STATUS_GRE=$(ip link show gre1 &>/dev/null && echo -e "${GREEN}Installed${RESET}" || echo -e "${RED}Not Installed${RESET}")

    # ────────────── Header ──────────────
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗"
    echo -e "║                    TUNNEL CYBER-TUNNEL                   ║"
    echo -e "║                 Author: Mikhaieel                        ║"
    echo -e "║        YouTube: https://www.youtube.com/@Cyber_Net_Plus  ║"
    echo -e "╚══════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${YELLOW}Select an option:${RESET}"
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "║ 1) Create new 6to4 tunnel       Status: $STATUS_6TO4        "
    echo -e "║ 2) Setup IPIP6 Tunnel           Status: $STATUS_IPIP        "
    echo -e "║ 3) Setup GRE1 Tunnel            Status: $STATUS_GRE         "
    echo -e "║ 4) Setup Networking & Firewall                              "
    echo -e "║ 5) Show all tunnels status                                  "
    echo -e "║ 6) Delete all existing tunnels                              "
    echo -e "║ 7) Exit                                                     "
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"
    echo
    read -rp "Select [1-7]: " choice
    echo

    case $choice in
        1)
            read -rp "Enter Remote IPv4 (leave empty to skip): " REMOTE_IP
            read -rp "Enter Local IPv4 (leave empty to skip): " LOCAL_IP
            read -rp "Enter IPv6 Address with Prefix (default: $DEFAULT_6TO4_IPV6): " IPV6_ADDR
            IPV6_ADDR=${IPV6_ADDR:-$DEFAULT_6TO4_IPV6}

            echo -e "${YELLOW}[*] Creating 6to4 tunnel...${RESET}"
            CMD="sudo ip tunnel add 6to4 mode sit"
            [[ -n "$REMOTE_IP" ]] && CMD="$CMD remote $REMOTE_IP"
            [[ -n "$LOCAL_IP" ]] && CMD="$CMD local $LOCAL_IP"
            $CMD 2>/dev/null || echo -e "${RED}[✖] Tunnel may already exist!${RESET}"
            sudo ip -6 addr add "$IPV6_ADDR" dev 6to4 2>/dev/null
            sudo ip link set 6to4 mtu 1400
            sudo ip link set 6to4 up
            echo -e "${GREEN}[✔] 6to4 Tunnel configured!${RESET}"
            read -rp "Press Enter to return to main menu..."
            ;;
        2)
            echo -e "${YELLOW}[*] Setting up IPIP6 Tunnel...${RESET}"
            read -rp "Enter Local IPv6 (default: $DEFAULT_LOCAL): " LOCAL
            LOCAL=${LOCAL:-$DEFAULT_LOCAL}
            read -rp "Enter Remote IPv6 (default: $DEFAULT_REMOTE): " REMOTE
            REMOTE=${REMOTE:-$DEFAULT_REMOTE}
            read -rp "Enter IPv4 address for IPIP6 (default: $DEFAULT_IPIP_IPV4): " IPV4
            IPV4=${IPV4:-$DEFAULT_IPIP_IPV4}

            sudo ip link add name ipip6 type ip6tnl local $LOCAL remote $REMOTE mode any
            sleep 1
            sudo ip addr add $IPV4 dev ipip6
            sleep 1
            sudo ip link set ipip6 mtu 1400
            sudo ip link set ipip6 up
            echo -e "${GREEN}[✔] IPIP6 Tunnel configured!${RESET}"
            read -rp "Press Enter to return to main menu..."
            ;;
        3)
            echo -e "${YELLOW}[*] Setting up GRE1 Tunnel...${RESET}"
            read -rp "Enter Local IPv6 (default: $DEFAULT_LOCAL): " LOCAL
            LOCAL=${LOCAL:-$DEFAULT_LOCAL}
            read -rp "Enter Remote IPv6 (default: $DEFAULT_REMOTE): " REMOTE
            REMOTE=${REMOTE:-$DEFAULT_REMOTE}
            read -rp "Enter IPv4 address for GRE1 (default: $DEFAULT_GRE_IPV4): " IPV4
            IPV4=${IPV4:-$DEFAULT_GRE_IPV4}

            sudo ip link add name gre1 type ip6gre local $LOCAL remote $REMOTE
            sudo ip addr add $IPV4 dev gre1
            sudo ip link set gre1 mtu 1400
            sudo ip link set gre1 up
            echo -e "${GREEN}[✔] GRE1 Tunnel configured!${RESET}"
            read -rp "Press Enter to return to main menu..."
            ;;
        4)
            echo -e "${YELLOW}[*] Setting up Networking & Firewall...${RESET}"
            # IP forwarding
            if ! grep -q "net.ipv4.ip_forward" /etc/sysctl.conf; then
                echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
            fi
            if ! grep -q "net.ipv6.conf.all.forwarding" /etc/sysctl.conf; then
                echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf
            fi
            sudo sysctl -p

            # iptables
            sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
            sudo iptables -A INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
            sudo iptables -A FORWARD -j ACCEPT

            # MTU برای همه تونل‌ها
            for TUN in 6to4 ipip6 gre1; do
                if ip link show $TUN &>/dev/null; then
                    sudo ip link set $TUN mtu 1400
                fi
            done

            # نمایش وضعیت
            echo -e "${CYAN}┌──────────── iptables ────────────┐${RESET}"
            sudo iptables -L -v -n
            echo -e "${CYAN}└──────────────────────────────────┘${RESET}"

            echo -e "${CYAN}┌──────────── Routes ──────────────┐${RESET}"
            ip route show
            ip -6 route show
            echo -e "${CYAN}└──────────────────────────────────┘${RESET}"

            echo -e "${GREEN}[✔] Networking & Firewall setup completed!${RESET}"
            read -rp "Press Enter to return to main menu..."
            ;;
        5)
            show_tunnel_status 6to4 "6to4"
            show_tunnel_status ipip6 "IPIP6"
            show_tunnel_status gre1 "GRE1"
            read -rp "Press Enter to return to main menu..."
            ;;
        6)
            echo -e "${YELLOW}[*] Removing all tunnels...${RESET}"
            for TUN in 6to4 ipip6 gre1; do
                if ip link show $TUN &>/dev/null; then
                    sudo ip link set $TUN down
                    sudo ip tunnel del $TUN 2>/dev/null
                    sudo ip link del $TUN 2>/dev/null
                    echo -e "${GREEN}[✔] $TUN removed.${RESET}"
                fi
            done
            read -rp "Press Enter to return to main menu..."
            ;;
        7)
            echo -e "${GREEN}Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${RESET}"
            sleep 1
            ;;
    esac
done

