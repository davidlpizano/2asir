# Servicios en Red

Esta asignatura se centra en los servicios que permiten ofrecer recursos en una
red, especialmente DNS y DHCP, así como su despliegue y administración.

## Contenidos

| Recurso | Descripción |
| --- | --- |
| [Laboratorio DHCP con Kea](dhcp-kea/README.md) | Práctica de DHCPv4 con ISC Kea en alta disponibilidad (`hot-standby`), router virtual con Keepalived y NAT con nftables en Debian mediante Vagrant. |
| [Laboratorio DNS con BIND 9](dns/README.md) | Práctica de servidores DNS maestro/esclavo con BIND 9, transferencias TSIG, subdominio lógico y delegación de subdominios en Debian mediante Vagrant. |
| [Servidores web en AWS: Apache, Varnish y ab](servidores-web/README.md) | Documentación de servicio en dos instancias AWS (Debian 13) con Apache 2.4, HTTPS (Certbot + No-IP), Varnish Cache 7.7 y pruebas comparativas con `ab` (RA3). |

## Nota

El laboratorio está pensado para un entorno aislado de prácticas. Consulta sus
requisitos y advertencias antes de desplegarlo.