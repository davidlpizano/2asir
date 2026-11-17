# Kubernetes

Kubernetes es una plataforma de orquestación de contenedores que permite
implementar, escalar y gestionar aplicaciones distribuidas de forma automatizada.

Cada apartado de este tema se encuentra en la carpeta `docs/` y se organiza por
bloques temáticos para facilitar la consulta.

## Índice

1. [Introducción](docs/1.md)
2. [Instalación](docs/2.md)
3. [Pods](docs/3.md)
4. [ReplicaSets](docs/4.md)
5. [Deployments](docs/5.md)

## Conceptos clave

- **Clúster:** conjunto de máquinas que ejecutan la infraestructura y la
  gestión de Kubernetes.
- **Nodo:** máquina del clúster que ejecuta los contenedores y workloads.
- **Pod:** unidad mínima desplegable; agrupa uno o varios contenedores que
  comparten red y almacenamiento.
- **ReplicaSet:** garantiza que siempre haya el número deseado de réplicas de
  un pod.
- **Deployment:** describe el estado deseado de una aplicación y gestiona su
  actualización y escalado.
- **Service:** expone de forma estable los pods que forman parte de una
  aplicación.
- **kubectl:** herramienta de línea de comandos para administrar el clúster.

## Primeros comandos

```bash
# Consultar el contexto y el estado del clúster
kubectl config current-context
kubectl cluster-info

# Listar nodos, Pods y despliegues
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get deployments -A
```

Los comandos requieren acceso a un clúster configurado y credenciales
adecuadas. Es recomendable practicar primero en un entorno local o de laboratorio.
