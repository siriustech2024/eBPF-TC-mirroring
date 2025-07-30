#!/bin/bash

set -e

usage() {
    echo "Uso:"
    echo "  $0 <iface_src> <iface_dst>        # Ativa espelhamento"
    echo "  $0 stop <iface_src>               # Remove espelhamento"
    echo "  $0 list                           # Lista espelhamentos ativos"
    exit 1
}

list_tc_mirrors() {
    echo "[*] Espelhamentos ativos:"
    for iface in $(ip -o link show | awk -F: '{print $2}' | tr -d ' '); do
        if tc qdisc show dev "$iface" | grep -q "clsact"; then
            if tc filter show dev "$iface" ingress | grep -q bpf; then
                echo "Interface: $iface"
                tc filter show dev "$iface" ingress | grep -A3 bpf
                echo "---"
            fi
        fi
    done
    exit 0
}

if [[ "$1" == "list" ]]; then
    list_tc_mirrors
elif [[ "$1" == "stop" ]]; then
    IFACE_SRC="$2"
    if [[ -z "$IFACE_SRC" ]]; then usage; fi

    echo "[*] Removendo filtros de $IFACE_SRC..."

    tc filter del dev "$IFACE_SRC" ingress 2>/dev/null || true

    if ! tc filter show dev "$IFACE_SRC" ingress | grep -q .; then
        tc qdisc del dev "$IFACE_SRC" clsact 2>/dev/null || true
        echo "[+] clsact removido de $IFACE_SRC"
    fi

    echo "[+] Espelhamento removido de $IFACE_SRC"
    exit 0
fi

# Ativação padrão
IFACE_SRC="$1"
IFACE_DST="$2"
if [[ -z "$IFACE_SRC" || -z "$IFACE_DST" ]]; then usage; fi

IFINDEX_DST=$(ip link show "$IFACE_DST" | awk -F: '/^[0-9]+: / {print $1}')

echo "[+] Interface de origem: $IFACE_SRC"
echo "[+] Interface de destino: $IFACE_DST (índice $IFINDEX_DST)"

make clean
make IFINDEX=$IFINDEX_DST

tc qdisc replace dev "$IFACE_SRC" clsact || true
tc filter del dev "$IFACE_SRC" ingress 2>/dev/null || true

tc filter add dev "$IFACE_SRC" ingress bpf da obj mirror_tc.o sec "tc/ingress"

echo "[+] Espelhamento ativado de $IFACE_SRC para $IFACE_DST"
