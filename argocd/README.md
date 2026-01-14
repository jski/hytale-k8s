# Argo CD

1) Update `repoURL` and `targetRevision` in `argocd/application.yaml`.
2) Apply the Application:

```bash
kubectl apply -f argocd/application.yaml
```

This deploys `k8s/` as a kustomize application into the `hytale` namespace.
