# paideia-poc-kubernetes-autoscaling

Laboratorio local con kind, Argo CD, Metrics Server y Nest. **Pendiente:** HPA y prueba de carga.

## Requisitos

- Docker en ejecución con contenedores Linux.
- kind 0.33.0, kubectl, Helm 4.3.1 y Bash (Git Bash en Windows).
- Internet para descargar imágenes, charts y consultar GitHub.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| [bootstrap/](bootstrap/) | Arranque del clúster e instalación de Argo CD. |
| [argocd/](argocd/) | Aplicación raíz y registro de Metrics Server y Nest. |
| [manifests/](manifests/) | Deployment y Service de Nest. |

## Ejecución

1. Desde la raíz del repositorio, ejecutar:

   ```bash
   bash bootstrap/up.sh
   ```

2. Comprobar las aplicaciones y las métricas:

   ```bash
   kubectl --context kind-paideia-poc-kubernetes-autoscaling -n argocd get applications
   kubectl --context kind-paideia-poc-kubernetes-autoscaling -n autoscaling top pods
   ```

- Esperar las tres aplicaciones en `Synced / Healthy`; las métricas pueden tardar unos instantes.
- El script reutiliza el clúster existente. Los cambios en `bootstrap/kind.yaml` requieren recrearlo.

## Acceso

Mantener cada túnel en una terminal distinta:

```bash
# Argo CD
kubectl --context kind-paideia-poc-kubernetes-autoscaling -n argocd port-forward svc/argocd-server 20443:443

# Nest
kubectl --context kind-paideia-poc-kubernetes-autoscaling -n autoscaling port-forward svc/paideia-template-nest-layered 23000:3000
```

| Servicio | Acceso |
| --- | --- |
| Argo CD | [https://localhost:20443](https://localhost:20443) · `admin` / `admin` · aceptar el certificado local. |
| Nest | `curl --fail http://localhost:23000/health` → `{"status":"ok"}`. |

`Ctrl+C` cierra el túnel. Si se reemplaza su pod, volver a ejecutar el túnel.

## Eliminar el clúster

```bash
kind delete cluster --name paideia-poc-kubernetes-autoscaling
```

Elimina sus recursos y datos internos. Para reconstruirlo: `bash bootstrap/up.sh`.
