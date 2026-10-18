\
# Hallazgos de referencia (ejemplo saneado)

Este archivo resume el tipo de evidencia recogida durante una sesión de laboratorio. Las direcciones y detalles identificables se han generalizado u omitido. Los resultados no son valores esperados ni garantizados en otros equipos.

## Entorno

| Elemento | Valor publicado |
|---|---|
| Interfaz Kali | `<IP_KALI_WSL>` |
| Interfaz Windows WSL | `<IP_WINDOWS_WSL>` |
| Resolver WSL | `<RESOLVER_WSL>` |
| Otras interfaces | Omitidas por privacidad |

## Resultados de Nmap

| Prueba | Resultado de referencia |
|---|---|
| Loopback de Kali, puertos TCP seleccionados | Cerrados |
| Windows WSL TCP 135 | `open`; servicio detectado como Microsoft Windows RPC |
| Windows WSL TCP 139, 445, 3389, 5985 | `filtered` |
| Top 20 puertos TCP de Windows WSL | TCP 135 `open`; otros puertos seleccionados `filtered` |
| Windows WSL TCP 49664–49670 | Todos `filtered` desde Kali |
| Ping a la interfaz Windows WSL | Sin respuestas ICMP |

Los estados corresponden a esa sesión específica y pueden cambiar según el equipo, la versión de Windows/WSL y las políticas activas.

## Correlación con Windows

- Los perfiles Domain, Private y Public del firewall estaban habilitados.
- La acción entrante predeterminada era `Block`; la saliente, `Allow`.
- El logging de tráfico permitido y bloqueado estaba deshabilitado.
- TCP 135 estaba en escucha y se asociaba a servicios RPC de Windows.
- Se observó una regla entrante habilitada de Hyper-V para RPC-EPMAP, con acción `Allow` y filtro TCP para el endpoint mapper (puerto 135).
- Se observaron sockets de escucha en el rango dinámico analizado. Se omiten detalles por proceso porque no son necesarios para explicar la conclusión principal.

## Conclusión

La evidencia confirma una diferencia entre TCP 135, que respondió como abierto, y varios puertos que aparecieron filtrados desde Kali. La política entrante predeterminada del firewall es `Block`, y se encontró una regla pertinente para el endpoint mapper. Sin embargo, la sesión no demostró causalmente qué regla o componente produjo cada resultado.

Como el logging estaba deshabilitado, no había registros de firewall disponibles para correlacionar con la prueba. Una confirmación más fuerte requeriría una prueba controlada y autorizada con evidencia adicional.

## Nota de publicación

Este ejemplo omite direcciones exactas, identificadores de procesos y otros detalles del equipo. Si lo adaptas a otra sesión, sustituye los valores identificables por marcadores genéricos y conserva solo los datos necesarios para explicar el método.
