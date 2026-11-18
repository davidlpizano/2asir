# Servidores web en AWS: Apache 2.4, HTTPS (Certbot), Varnish Cache y pruebas con `ab`

**Documentación:**
[1. Fundamentos y arquitectura](docs/01-fundamentos-y-arquitectura.md) ·
[2. Requisitos e instalación](docs/02-requisitos-e-instalacion.md) ·
[3. Configuración de Apache y Varnish](docs/03-configuracion-apache-y-varnish.md) ·
[4. Pruebas, verificación y `ab`](docs/04-pruebas-verificacion-y-ab.md) ·
[5. Operación, registros e incidencias](docs/05-operacion-registros-e-incidencias.md)

Documentación técnica del despliegue en **dos instancias AWS EC2 (Debian 13 `trixie`)** basado en el bloque **RA3 — Servidores web** de *Servicios de Red e Internet*: servidor web **Apache 2.4** con **HTTPS (Let's Encrypt / Certbot)** y **DDNS No-IP**, proxy caché HTTP **Varnish 7.7** en una segunda máquina y batería de pruebas de carga y latencia cruzadas con **ApacheBench (`ab`)**.

> [!NOTE]
> Este apartado sigue la estructura de documentación de servicio del criterio **j (RA3 §10)**: objetivos y alcance, arquitectura, versiones exactas, instalación, configuración versionada y justificada, seguridad y custodia de certificados, pruebas de verificación y carga, operación, resolución de incidencias, recomendaciones de uso e historial de cambios.

## Resumen de nodos desplegados

| Nodo | Hostname / DNS público | IP privada VPC | Servicios activos | Puertos |
| :--- | :--- | :--- | :--- | :--- |
| **`web-apache` (`M1`)** | `davidservicios.ddns.net` (`ec2-13-218-219-237.compute-1.amazonaws.com`) | `172.31.16.51` | Apache `2.4.71`, Certbot `4.0.0`, `noip-duc`, `ab` `2.3` | `22`, `80`, `443` |
| **`varnish-cache` (`M2`)** | `ec2-18-234-214-81.compute-1.amazonaws.com` | `172.31.27.180` | Varnish `7.7.0`, Apache `2.4.69` (local en `:8080`), `ab` `2.3` | `22`, `80` (Varnish), `6081`/`6082` (locales), `8080` (Apache local) |

## Contenido del directorio

```text
servidores-web-varnish/
├── README.md
├── config/
│   ├── apache-m1/
│   │   ├── cache-headers.conf
│   │   ├── davidservicios-le-ssl.conf
│   │   ├── davidservicios.conf
│   │   ├── remoteip.conf
│   │   ├── security.conf
│   │   └── status.conf
│   ├── apache-m2/
│   │   ├── 000-default.conf
│   │   └── ports.conf
│   └── varnish-m2/
│       ├── default.vcl
│       └── varnish.override.conf
└── docs/
    ├── 01-fundamentos-y-arquitectura.md
    ├── 02-requisitos-e-instalacion.md
    ├── 03-configuracion-apache-y-varnish.md
    ├── 04-pruebas-verificacion-y-ab.md
    └── 05-operacion-registros-e-incidencias.md
```

## Recorrido recomendado

1. Revisa el objetivo, los fundamentos HTTP/TLS y la topología en [1. Fundamentos y arquitectura](docs/01-fundamentos-y-arquitectura.md).
2. Comprueba las versiones de paquetes y los pasos de despliegue en [2. Requisitos e instalación](docs/02-requisitos-e-instalacion.md).
3. Consulta los ficheros completos y su justificación en [3. Configuración de Apache y Varnish](docs/03-configuracion-apache-y-varnish.md).
4. Reproduce las comprobaciones `curl`, `PURGE`, `varnishstat` y las pruebas cruzadas de `ab` en [4. Pruebas, verificación y `ab`](docs/04-pruebas-verificacion-y-ab.md).
5. Consulta el mantenimiento diario, análisis de logs y resolución de fallos en [5. Operación, registros e incidencias](docs/05-operacion-registros-e-incidencias.md).

## Historial de cambios

| Fecha | Versión | Descripción |
| :--- | :--- | :--- |
| `2026-11-18` | `1.0` | Despliegue inicial en las dos instancias AWS (Apache endurecido + `mod_remoteip` + `mod_expires`/`headers` + `mod_status` en M1; Varnish 7.7 en `:80` y Apache en `:8080` en M2), pruebas comparativas con `ab` y documentación completa en el repositorio. |
