# Kubernetes

Introducción a Kubernetes y a los conceptos básicos que se utilizan para
desplegar y administrar aplicaciones en contenedores.

## Contenidos

1. **Clúster:** conjunto de máquinas que ejecutan y gestionan las aplicaciones.
2. **Nodo:** máquina que forma parte del clúster. El plano de control coordina
   el clúster y los nodos de trabajo ejecutan las cargas.
3. **Pod:** unidad mínima desplegable de Kubernetes; agrupa uno o más
   contenedores que comparten recursos de red y almacenamiento.
4. **Deployment:** describe el estado deseado de una aplicación y permite
   mantener y actualizar sus réplicas.
5. **Service:** proporciona un punto de acceso estable para comunicarse con un
   conjunto de Pods.
6. **kubectl:** herramienta de línea de comandos para consultar y administrar
   recursos del clúster.

## Primeros comandos

```bash
# Consultar el contexto y el estado del clúster
kubectl config current-context
kubectl cluster-info

# Listar nodos y Pods
kubectl get nodes
kubectl get pods --all-namespaces
```

Los comandos requieren acceso a un clúster configurado y credenciales
adecuadas. Practica primero en un entorno local o de laboratorio.
