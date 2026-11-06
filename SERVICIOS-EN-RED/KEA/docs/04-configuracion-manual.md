# Configuración manual

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
[← Despliegue](03-despliegue-con-vagrant.md) ·
[Siguiente: Pruebas →](05-pruebas-y-validacion.md)

Esta guía explica la estructura y el orden de configuración de los servicios.
El `Vagrantfile` define la topología, los scripts de instalación están en
[`provision/`](../provision/) y las plantillas se encuentran en
[`config/`](../config/). Los comandos con `sudo` deben ejecutarse en el
servidor indicado. No copies secretos ficticios ni claves de otro entorno.

## Orden de trabajo

1. Prepara la LAN, las direcciones estáticas y el encaminamiento.
2. Configura `dns1` como maestro de `asir.lan` y de la zona inversa.
3. Configura `dns2` como esclavo de esas zonas y maestro de `es.asir.lan`.
4. Valida la sintaxis y conectividad de DNS antes de activar DDNS.
5. Configura Kea DHCP/DDNS y permite la actualización firmada desde Kea.
6. Añade el cliente, renueva una concesión y verifica DNS directo e inverso.
7. Configura y prueba por separado la alta disponibilidad de Kea y VRRP.

Separar estas etapas facilita localizar errores: primero se verifica DNS
estático, luego transferencia, después delegación y finalmente DDNS y HA.

## BIND en `dns1`

1. Instala BIND y sus utilidades:

   ```bash
   sudo apt update
   sudo apt install bind9 bind9-utils bind9-dnsutils
   ```

2. Crea una clave TSIG de transferencia y una de DDNS. `tsig-keygen` muestra
   una clave; guárdala en un fichero legible solo por las cuentas necesarias y
   distribuye la clave de transferencia de forma segura a ambos servidores:

   ```bash
   sudo install -d -o root -g bind -m 0750 /etc/bind/keys
   sudo tsig-keygen -a hmac-sha256 transfer-key
   sudo tsig-keygen -a hmac-sha256 ddns-key
   ```

   La salida contiene bloques `key { ... };` que deben guardarse en ficheros
   separados, con permisos restringidos. No la publiques ni la pegues en Git.

3. Configura las opciones con acceso limitado a la LAN. Consulta
   [`named.conf.options.tmpl`](../config/bind/named.conf.options.tmpl) como
   punto de partida. El marcador `@@DNS_IP@@` se sustituye por la dirección
   del servidor correspondiente. No abras recursión a redes no confiables.

4. Incluye las claves y declara las zonas usando como referencia
   [`named.conf.local.dns1.example`](../config/bind/named.conf.local.dns1.example).
   Ajusta las rutas de las claves a los ficheros que hayas creado.

5. Instala o crea las zonas:
   - [`db.asir.lan`](../config/bind/zones/db.asir.lan): zona padre, registro
     virtual y corte `NS` de `es.asir.lan`.
   - [`db.10.168.192`](../config/bind/zones/db.10.168.192): zona inversa.

6. Comprueba las zonas y configuración antes de cargar:

   ```bash
   sudo named-checkconf
   sudo named-checkzone asir.lan /var/lib/bind/db.asir.lan
   sudo named-checkzone 10.168.192.in-addr.arpa /var/lib/bind/db.10.168.192
   ```

   Ajusta las rutas de los comandos al lugar real donde guardes los ficheros.
   Comprueba permisos de lectura para el usuario/grupo que ejecuta BIND. Luego
   activa el servicio:

   ```bash
   sudo systemctl enable --now bind9
   sudo systemctl status bind9 --no-pager
   ```

## BIND en `dns2`

1. Instala BIND y sus utilidades.
2. Instala la clave de transferencia compartida con `dns1` y declara el bloque
   `server 192.168.10.10` que la usa.
3. Declara `asir.lan` y la zona inversa como esclavas, con `dns1` como maestro.
   Declara `es.asir.lan` como maestra en `dns2`. Consulta
   [`named.conf.local.dns2.example`](../config/bind/named.conf.local.dns2.example).
4. Crea la zona hija usando
   [`db.es.asir.lan`](../config/bind/zones/db.es.asir.lan).
5. Valida configuración y zona, y luego inicia BIND:

   ```bash
   sudo named-checkconf
   sudo named-checkzone es.asir.lan /var/lib/bind/db.es.asir.lan
   sudo systemctl enable --now bind9
   ```

Una zona esclava recién declarada necesita comunicarse con el maestro por DNS y
transferencias TCP/53. Comprueba conectividad y que el maestro permita
transferencias autenticadas antes de depurar el contenido del fichero esclavo:
BIND genera esa copia.

## DDNS desde Kea

La integración tiene dos lados:

- Kea DHCP/DDNS selecciona las zonas destino, genera actualizaciones y firma
  con la clave `ddns-key`.
- BIND tiene esa misma clave y autoriza las actualizaciones mediante
  `update-policy`.

El servidor DHCP debe alcanzar `dns1` por TCP y UDP/53. Verifica primero la
resolución manual de una zona estática; después solicita/renueva una concesión
y revisa los logs de Kea y BIND. Las rutas, nombres de unidades y paquetes
pueden variar según la versión Debian/Kea instalada.

## Editar una zona dinámica

Cuando Kea modifica una zona, BIND mantiene cambios pendientes en un fichero de
journal. No edites directamente el fichero maestro mientras la zona está
activa:

```bash
sudo rndc freeze asir.lan
sudoedit /var/lib/bind/db.asir.lan
sudo named-checkzone asir.lan /var/lib/bind/db.asir.lan
sudo rndc thaw asir.lan
```

Repite para la zona inversa si también la editas. `thaw` vuelve a cargar la
zona. No elimines manualmente los ficheros `.jnl`; si la zona no se puede
descongelar, revisa los mensajes de BIND y su documentación antes de recuperar
el journal.

## Diferencia entre el ejemplo y producción

Esta guía no constituye un procedimiento universal de instalación: interfaces,
nombres de paquetes, servicios, permisos y sockets dependen de la versión y del
sistema. En producción se requieren controles adicionales, como protección de
las APIs de Kea, filtrado de tráfico, supervisión, gestión de secretos,
backups y una estrategia probada de recuperación.
