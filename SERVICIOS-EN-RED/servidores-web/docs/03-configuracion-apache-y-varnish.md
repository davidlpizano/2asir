# 3. Configuración de Apache y Varnish

**Navegación:** [Inicio](../README.md) ·
[← Requisitos e instalación](02-requisitos-e-instalacion.md) ·
[Siguiente: Pruebas, verificación y `ab` →](04-pruebas-verificacion-y-ab.md)

Todos los ficheros de configuración activos están versionados en [`../config/`](../config/) sin incluir claves privadas ni contraseñas.

---

## 3.1 Configuración de Máquina 1 (`web-apache` — `172.31.16.51`)

Antes de modificar cualquier fichero en producción se guardó copia de seguridad en `/root/backup-apache-20261118/`.

### Módulos habilitados (RA3 §3.1)

```bash
sudo a2enmod remoteip headers expires
```

| Módulo | Función en esta arquitectura |
| :--- | :--- |
| `ssl`, `rewrite` | Terminación HTTPS con Certbot y redirección HTTP→HTTPS para `davidservicios.ddns.net`. |
| `remoteip` | Sustituye la IP origen de `M2` (`172.31.27.180`) por la IP real del cliente recibida en `X-Forwarded-For`. |
| `expires`, `headers` | Publican `Expires` y `Cache-Control: public, max-age=120` para que Varnish respete tiempos de caché explícitos. |
| `status` | Expone `/server-status` y `/server-status?auto` para monitorizar trabajadores ocupados/libres durante las pruebas. |

### Endurecimiento (`security.conf`)

Fichero: [`config/apache-m1/security.conf`](../config/apache-m1/security.conf) (`/etc/apache2/conf-available/security.conf`):

```apache
ServerTokens Prod
ServerSignature Off
TraceEnable Off
```

- **Justificación:** reduce la información expuesta en cabeceras (`Server: Apache` en lugar de `Apache/2.4.71 (Debian)`) y desactiva el método `TRACE` (RA3 §2.1 y §7.2).

### Restauración de IP tras proxy (`remoteip.conf`)

Fichero: [`config/apache-m1/remoteip.conf`](../config/apache-m1/remoteip.conf) (`/etc/apache2/conf-available/remoteip.conf`):

```apache
<IfModule mod_remoteip.c>
	RemoteIPHeader X-Forwarded-For
	RemoteIPTrustedProxy 172.31.27.180
</IfModule>
```

- **Justificación:** solo se confía en la cabecera `X-Forwarded-For` cuando la conexión procede de la IP privada del nodo Varnish (`172.31.27.180`), evitando suplantación desde clientes externos.

### Cabeceras de caché (`cache-headers.conf`)

Fichero: [`config/apache-m1/cache-headers.conf`](../config/apache-m1/cache-headers.conf) (`/etc/apache2/conf-available/cache-headers.conf`):

```apache
<IfModule mod_expires.c>
	ExpiresActive On
	ExpiresByType text/html "access plus 120 seconds"
	ExpiresByType text/css "access plus 300 seconds"
	ExpiresByType application/javascript "access plus 300 seconds"
	ExpiresByType image/png "access plus 300 seconds"
	ExpiresByType image/webp "access plus 300 seconds"
	ExpiresByType image/jpeg "access plus 300 seconds"
	ExpiresByType image/svg+xml "access plus 300 seconds"
</IfModule>
<IfModule mod_headers.c>
	<FilesMatch "\.(html|css|js|png|jpg|jpeg|webp|svg|woff2)$">
		Header set Cache-Control "public, max-age=120"
	</FilesMatch>
</IfModule>
```

- **Justificación:** sin `Cache-Control` explícito, la caché depende únicamente del TTL por defecto de Varnish (`120s`). Con `mod_expires` y `mod_headers`, el backend controla explícitamente la caducidad conforme al estándar HTTP (RA3 §1.5 y §1.8).

### Monitorización interna (`status.conf`)

Fichero: [`config/apache-m1/status.conf`](../config/apache-m1/status.conf) (`/etc/apache2/mods-available/status.conf`):

```apache
<Location /server-status>
	SetHandler server-status
	Require local
	Require ip 172.31.27.180
</Location>

ExtendedStatus On

<IfModule mod_proxy.c>
	ProxyStatus On
</IfModule>
```

- **Justificación:** restringido exclusivamente a `localhost` y a la IP privada de `M2` (`172.31.27.180`), nunca expuesto al público (RA3 §8.1).

### Sitios virtuales HTTP y HTTPS

- [`config/apache-m1/davidservicios.conf`](../config/apache-m1/davidservicios.conf): redirige `http://davidservicios.ddns.net` a HTTPS (`301`), pero permite que las peticiones internas por IP (`172.31.16.51` desde Varnish o `ab`) reciban `200 OK` en HTTP sin bucles de redirección (imprescindible dado que el Security Group en AWS bloquea `8080` entre instancias).
- [`config/apache-m1/davidservicios-le-ssl.conf`](../config/apache-m1/davidservicios-le-ssl.conf): sirve `/var/www/html` en `:443` usando el certificado ECDSA de Let's Encrypt y `/etc/letsencrypt/options-ssl-apache.conf`.

### Activación y recarga sin corte (RA3 §2.3)

```bash
sudo a2enconf remoteip cache-headers
sudo /usr/sbin/apache2ctl -t
sudo systemctl reload apache2
```

---

## 3.2 Configuración de Máquina 2 (`varnish-cache` — `172.31.27.180`)

### Unidad `systemd` de Varnish (`override.conf`)

Fichero: [`config/varnish-m2/varnish.override.conf`](../config/varnish-m2/varnish.override.conf) (`/etc/systemd/system/varnish.service.d/override.conf`):

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/varnishd \
          -F \
          -a :80 \
          -a 127.0.0.1:6081 \
          -T localhost:6082 \
          -f /etc/varnish/default.vcl \
          -S /etc/varnish/secret \
          -p feature=+http2 \
          -s malloc,256m
```

- **Decisiones justificadas:**
  - `-a :80`: permite atender tanto tráfico público (`http://18.234.214.81/`) como tráfico interno de la VPC (`http://172.31.27.180/`) aprovechando el puerto `80` permitido en el Security Group de AWS.
  - `-a 127.0.0.1:6081`: mantiene el puerto estándar local de Varnish para pruebas internas.
  - `-T localhost:6082`: interfaz de administración (`varnishadm`) vinculada únicamente a `localhost`.
  - `-s malloc,256m`: almacenamiento en memoria RAM dimensionado para una instancia con `939 MiB` de RAM totales (evita *swap* y mantiene memoria libre para el sistema y `ab`).

### Configuración VCL (`default.vcl`)

Fichero: [`config/varnish-m2/default.vcl`](../config/varnish-m2/default.vcl) (`/etc/varnish/default.vcl`):

```vcl
vcl 4.1;

backend apache_m1 {
    .host = "172.31.16.51";
    .port = "80";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = {
        .url = "/";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

acl purge_acl {
    "localhost";
    "127.0.0.1";
    "172.31.16.51";
}

sub vcl_recv {
    set req.backend_hint = apache_m1;

    if (req.method == "PURGE") {
        if (!client.ip ~ purge_acl) {
            return (synth(405, "Method Not Allowed"));
        }
        return (purge);
    }

    if (req.http.Host ~ "^davidservicios\.ddns\.net(:[0-9]+)?$") {
        set req.http.Host = "172.31.16.51";
    }
}

sub vcl_backend_response {
    if (beresp.ttl <= 0s && beresp.http.Cache-Control !~ "no-cache|no-store|private") {
        set beresp.ttl = 120s;
    }
    set beresp.grace = 30s;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Cache-Hits = obj.hits;
}
```

- **Decisiones justificadas:**
  - `.probe`: realiza chequeos de salud cada `5s` sobre `GET /` de `172.31.16.51:80`; necesita 3 respuestas `200` de la ventana de 5 para marcar `apache_m1` como `healthy`.
  - `acl purge_acl`: solo `localhost` y el backend `172.31.16.51` pueden invalidar caché con el método HTTP `PURGE`; cualquier otra IP recibe `405 Method Not Allowed`.
  - Normalización de `Host`: si llega una petición HTTP con `Host: davidservicios.ddns.net`, se reescribe a `172.31.16.51` al enviarla al backend para evitar que Apache responda con redirección `301` hacia HTTPS.
  - `beresp.grace = 30s`: permite servir contenido reciente si el backend sufre una caída breve.
  - `vcl_deliver`: añade `X-Cache` (`HIT`/`MISS`) y `X-Cache-Hits` para auditar el comportamiento de la caché desde cliente.

### Validación de sintaxis y arranque

```bash
sudo /usr/sbin/varnishd -C -f /etc/varnish/default.vcl >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now varnish
sudo systemctl restart varnish
```

---

## 3.3 Seguridad, certificados y custodia de secretos (RA3 §10.6)

- **Certificado TLS (`M1`):**
  - Dominio: `davidservicios.ddns.net` (tipo `ECDSA`, válido hasta `2027-02-11 09:07:31+00:00`).
  - Renovación automática: gestionada por el temporizador `certbot.timer` (`systemctl list-timers`).
  - Protocolo verificado en pruebas: `TLSv1.3` con `TLS_AES_256_GCM_SHA384`.
- **Custodia de credenciales y claves (nunca en este repositorio):**
  - Las claves privadas SSH de acceso (`abierto.pem`, `aws_david.pem`) se custodian exclusivamente en el equipo de administración local con permisos `0400` (`~/Documentos/`).
  - La clave privada TLS del certificado Let's Encrypt reside únicamente en `/etc/letsencrypt/live/davidservicios.ddns.net/privkey.pem` en `M1` (permisos restringidos a `root`).
  - El secreto de administración de Varnish reside en `/etc/varnish/secret` en `M2` (solo lectura `root`).
- **Control de acceso de red:**
  - `/server-status` en `M1` limitado a `127.0.0.1` y `172.31.27.180`.
  - Puerto de administración Varnish (`6082`) ligado exclusivamente a `127.0.0.1`.
  - Método `PURGE` restringido por `purge_acl` (`localhost` y `172.31.16.51`).
