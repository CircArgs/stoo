Thanks for sharing the updated directory structure and `kustomization.yaml` file. Below is the **fixed `entrypoint.sh`** and a **new Phoenix overlay** that works with the current directory layout.

---

## **1. Phoenix Overlay (To Be Created)**
We will define:
- A **Kustomization file** (`kustomization.yaml`) to apply the Phoenix container.
- A **Patch file** (`phoenix-additions.yaml`) to add the container.

### **Create `overlays/phoenix/kustomization.yaml`**
```yaml
# overlays/phoenix/kustomization.yaml
resources:
  - ../../base  # Always include the base resources

patchesStrategicMerge:
  - phoenix-additions.yaml  # Apply the Phoenix container patch
```

---

### **Create `overlays/phoenix/phoenix-additions.yaml`**
This adds the `arize/phoenix` container **only** when applied.

```yaml
# overlays/phoenix/phoenix-additions.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workflow-dev-env
spec:
  template:
    spec:
      containers:
        - name: phoenix
          image: arize/phoenix:latest
          env:
            - name: ENABLE_PHOENIX
              value: "true"
          command: ["/bin/sh", "-c"]
          args:
            - |
              if [ "$ENABLE_PHOENIX" = "true" ]; then
                echo "Starting Phoenix..."
                exec phoenix
              else
                echo "Skipping Phoenix container..."
                sleep infinity
              fi
```

---

## **2. Fix `entrypoint.sh`**
Now, we need to modify `entrypoint.sh` so that it:
- **Always applies the base Kustomization**.
- **Only applies the Phoenix overlay if `ENABLE_PHOENIX=true`**.

### **Updated `entrypoint.sh`**
```bash
#!/usr/bin/env bash
set -xe  # Fail fast

# Copy workflow values
cp /app/workflow-values.yaml /tmp/workflow-values.yaml

# Download & Extract Helm Package
cd /tmp
curl -O "https://artifactory.cloud.capitalone.com/artifactory/helm-shared/genai-kubernetes-platform/${WORKFLOWS_HUB}"
tar -xvf genai-workflows-application.tgz --no-same-owner

# Apply Patches
python3 /app/scripts/patches/patch_values.py workflow-values.yaml
python3 /app/scripts/patches/patch_cron.py genai-workflows-application/templates/dev-env-cron.yaml

# Determine which Kustomization overlay to apply
if [ "$ENABLE_PHOENIX" = "true" ]; then
    echo "Applying Phoenix overlay..."
    kubectl kustomize /app/patches/overlays/phoenix --enable-helm > /tmp/genai-workflows-application.yaml
else
    echo "Applying base overlay..."
    kubectl kustomize /app/patches/base --enable-helm > /tmp/genai-workflows-application.yaml
fi

# Deploy
kubectl apply -n "$NAMESPACE" -f /tmp/genai-workflows-application.yaml
```

---

## **How This Works**
| `ENABLE_PHOENIX` | Applied Kustomization Overlay | Phoenix Container |
|------------------|-----------------------------|-------------------|
| `false` (default) | `patches/base/` | ❌ Not included |
| `true` | `patches/overlays/phoenix/` | ✅ Included |

---

## **Key Benefits**
✅ **Modular**: The Phoenix container is optional and separate.  
✅ **Maintains existing patches**: Always applies the `base` patches.  
✅ **Easy to extend**: New overlays can be added in the future.  
✅ **No unnecessary patches**: Only applies `phoenix-additions.yaml` when needed.  

---

### **Next Steps**
- **Create the `overlays/phoenix/` directory** and add the `kustomization.yaml` and `phoenix-additions.yaml` files.
- **Replace `entrypoint.sh` with the updated version**.

This setup is **clean, scalable, and follows Kubernetes best practices**. 🚀  
Let me know if you need any tweaks!
