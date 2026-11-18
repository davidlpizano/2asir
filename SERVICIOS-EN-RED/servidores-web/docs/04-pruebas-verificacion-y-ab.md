# 4. Pruebas de verificación y rendimiento con `ab`

**Navegación:** [Inicio](../README.md) ·
[← Configuración de Apache y Varnish](03-configuracion-apache-y-varnish.md) ·
[Siguiente: Operación, registros e incidencias →](05-operacion-registros-e-incidencias.md)

Todas las pruebas descritas en este documento se ejecutaron sobre el entorno real desplegado el `2026-11-18`, siguiendo el método del **RA3 §8.3**: lanzar el generador de carga (`ab`) siempre **desde la otra máquina** para no medir el consumo del propio cliente y cambiar una sola variable cada vez.

---

## 4.1 Verificación funcional del backend, caché y `PURGE`

### Estado del backend en Varnish (`M2`)

```bash
sudo varnishadm backend.list
```

Salida observada:

```text
Backend name     Admin   Probe   Health    Last change
boot.apache_m1   probe   5/5     healthy   Wed, 18 Nov 2026 08:30:37 GMT
```

### Ciclo `MISS` → `HIT` e invalidación `PURGE` desde `M1`

```bash
curl -sI -X PURGE http://172.31.27.180/
curl -sI http://172.31.27.180/ | grep -iE 'HTTP/|X-Cache|Age:|X-Varnish:'
curl -sI http://172.31.27.180/ | grep -iE 'HTTP/|X-Cache|Age:|X-Varnish:'
```

Resultado real:

```http
HTTP/1.1 200 Purged
Date: Wed, 18 Nov 2026 08:31:41 GMT
Server: Varnish
X-Varnish: 2097258

# Primera petición tras PURGE:
HTTP/1.1 200 OK
X-Varnish: 2883673
Age: 0
X-Cache: MISS
X-Cache-Hits: 0

# Segunda petición (servida desde RAM de Varnish):
HTTP/1.1 200 OK
X-Varnish: 2097260 2883674
Age: 0
X-Cache: HIT
X-Cache-Hits: 1
```

### Comprobación de seguridad en `PURGE` desde IP externa

```bash
curl -sI -X PURGE http://18.234.214.81/
```

```http
HTTP/1.1 405 Method Not Allowed
Date: Wed, 18 Nov 2026 08:30:56 GMT
Server: Varnish
```

### Verificación HTTPS público (`M1`)

```bash
curl -sI https://davidservicios.ddns.net/ | grep -iE 'HTTP/|Server:|Cache-Control:|Expires:'
```

```http
HTTP/1.1 200 OK
Server: Apache
Cache-Control: public, max-age=120
Expires: Wed, 18 Nov 2026 08:33:50 GMT
```

---

## 4.2 Pruebas de carga cruzadas con ApacheBench (`ab`)

Recurso probado: `/` (`41 131 bytes`, página principal de la aplicación web).

### Comandos ejecutados

1. **Apache HTTP directo (sin Varnish)** — ejecutado desde `M2` contra `M1` (`172.31.16.51:80`):
   ```bash
   ab -n 2000 -c 50 http://172.31.16.51/
   ab -n 2000 -c 50 -k http://172.31.16.51/
   ```
2. **Apache HTTPS (coste TLS 1.3)** — ejecutado desde `M2` contra `https://davidservicios.ddns.net/`:
   ```bash
   ab -n 500 -c 20 https://davidservicios.ddns.net/
   ```
3. **A través de Varnish Cache** — ejecutado desde `M1` contra `M2` (`172.31.27.180:80`):
   ```bash
   ab -n 2000 -c 50 http://172.31.27.180/
   ab -n 2000 -c 50 -k http://172.31.27.180/
   ```

### Tabla comparativa de resultados medidos

| Escenario | Peticiones / Concurrencia | Keep-Alive | Fallos | Throughput (`req/s`) | Latencia media (`ms`) | `p50` (`ms`) | `p95` (`ms`) | `p99` (`ms`) |
| :--- | :---: | :---: | :---: | ---: | ---: | ---: | ---: | ---: |
| **1A. Apache directo HTTP** | `2000 / 50` | No | `0` | `7225.98` | `6.919` | `3` | `30` | `47` |
| **1B. Apache directo HTTP** | `2000 / 50` | Sí (`-k`) | `0` | `12416.50` | `4.027` | `1` | `20` | `39` |
| **1C. Apache HTTPS (TLS 1.3)** | `500 / 20` | No | `0` | `726.36` | `27.535` | `26` | `30` | `44` |
| **2A. Varnish Cache HTTP** | `2000 / 50` | No | `0` | `4153.34` | `12.039` | `11` | `26` | `37` |
| **2B. Varnish Cache HTTP** | `2000 / 50` | Sí (`-k`) | `0` | `5319.73` | `9.399` | `8` | `22` | `27` |

### Verificación de descarga real del backend mediante `varnishstat`

Justo después de ejecutar las 4 000 peticiones de las pruebas `2A` y `2B` sobre Varnish:

```bash
sudo varnishstat -1 | grep -E 'MAIN.client_req|MAIN.cache_hit\b|MAIN.cache_miss|MAIN.backend_req|MAIN.n_object\b|SMA.s0.g_bytes'
```

Salida observada:

```text
MAIN.client_req                     4006        77.04 Good client requests received
MAIN.cache_hit                      4002        76.96 Cache hits
MAIN.cache_miss                        3         0.06 Cache misses
MAIN.n_object                          3          .   object structs made
MAIN.backend_req                       3         0.06 Backend requests made
SMA.s0.g_bytes                            31218          .   Bytes outstanding
```

---

## 4.3 Interpretación técnica de las métricas (RA3 §8.3)

1. **Impacto del *keep-alive* (`-k`):** reutilizar conexiones TCP dispara el rendimiento en ambos casos (`+71.8 %` en Apache directo de `7225` a `12416 req/s`, y `+28.1 %` en Varnish de `4153` a `5319 req/s`) al evitar la apertura/cierre de 2 000 *sockets* efímeros.
2. **Impacto de TLS 1.3 (HTTP vs HTTPS):** sin *keep-alive*, el *handshake* TLS (`Connect` medio de `15 ms` frente a `0 ms` en HTTP) reduce las peticiones por segundo en torno a un orden de magnitud (`726 req/s` frente a `7225 req/s`).
3. **Por qué en un fichero estático pequeño `sendfile()` de Apache supera en `req/s` brutos a Varnish, pero Varnish protege al origen y mejora el `p99`:**
   - Un único fichero estático de `41 KB` permanece en la *page cache* del kernel de `M1` y Apache lo sirve mediante `sendfile()`, mientras que Varnish actúa como proceso intermedio en espacio de usuario sobre una instancia de 2 vCPU.
   - Sin embargo, `varnishstat` demuestra que **4 000 de las 4 000 peticiones de carga (`cache_hit = 4002`, `backend_req = 3`) se resolvieron sin tocar a Apache**, reduciendo además la cola de latencia extrema (`p99 = 27 ms` en Varnish `-k` frente a `39 ms` en Apache `-k`). En aplicaciones dinámicas (PHP/Python/BD), el ahorro sobre el backend sería órdenes de magnitud mayor.
4. **Limitaciones de `ab`:** `ab` es monohilo, envía HTTP/1.0 (`-k` habilita keep-alive) y no soporta HTTP/2; para saturar servidores multicore o probar HTTP/2 se recomiendan herramientas como `wrk`, `hey` u `oha`.

---

## 4.4 Comprobación de `mod_status` durante las pruebas

Desde `M2` (`172.31.27.180`, autorizada en `status.conf`):

```bash
curl -s http://172.31.16.51/server-status?auto
```

Fragmento observado tras las pruebas:

```text
ServerVersion: Apache/2.4.71 (Debian) OpenSSL/3.5.7
ServerMPM: event
Load1: 0.01
Total Accesses: 4686
Total kBytes: 190750
ReqPerSec: 1.14769
BusyWorkers: 1
IdleWorkers: 74
Scoreboard: _______W___________________________________________________________________...
```
