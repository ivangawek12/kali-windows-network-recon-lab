#!/usr/bin/env bash
# Escaneos TCP acotados. Solo ejecutar contra la interfaz WSL de Windows
# que administras y cuya IP verificaste en ipconfig.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <IP_WINDOWS_WSL>" >&2
  echo "Ejemplo de sintaxis (verifica tu IP real): $0 172.26.144.1" >&2
  exit 2
fi

TARGET="$1"
echo "Objetivo declarado: $TARGET"
echo "Confirma que es la interfaz WSL de tu propio equipo antes de continuar."
read -r -p "¿Confirmas autorización y que es tu Windows/WSL local? Escribe SI: " CONFIRM
if [[ "$CONFIRM" != "SI" ]]; then
  echo "Cancelado."
  exit 1
fi

echo
 echo "=== Información local de red ==="
ip -br address
ip route

echo
 echo "=== Escaneo TCP acotado de puertos comunes ==="
nmap -sT -Pn -n -p 135,139,445,3389,5985 "$TARGET"

echo
 echo "=== Top 20 puertos TCP ==="
nmap -sT -Pn -n --top-ports 20 "$TARGET"

echo
 echo "=== Puertos dinámicos observados en el laboratorio ==="
nmap -sT -Pn -n -p 49664-49670 "$TARGET"

echo
 echo "=== Detección ligera del servicio TCP 135 ==="
nmap -sT -sV -Pn -n -p 135 --version-light "$TARGET"
