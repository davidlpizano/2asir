# 5. Operación, análisis de registros e incidencias

**Navegación:** [Inicio](../README.md) ·
[← Pruebas, verificación y `ab`](04-pruebas-verificacion-y-ab.md)

---

## 5.1 Operación diaria del servicio (RA3 §2.3 y §10.8)

### Arranque, parada y recarga sin corte

```bash
# En M1 (Apache) — validar siempre antes de recargar
sudo /usr/sbin/apache2ctl -t && sudo systemctl reload apache2

# En M2 (Varnish) — compilar/validar VCL antes de recargar
sudo /usr/sbin/varnishd -C -f /etc/varnish/default.vcl >/dev/null && sudo systemctl reload varnish
```

> [!TIP]
> **`reload` frente a `restart`:** usa siempre `reload` tras cambios de configuración. En Apache ejecuta un reinicio *graceful* y en Varnish (`varnishreload`) compila y carga el nuevo VCL en caliente sin perder la caché en memoria ni cortar conexiones en curso.

### Monitorización habitual

```bash
# Estado de servicios
sudo systemctl is-active apache2 varnish

# Estadísticas de caché en tiempo real (M2)
sudo varnishstat -1
sudo varnishadm backend.list

# Peticiones HTTP en tiempo real que llegan a Varnish (M2)
sudo varnishlog -g request -i ReqMethod,ReqURL,VCL_call,RespStatus

# Estado de Apache desde M2
curl -s http://172.31.16.51/server-status?auto
```

### Rotación de registros y copias de seguridad

- **Rotación automática:** gestionada por `logrotate` en `/etc/logrotate.d/apache2` (`M1`) y `/etc/logrotate.d/varnish` (`M2`).
- **Copias de seguridad recomendadas:** respaldar periódicamente `/etc/apache2/`, `/etc/letsencrypt/` (con permisos preservados), `/var/www/html/` en `M1`, y `/etc/varnish/` junto con `/etc/systemd/system/varnish.service.d/` en `M2`.

---

## 5.2 Análisis de registros en línea de comandos (RA3 §9.1–9.3)

En `M1` (`/var/log/apache2/access.log`, formato `combined`):

```bash
LOG=/var/log/apache2/access.log

# 1. IPs más activas (ya restauradas por mod_remoteip si pasan por Varnish)
sudo awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head

# 2. Distribución de códigos de estado HTTP
sudo awk '{print $9}' "$LOG" | sort | uniq -c | sort -nr

# 3. Últimos errores 5xx
sudo awk '$9 ~ /^5/' "$LOG" | tail -n 20

# 4. URLs más solicitadas
sudo awk '{print $7}' "$LOG" | sort | uniq -c | sort -nr | head

# 5. Errores 404 más frecuentes (escaneos o enlaces rotos)
sudo awk '$9==404 {print $7}' "$LOG" | sort | uniq -c | sort -nr | head
```

Para informes visuales HTML en auditorías puntuales se puede usar **GoAccess** (`sudo apt install goaccess`):

```bash
sudo goaccess /var/log/apache2/access.log --log-format=COMBINED -o /tmp/reporte.html
```

*(Si se publica el informe HTML en un directorio web, protegerlo siempre con autenticación básica según RA3 §5).*

---

## 5.3 Resolución de incidencias frecuentes (RA3 §9.4 y §10.9)

| Síntoma | Dónde mirar | Causa típica | Solución |
| :--- | :--- | :--- | :--- |
| **Timeouts (`EXIT:124`) desde `M2` al puerto `8080` o `6081` de `M1`** | Reglas del Security Group en AWS / `ss -tlnp` | Los Security Groups entre instancias AWS solo permiten `22`, `80` y `443`. | Usar el puerto `80` en el VPC entre `M2` (Varnish) y `M1` (Apache) o abrir el puerto en el Security Group. |
| **Varnish devuelve `301 Moved Permanently` hacia `https://davidservicios.ddns.net/`** | `curl -I` / `davidservicios.conf` en `M1` | El cliente envió `Host: davidservicios.ddns.net` por HTTP y Apache aplicó la regla `RewriteCond %{SERVER_NAME}`. | Mantener la normalización de `Host` en `vcl_recv` cuando llega tráfico HTTP por `davidservicios.ddns.net`. |
| **Varnish responde siempre `X-Cache: MISS` (`obj.hits = 0`)** | `curl -I` / `varnishlog` | El backend envía `Set-Cookie`, `Cache-Control: no-store/private` o faltan cabeceras de expiración. | Revisar `cache-headers.conf` en `M1` y las reglas de `vcl_backend_response` en `default.vcl`. |
| **`503 Backend fetch failed` en Varnish** | `sudo varnishadm backend.list` y `journalctl -u apache2` en `M1` | `apache2` caído en `M1`, `apache_m1` marcado `sick` por la sonda o bloqueo de red en `:80`. | Comprobar `systemctl status apache2` en `M1` y conectividad `curl -I http://172.31.16.51/`. |
| **`405 Method Not Allowed` al lanzar `PURGE`** | `default.vcl` (`acl purge_acl`) | La petición `PURGE` procede de una IP no autorizada en `purge_acl`. | Lanzar `PURGE` desde `localhost` (`M2`) o desde `172.31.16.51` (`M1`). |
| **Varnish no arranca tras editar `default.vcl` o `override.conf`** | `sudo journalctl -u varnish -n 50` | Error de sintaxis VCL o puerto `:80` ocupado por Apache en `M2`. | Validar con `varnishd -C -f /etc/varnish/default.vcl` y comprobar `ss -tlnp \| grep :80`. |
| **Apache en `M1` registra `172.31.27.180` en lugar de la IP cliente** | `/var/log/apache2/access.log` | Módulo `remoteip` deshabilitado o IP de proxy mal configurada. | Verificar `a2enmod remoteip`, `remoteip.conf` (`RemoteIPTrustedProxy 172.31.27.180`) y formato de log. |
| **`Failed requests > 0` en `ab` contra páginas dinámicas** | Salida de `ab` (`Length`) | `ab` marca como fallo cambios de longitud en respuestas variables. | Usar `-l` en `ab` si el contenido varía dinámicamente o probar recursos estáticos comparables. |

---

## 5.4 Recomendaciones de uso (RA3 §10.10)

### Para usuarios del servicio
- Acceder a la web pública por **`https://davidservicios.ddns.net/`** (conexión cifrada con certificado válido Let's Encrypt).
- Usar **`http://18.234.214.81/`** únicamente para pruebas de verificación y demostración de la caché HTTP de Varnish.
- Si el navegador muestra un aviso de certificado al entrar por IP directa (`https://13.218.219.237/`), es el comportamiento esperado porque el certificado está emitido para el nombre DNS `davidservicios.ddns.net` (SAN).

### Para administradores
- **No editar en producción sin copia previa** (`/root/backup-...`).
- **Validar siempre antes de recargar:** `apache2ctl -t` en Apache y `varnishd -C -f /etc/varnish/default.vcl` en Varnish.
- **Usar `sites-available` + `a2ensite` / `conf-available` + `a2enconf`** en lugar de modificar enlaces en `sites-enabled` o `conf-enabled`.
- **No exponer `/server-status` ni el puerto `6082` fuera de `localhost`/VPC.**
- **Mantener las pruebas `ab` separadas del nodo objetivo** y monitorizar `varnishstat` y `access.log`/`error.log` en paralelo.

---

## 5.5 Historial de cambios (RA3 §10.11)

| Fecha | Versión | Autor / Responsable | Cambios realizados |
| :--- | :--- | :--- | :--- |
| `2026-11-18` | `1.0` | David López / Asistente | Endurecimiento Apache (`M1`), activación de `mod_remoteip`, `mod_expires`/`headers` y `mod_status` restringido; reubicación de Apache `M2` a `:8080`, despliegue de Varnish `7.7.0` en `M2:80` con `default.vcl` (`probe`, `PURGE`, `X-Cache`); ejecución de pruebas cruzadas `ab` y publicación de la documentación en el repositorio `2asir`. |
