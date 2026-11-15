# Configuración manual

**Navegación:** [Inicio](../README.md) ·
[← Despliegue](03-despliegue-con-vagrant.md) ·
[Siguiente: Pruebas →](05-pruebas-y-validacion.md)

Esta guía explica la estructura y el orden de configuración manual de BIND 9.
El `Vagrantfile` define la topología, los scripts de instalación están en
[`provision/`](../provision/) y las plantillas y zonas se encuentran en
[`config/`](../config/). Los comandos con `sudo` deben ejecutarse en el
servidor indicado. No copies secretos ficticios ni claves de otro entorno.

## Orden de trabajo

1. Prepara la LAN y las direcciones estáticas en `dns1` (`192.168.10.10`),
   `dns2` (`192.168.10.11`) y `cliente1` (`192.168.10.100`).
2. Configura `dns1` como maestro de `asir.lan` y de la zona inversa.
3. Configura `dns2` como esclavo de esas zonas y maestro de `es.asir.lan`.
4. Valida la sintaxis, las zonas, las transferencias TSIG y la delegación.

## BIND en `dns1`

1. Instala BIND y sus utilidades:

   ```bash
   sudo apt update
   sudo apt install bind9 bind9-utils bind9-dnsutils
   ```

2. Crea la clave TSIG de transferencia. `tsig-keygen` muestra una clave;
   guárdala en un fichero legible solo por `root:bind` y distribúyela de forma
   segura a `dns2`:

   ```bash
   sudo install -d -o root -g bind -m 0750 /etc/bind/keys
   sudo tsig-keygen -a hmac-sha256 transfer-key
   ```

   Guarda el bloque `key "transfer-key" { ... };` en
   `/etc/bind/keys/transfer.key` con permisos `0640` y propietario `root:bind`.
   No la publiques ni la pegues en Git.

3. Configura `/etc/bind/named.conf.options` con acceso limitado a la LAN.
   Consulta [`named.conf.options.tmpl`](../config/named.conf.options.tmpl) como
   punto de partida. El marcador `@@DNS_IP@@` se sustituye por `192.168.10.10`.
   No abras recursión a redes no confiables.

4. Declara las zonas en `/etc/bind/named.conf.local` usando como referencia
   [`named.conf.local.dns1.example`](../config/named.conf.local.dns1.example).

5. Instala los ficheros de zona en `/var/lib/bind/` con propietario `bind:bind`:
   - [`db.asir.lan`](../config/zones/db.asir.lan): zona padre, subdominio
     lógico `virtual.asir.lan` y corte `NS` de `es.asir.lan`.
   - [`db.10.168.192`](../config/zones/db.10.168.192): zona inversa.

6. Comprueba las zonas y configuración antes de cargar:

   ```bash
   sudo named-checkconf
   sudo named-checkzone asir.lan /var/lib/bind/db.asir.lan
   sudo named-checkzone 10.168.192.in-addr.arpa /var/lib/bind/db.10.168.192
   ```

   Luego activa e inicia el servicio:

   ```bash
   sudo systemctl enable --now bind9
   sudo systemctl status bind9 --no-pager
   ```

## BIND en `dns2`

1. Instala BIND y sus utilidades.
2. Instala la misma clave `/etc/bind/keys/transfer.key` compartida con `dns1`
   (`root:bind`, `0640`) y declara el bloque `server 192.168.10.10` que la usa.
3. Configura `/etc/bind/named.conf.options` sustituyendo `@@DNS_IP@@` por
   `192.168.10.11`.
4. Declara `asir.lan` y la zona inversa como esclavas (`type slave`) con `dns1`
   como maestro, y declara `es.asir.lan` como maestra en `dns2`. Consulta
   [`named.conf.local.dns2.example`](../config/named.conf.local.dns2.example).
5. Crea la zona hija `/var/lib/bind/db.es.asir.lan` usando
   [`db.es.asir.lan`](../config/zones/db.es.asir.lan) (`bind:bind`, `0640`).
6. Valida configuración y zona, y luego inicia BIND:

   ```bash
   sudo named-checkconf
   sudo named-checkzone es.asir.lan /var/lib/bind/db.es.asir.lan
   sudo systemctl enable --now bind9
   ```

Una zona esclava recién declarada necesita comunicarse con el maestro por
UDP/TCP 53. Comprueba conectividad y que el maestro permita transferencias
autenticadas antes de depurar el contenido del fichero esclavo en
`/var/cache/bind/`: BIND genera esa copia automáticamente.

## Edición manual de zonas

Tras editar un fichero de zona en `dns1` o `dns2`, recuerda incrementar el
número de serie (`Serial`) en el registro `SOA`, validar con `named-checkzone`
y recargar con `sudo rndc reload`. Si en el futuro añades actualizaciones
dinámicas (DDNS), congela la zona antes de editar (`rndc freeze` / `rndc thaw`).

## Diferencia entre el ejemplo y producción

Esta guía no constituye un procedimiento universal de instalación: interfaces,
nombres de paquetes, servicios, permisos y rutas dependen de la versión y del
sistema. En producción se requieren controles adicionales como DNSSEC firmado,
separación entre servidores autoritativos y recursivos, filtrado de tráfico y
supervisión.
