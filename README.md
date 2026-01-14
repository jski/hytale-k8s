# hytale-k8s

Build and run a Hytale server image with a minimal Kubernetes setup.

## Build server artifacts (optional)

This runs the amd64-only Hytale downloader in a container and writes files to `./artifacts`:

```bash
docker compose up --build
```

## Published image (GHCR)

The build workflow publishes:

- `ghcr.io/jski/hytale-server:latest`
- `ghcr.io/jski/hytale-server:v<version>`
- `ghcr.io/jski/hytale-server:build-YYYYMMDD-HHMMSS`

## Docker Compose

Create a `docker-compose.yml` like this:

```yaml
services:
  hytale-server:
    image: ghcr.io/jski/hytale-server:latest
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/hytale/data
    environment:
      JAVA_OPTS: "-Xms6G -Xmx6G"
      AOT_OPTS: "-XX:AOTCache=/hytale/data/HytaleServer.aot"
    working_dir: /hytale/data
    command: >-
      sh -lc "exec java $JAVA_OPTS $AOT_OPTS -jar /hytale/HytaleServer.jar --assets /hytale/Assets.zip"
```

Run it:

```bash
docker compose up -d
```

## First-time auth

On first start, check the logs and complete the Hytale login prompt. It will direct you to `oauth.accounts.hytale.com` for device login.

```bash
docker logs -f hytale-server
```

## Kubernetes

StorageClass note: this StatefulSet uses the cluster default StorageClass. If your cluster doesn't have a default, create one (for example `local-path`) and set it as default, or edit `k8s/statefulset.yaml` to add `storageClassName`.

Known assumptions:

- Kubernetes nodes are Linux and expose `/etc/machine-id` so auth persistence works.
- Pods have IPv6 available (dual-stack cluster setup). The server requires IPv6 sockets for QUIC.

Apply the manifests:

```bash
kubectl apply -k k8s/
```

Wait for the pod:

```bash
kubectl get pods -n hytale
```

Attach to the server console for first-time auth:

```bash
kubectl attach -it hytale-server-0 -n hytale
```

Inside the console, run:

```text
/auth login device
```

To persist auth across restarts, also run:

```text
/auth persistence Encrypted
```

Note: the Kubernetes manifest mounts `/etc/machine-id` from the node to support auth persistence. If your nodes don't have that file, remove the mount or adjust the path.

Detach without stopping the server:

```text
CTRL + P, then CTRL + Q
```

Connect to the server:

```bash
<node-public-ip>:5520
```

## First-run checklist

- Wait for the pod to be Running: `kubectl get pods -n hytale`
- Attach and authenticate: `/auth login device`
- Enable auth persistence (one-time): `/auth persistence Encrypted`
- Ensure UDP 5520 is open on the node firewall and your cloud security rules
- Connect using `<node-public-ip>:5520`

## Troubleshooting

- Pod not starting: `kubectl describe pod hytale-server-0 -n hytale` and `kubectl logs hytale-server-0 -n hytale`
- Auth prompt missing: attach again and run `/auth login device`
- Clients cannot connect: confirm the Service is UDP and that port `5520/udp` is open in firewalls/load balancers (Hytale uses QUIC over UDP)
- Wrong bind/port: update the Kubernetes `Service` and the server command if you change ports; keep UDP only

## Argo CD

Use the Application in `argocd/application.yaml` and update `repoURL`/`targetRevision` to match your fork or branch.

Apply it:

```bash
kubectl apply -f argocd/application.yaml
```

## Data migration (node to PVC) - if you already have a server running on baremetal that you're moving to k8s

1) Stop the server:

```bash
kubectl scale statefulset hytale-server -n hytale --replicas=0
```

2) Create a temporary pod that mounts the PVC:

```bash
kubectl -n hytale run hytale-data-migrator --rm -it --image=busybox --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"migrator","image":"busybox","command":["sh","-lc","sleep 3600"],"volumeMounts":[{"name":"data","mountPath":"/data"}]}],"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"hytale-data-hytale-server-0"}}]}}'
```

3) Copy your existing world data into the PVC:

```bash
kubectl -n hytale cp /path/to/world/. hytale-data-migrator:/data/universe/worlds/default/
```

4) Remove the migrator pod and start the server:

```bash
kubectl delete pod -n hytale hytale-data-migrator
kubectl scale statefulset hytale-server -n hytale --replicas=1
```
