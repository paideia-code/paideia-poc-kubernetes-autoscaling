# paideia-poc-kubernetes-autoscaling

Laboratorio local con kind, Argo CD, Metrics Server y Nest para practicar escalamiento automático de 1 a 3 pods según CPU.

## Requisitos

- Docker en ejecución con contenedores Linux.
- kind 0.33.0, kubectl, Helm 4.3.1 y Bash (Git Bash en Windows).
- Internet para descargar imágenes, charts y consultar GitHub.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| [bootstrap/](bootstrap/) | Arranque del clúster e instalación de Argo CD. |
| [argocd/](argocd/) | Aplicación raíz y registro de Metrics Server y Nest. |
| [manifests/](manifests/) | Deployment, Service y HPA de Nest. |

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

## Prueba de escalamiento

1. Observar el HPA y los pods, cada comando en una terminal distinta:

   ```bash
   kubectl --context kind-paideia-poc-kubernetes-autoscaling -n autoscaling get hpa --watch
   kubectl --context kind-paideia-poc-kubernetes-autoscaling -n autoscaling get pods --watch
   ```

2. En otra terminal, generar carga sobre el Service (no necesita túnel):

   ```bash
   kubectl --context kind-paideia-poc-kubernetes-autoscaling \
     -n autoscaling run load-generator \
     --image=busybox:1.37.0 --restart=Never \
     --command -- sh -c '
       for i in 1 2 3 4 5 6 7 8; do
         (
           while true; do
             wget -q -O /dev/null http://paideia-template-nest-layered:3000/health
           done
         ) &
       done
       wait
     '
   ```

3. Tras observar el aumento de réplicas, detener la carga:

   ```bash
   kubectl --context kind-paideia-poc-kubernetes-autoscaling -n autoscaling delete pod load-generator
   ```

| Momento | Resultado esperado |
| --- | --- |
| Sin carga | Una réplica y CPU baja. |
| Con carga | Aumenta la CPU y las réplicas, hasta un máximo de tres. |
| Tras detener la carga | Baja la CPU; vuelve a una réplica después de unos cinco minutos de estabilización. |
| `TARGETS: 1%/50%` | Consumo promedio / objetivo, respecto a `requests.cpu: 100m`: aproximadamente `1m` / `50m`. |

El generador continúa hasta eliminar su pod. `Ctrl+C` solo detiene la observación de cada comando con `--watch`.

## Eliminar el clúster

```bash
kind delete cluster --name paideia-poc-kubernetes-autoscaling
```

Elimina sus recursos y datos internos. Para reconstruirlo: `bash bootstrap/up.sh`.
