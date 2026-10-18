# Procedimiento completo

Este procedimiento replica la sesión de laboratorio. Ejecuta cada paso y guarda la salida relevante en tus notas.

## 0. Define el alcance

Objetivo: la interfaz virtual de Windows usada por WSL2, desde la instancia Kali local. No uses la IP pública ni escanees redes ajenas. Si las direcciones cambiaron, identifica la dirección actual antes de escanear.

## 1. Inspección de red desde Kali

```bash
ip -br address
ip route
cat /etc/resolv.conf
ip neigh
```

Qué buscar: interfaz y dirección IPv4 de Kali, ruta predeterminada y gateway, resolver configurado por WSL y vecinos conocidos.

Anota los valores localmente para tu análisis. **Antes de publicar la salida**, reemplaza las direcciones por marcadores como `<IP_KALI_WSL>`, `<IP_WINDOWS_WSL>` y `<RESOLVER_WSL>`.

## 2. Identifica las interfaces de Windows

En PowerShell:

```powershell
ipconfig
```

Localiza `vEthernet (WSL...)` y anota su IPv4. Localiza la interfaz WSL y anota su IP solo en tus notas locales. No publiques un volcado completo de `ipconfig` si basta con describir qué interfaz seleccionaste.

## 3. Prueba local en Kali

```bash
nmap -sT -Pn -n -p 22,80,443,8000,8080 127.0.0.1
nmap -sT -Pn -n --top-ports 100 127.0.0.1
```

Registra si los puertos probados están abiertos, cerrados o filtrados. Eso describe únicamente el entorno en el que ejecutaste la prueba.

## 4. Comprueba la conectividad con el gateway WSL

Sustituye `<IP_WINDOWS_WSL>` por la dirección que identificaste en el paso 2:

```bash
ping -c 4 <IP_WINDOWS_WSL>
ip neigh
```

La ausencia de respuesta ICMP no demuestra por sí sola que el host esté apagado o sea inaccesible; ICMP puede estar filtrado.

## 5. Escaneo TCP acotado contra la interfaz WSL de Windows

Usa solo la IP confirmada de tu propia interfaz WSL:

```bash
nmap -sT -Pn -n -p 135,139,445,3389,5985 <IP_WINDOWS_WSL>
nmap -sT -Pn -n --top-ports 20 <IP_WINDOWS_WSL>
nmap -sT -Pn -n -p 49664-49670 <IP_WINDOWS_WSL>
```

Interpretación:
- `open`: Nmap pudo establecer una conexión TCP al puerto.
- `closed`: el host respondió, pero no hay un servicio escuchando en ese puerto TCP.
- `filtered`: Nmap no pudo determinar si está abierto o cerrado porque no obtuvo una respuesta concluyente; un filtro o una condición de red puede estar impidiendo la observación.

No escanees rangos enteros ni amplíes el alcance solo porque algunos puertos aparezcan filtrados.

## 6. Identificación ligera del servicio en TCP 135

Si TCP 135 aparece abierto en tu propio equipo:

```bash
nmap -sT -sV -Pn -n -p 135 --version-light <IP_WINDOWS_WSL>
```

La detección de servicio puede ser imperfecta; úsala como evidencia, no como verdad absoluta. No es necesario escanear el resolver de WSL para completar este laboratorio.

## 7. Inventario de sockets en escucha de Windows

En PowerShell:

```powershell
Get-NetTCPConnection -State Listen |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess
```

Para revisar el proceso asociado a TCP 135:

```powershell
$pid135 = (Get-NetTCPConnection -State Listen -LocalPort 135 |
    Select-Object -First 1 -ExpandProperty OwningProcess)

Get-Process -Id $pid135
Get-CimInstance Win32_Service |
    Where-Object ProcessId -eq $pid135 |
    Select-Object Name, DisplayName, State, StartMode
```

Correlaciona el PID con el proceso y los servicios asociados. Evita publicar los PIDs y el inventario completo si no son necesarios para explicar el hallazgo.

Para revisar procesos que coincidían con los puertos dinámicos observados:

```powershell
$ports = 49664..49670
Get-NetTCPConnection -State Listen |
    Where-Object { $ports -contains $_.LocalPort } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess,
        @{Name='ProcessName';Expression={
            (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        }}
```

No concluyas que cada puerto es RPC solo por el número o el proceso: correlaciona con evidencia específica. Sanea nombres de procesos o servicios antes de publicar si revelan información innecesaria.

## 8. Revisa la política activa del firewall

```powershell
Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

Documenta los perfiles y las acciones predeterminadas observadas. Comparte solo los datos necesarios para explicar el resultado.

Consulta el estado de logging sin cambiar nada:

```powershell
Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name, LogBlocked, LogAllowed, LogFileName
```

Si el logging está deshabilitado, anótalo. Evita publicar rutas internas completas cuando no aporten al análisis.

## 9. Inspecciona la regla de TCP 135 observada

```powershell
Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -Direction Inbound |
    Where-Object DisplayName -Like '*RPC-EPMAP*' |
    Select-Object Name, DisplayName, Enabled, Direction, Action, Profile,
        PolicyStoreSourceType, PolicyStoreSource
```

Si encuentras una regla pertinente, anota sus características relevantes. Para examinar los filtros asociados a la regla, copia su propiedad `Name` exacta:

```powershell
$ruleName = '<NOMBRE_EXACTO_DE_REGLA>'
Get-NetFirewallRule -PolicyStore ActiveStore -Name $ruleName | Get-NetFirewallPortFilter
Get-NetFirewallRule -PolicyStore ActiveStore -Name $ruleName | Get-NetFirewallAddressFilter
Get-NetFirewallRule -PolicyStore ActiveStore -Name $ruleName | Get-NetFirewallInterfaceFilter
```

La regla es coherente con un resultado observado, pero no prueba por sí sola que fuera la única causa de que el puerto apareciera abierto.

## 10. Registra el estado de logging y decide si hace falta más evidencia

Si el logging de tráfico permitido y bloqueado está deshabilitado, puede que no haya registros históricos para correlacionar con el escaneo.

No habilites logging ni cambies reglas automáticamente. Si necesitas una confirmación más fuerte, planifica una prueba autorizada que:
1. documente la configuración previa;
2. habilite temporalmente solo el logging necesario, con autorización;
3. repita un escaneo acotado;
4. inspeccione las entradas relevantes;
5. restaure el estado previo y verifique la restauración.

Un log sin entradas no demuestra por sí solo que el firewall no haya intervenido: también hay que comprobar la ruta, la interfaz y que el tráfico esté cubierto por ese registro.

## 11. Cómo redactar la conclusión

> Los resultados observados muestran diferencias entre puertos abiertos y filtrados. La política entrante predeterminada del firewall y las reglas pertinentes son evidencia contextual, pero no demuestran por sí solas qué componente produjo cada resultado. Para una atribución causal se necesitaría evidencia adicional, por ejemplo logging temporal autorizado y una prueba controlada.

## Checklist para repetir

- [ ] Alcance autorizado definido.
- [ ] IPv4 Kali anotada.
- [ ] IPv4 Windows WSL anotada.
- [ ] Ruta predeterminada anotada.
- [ ] Escaneo local de Kali ejecutado.
- [ ] Escaneo acotado de la interfaz Windows ejecutado.
- [ ] Estados `open` / `closed` / `filtered` explicados.
- [ ] Sockets en escucha correlacionados con procesos.
- [ ] Servicios asociados al puerto 135 revisados.
- [ ] Política activa del firewall documentada.
- [ ] Regla y filtros pertinentes inspeccionados.
- [ ] Logging consultado sin modificarlo.
- [ ] Hallazgos separados de hipótesis.
- [ ] No se modificó la configuración del equipo.
- [ ] Se eliminaron o generalizaron detalles identificables antes de publicar.
