# 2. Requisitos y proceso de instalación

**Navegación:** [Inicio](../README.md) ·
[← Fundamentos y arquitectura](01-fundamentos-y-arquitectura.md) ·
[Siguiente: Configuración de Apache y Varnish →](03-configuracion-apache-y-varnish.md)

## 2.1 Requisitos y versiones exactas (RA3 §10.3)

Ambas instancias utilizan **Debian GNU/Linux 13 (`trixie`)**, 2 vCPU y 939 MiB de RAM.

| Componente | Máquina 1 (`web-apache`) | Máquina 2 (`varnish-cache`) | Comando de verificación |
| :--- | :--- | :--- | :--- |
| **Sistema Operativo** | Debian GNU/Linux 13 (`trixie`, `13.7`) | Debian GNU/Linux 13 (`trixie`, `13.7`) | `cat /etc/os-release` |
| **Apache HTTP Server** | `Apache/2.4.71 (Debian)` (`mpm_event`) | `Apache/2.4.69 (Debian)` (`mpm_event`) | `/usr/sbin/apache2 -v` |
| **ApacheBench (`apache2-utils`)** | `Version 2.3` | `Version 2.3 <$Revision: 1934973 $>` | `ab -V` |
| **Varnish Cache** | — | `varnish-7.7.0` (`7.7.0-3+deb13u2`) | `/usr/sbin/varnishd -V` |
| **Certbot** | `certbot 4.0.0` | — | `certbot --version` |
| **Cliente DDNS No-IP** | `/usr/bin/noip-duc` (activo) | — | `ps aux \| grep noip-duc` |

---

## 2.2 Instalación en Máquina 1 (`web-apache`, `172.31.16.51`)

En esta instancia ya estaban desplegados Apache, las utilidades `ab`, Certbot y el cliente No-IP. Los comandos equivalentes para reproducir su instalación base en Debian 13 son:

```bash
sudo apt-get update
sudo apt-get install -y apache2 apache2-utils certbot python3-certbot-apache
```

Salida esperada al comprobar que los binarios y el servicio están disponibles:

```text
$ /usr/sbin/apache2 -v
Server version: Apache/2.4.71 (Debian)
Server built:   2026-11-11T12:54:19

$ certbot --version
certbot 4.0.0

$ ab -V | head -n 2
This is ApacheBench, Version 2.3 <$Revision$>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
```

---

## 2.3 Instalación en Máquina 2 (`varnish-cache`, `172.31.27.180`)

En la segunda máquina partimos de Apache (`2.4.69`) y `apache2-utils` (`ab`) ya instalados. Para dejar libre el puerto `80` a Varnish sin eliminar el Apache local, primero se reubica Apache al puerto `8080` y después se instala `varnish`.

### Paso 1: copia de seguridad y cambio de puerto de Apache local (`80` → `8080`)

```bash
sudo mkdir -p /root/backup-20261118
sudo cp -a /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf /root/backup-20261118/

sudo sed -i "s/^Listen 80$/Listen 8080/" /etc/apache2/ports.conf
sudo sed -i "s/<VirtualHost \*:80>/<VirtualHost *:8080>/" /etc/apache2/sites-available/000-default.conf

sudo /usr/sbin/apache2ctl -t
sudo systemctl restart apache2
```

Salida esperada:

```text
Syntax OK
```

### Paso 2: instalación de Varnish Cache 7.7

```bash
sudo apt-get update
sudo apt-get install -y varnish
```

Comprobación de versión tras instalar:

```text
$ /usr/sbin/varnishd -V
varnishd (varnish-7.7.0 revision 71fc9d211c471106e4be590f3816a56ba156a833)
```

> [!IMPORTANT]
> Antes de arrancar Varnish en el puerto `80`, consulta [3. Configuración de Apache y Varnish](03-configuracion-apache-y-varnish.md) para crear el *drop-in* de `systemd` (`/etc/systemd/system/varnish.service.d/override.conf`) y el fichero VCL (`/etc/varnish/default.vcl`). Por defecto en Debian, el paquete arranca escuchando en `:6081` apuntando a `127.0.0.1:8080`.
