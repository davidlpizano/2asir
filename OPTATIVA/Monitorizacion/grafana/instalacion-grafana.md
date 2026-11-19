# 2. Instalación de Grafana

Grafana permite consultar las métricas de Prometheus y representarlas mediante
paneles. Los pasos siguientes instalan Grafana en Debian o Ubuntu.

## Instalación

Añade el repositorio oficial y su clave de firma:

```bash
sudo apt install -y gpg wget
sudo install -d -m 0755 /usr/share/keyrings
wget -q -O - https://apt.grafana.com/gpg.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```

Accede a Grafana en `http://localhost:3000`. En el primer inicio de sesión,
usa `admin` como usuario y contraseña y establece una nueva contraseña cuando
te lo solicite.
