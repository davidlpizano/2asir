#!/usr/bin/env python3
import time, json

# Simula consulta a base de datos / procesamiento backend (~25 ms)
time.sleep(0.025)

payload = {
    "servicio": "PixelZenWorlds Catalogo",
    "origen": "Apache CGI Backend (172.31.16.51)",
    "items": [{"id": i, "nombre": f"Escenario-{i:03d}", "estado": "activo"} for i in range(1, 201)],
}
body = json.dumps(payload)

print("Content-Type: application/json; charset=utf-8")
print("Cache-Control: public, max-age=120")
print(f"Content-Length: {len(body.encode())}")
print()
print(body, end="")
