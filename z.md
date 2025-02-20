You're right to point that out! Instead of **redefining part of the deployment**, we should **use a proper Kustomize JSON patch** or a `strategicMerge` operation that **only appends** the `phoenix` container.

---

## **1. The Correct Kustomize Patch for Adding a Container**
To **only append the `phoenix` container** without touching other parts of the deployment, we should **use a JSON patch** instead of a full YAML patch.

### **`overlays/phoenix/phoenix-additions.yaml`**
```yaml
# overlays/phoenix/phoenix-additions.yaml
- op: add
  path: /spec/template/spec/containers/-
  value:
    name: phoenix
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
### **Why This Works**
✅ **Uses `op: add` to append to the `/containers` array**  
✅ **Does not redefine the deployment**  
✅ **Minimal change, no unnecessary modifications**  

---

## **2. The Phoenix Overlay Kustomization File**
This tells Kustomize to **always include the base resources** and **apply the Phoenix patch**.

### **`overlays/phoenix/kustomization.yaml`**
```yaml
# overlays/phoenix/kustomization.yaml
resources:
  - ../../base  # Always include the base deployment

patchesJson6902:
  - target:
      version: v1
      kind: Deployment
      name: workflow-dev-env
    path: phoenix-additions.yaml
```

### **Why This Works**
✅ Uses **`patchesJson6902`**, which applies JSON-style patches correctly.  
✅ Ensures **only the container is added**, without affecting anything else.  

---

## **3. Fix `entrypoint.sh` to Apply the Right Overlay**
Modify `entrypoint.sh` to apply either the **base deployment** or the **Phoenix overlay**.

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

## **Final Behavior**
| `ENABLE_PHOENIX` | Applied Kustomization Overlay | Phoenix Container |
|------------------|-----------------------------|-------------------|
| `false` (default) | `patches/base/` | ❌ Not included |
| `true` | `patches/overlays
