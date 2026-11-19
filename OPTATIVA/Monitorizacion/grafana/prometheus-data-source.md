# 3. Añadir Prometheus como fuente de datos en Grafana

Después de instalar Prometheus y Grafana, configura Prometheus como fuente de
datos para poder consultar sus métricas desde los paneles de Grafana.

1. Inicia sesión en Grafana en `http://localhost:3000`.
2. Ve a **Connections > Data sources > Add data source**.
3. Selecciona **Prometheus**.
4. En **Prometheus server URL**, indica `http://localhost:9090` si Grafana y
   Prometheus están instalados en la misma máquina.
5. Pulsa **Save & test** y verifica que la conexión se realiza correctamente.

En **Explore**, consulta `up` para comprobar que Grafana recibe métricas de
Prometheus.

Si Grafana y Prometheus están instalados en máquinas distintas, indica una
dirección de Prometheus accesible desde Grafana en lugar de `localhost`.
Limita el acceso a los puertos de los servicios a los equipos que los
necesiten.
