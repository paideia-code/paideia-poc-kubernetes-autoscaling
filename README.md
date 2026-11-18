# paideia-poc-kubernetes-autoscaling

POC para estudiar escalamiento horizontal automático de pods mediante HPA, métricas de CPU y generación de carga. Actualmente permite crear el clúster local e instalar Argo CD.

## Requisitos

- Docker en ejecución, con contenedores Linux.
- kind 0.33.0.
- kubectl.
- Helm 4.3.1.
- Bash: Linux/macOS o Git Bash en Windows.

kind crea el clúster sobre Docker. Si utilizas Docker Desktop, este clúster es independiente de su Kubernetes integrado.

## Archivos

| Archivo | Función |
| --- | --- |
| [cluster/kind.yaml](cluster/kind.yaml) | Clúster de un nodo con Kubernetes 1.36.4 e imagen fijada por digest. |
| [argocd/install/values.yaml](argocd/install/values.yaml) | Configuración local de Argo CD, incluida la contraseña de administrador. |
| [scripts/up.sh](scripts/up.sh) | Crear el clúster si falta, esperar los nodos e instalar o actualizar Argo CD con el chart 10.17.0. |

## Levantar el entorno

Desde la raíz del repositorio:

```bash
bash scripts/up.sh
```

El script reutiliza el clúster si ya existe. Los cambios en `cluster/kind.yaml` requieren recrearlo; los valores de Argo CD se aplican al repetir el script.

Comprobar:

```bash
kubectl --context kind-paideia-poc-kubernetes-autoscaling get nodes

kubectl --context kind-paideia-poc-kubernetes-autoscaling \
  -n argocd get pods
```

Se espera un nodo `Ready` y los pods de Argo CD en `Running`, con `READY 1/1`.

## Acceder a Argo CD

Ejecutar en una terminal y mantenerla abierta:

```bash
kubectl --context kind-paideia-poc-kubernetes-autoscaling \
  -n argocd port-forward svc/argocd-server 20443:443
```

Abrir [https://localhost:20443](https://localhost:20443). Credenciales de este laboratorio local: **admin / admin**. El navegador puede advertir sobre el certificado autofirmado.

`Ctrl+C` cierra el túnel; el clúster sigue funcionando.

## Bajar el clúster

```bash
kind delete cluster --name paideia-poc-kubernetes-autoscaling
```

Elimina el clúster de la POC y sus recursos y datos internos. Los archivos del repositorio se conservan. Para reconstruirlo, repetir `bash scripts/up.sh`.

La retirada requiere un único comando; no se necesita `down.sh`.
