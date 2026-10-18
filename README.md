# Kali + Windows Network Recon Lab

Guía reproducible para practicar reconocimiento de red autorizado desde Kali Linux (WSL2) contra la interfaz virtual de Windows del mismo equipo.

> **Alcance seguro:** este laboratorio está diseñado para el equipo propio y la dirección de la interfaz WSL de Windows. No ejecutes los comandos contra IPs públicas, redes ajenas ni sistemas para los que no tengas autorización. Las direcciones de ejemplo pueden cambiar en otro equipo.

## Objetivos

- Identificar interfaces y rutas de Kali/WSL2.
- Ejecutar escaneos TCP acotados con Nmap.
- Interpretar `open`, `closed` y `filtered`.
- Correlacionar resultados con sockets en escucha, procesos y servicios de Windows.
- Inspeccionar la política activa de Windows Defender Firewall.
- Documentar qué se confirmó y qué quedó como hipótesis, sin cambiar la configuración por defecto.

## Estructura

```text
kali-windows-network-recon-lab/
├── README.md
├── docs/
│   ├── procedure.md
│   ├── findings-example.md
│   └── glossary.md
└── scripts/
    ├── windows-inventory.ps1
    └── kali-scan.sh
```

## Requisitos

- Windows con WSL2 y Kali Linux.
- Nmap instalado en Kali (`sudo apt update && sudo apt install nmap`).
- PowerShell.

## Inicio rápido

1. En Kali, ejecuta `ip -br address` y `ip route`.
2. En PowerShell, ejecuta `ipconfig` para identificar la interfaz `vEthernet (WSL...)`.
3. Usa como objetivo únicamente la dirección de esa interfaz Windows que conecta con WSL. En la sesión original era `172.26.144.1`, pero **verifica la tuya**.
4. Sigue [`docs/procedure.md`](docs/procedure.md).
5. Compara tus resultados con [`docs/findings-example.md`](docs/findings-example.md).

## Principios

- Primero observar, luego probar, finalmente correlacionar.
- Usar escaneos pequeños y explícitos.
- `filtered` no significa que un puerto esté cerrado.
- No atribuir un resultado a una regla concreta sin evidencia.
- No deshabilitar el firewall ni modificar reglas para “hacer que funcione”.
- Si se habilita logging en un ejercicio futuro, hacerlo solo con autorización y documentar cómo restaurar el estado previo.
