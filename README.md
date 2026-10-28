# Kubernetes & AKS Interview Questions & Answers

A quick-reference guide covering core Kubernetes concepts, `kubectl` commands, and **Azure Kubernetes Service (AKS)** — useful for interview prep or as a working cheat sheet.

> Based on [gauri17-pro/kubernetes-interview-questions](https://github.com/gauri17-pro/kubernetes-interview-questions), extended with AKS content, corrected examples, and additional topics.

## Table of Contents

**Core Kubernetes**

1. [Kubernetes Architecture](#1-kubernetes-architecture)
2. [Init Containers](#2-init-containers)
3. [Pods](#3-pods)
4. [Describe Pod vs Inspect Pod](#4-describe-pod-vs-inspect-pod)
5. [Managing Labels](#5-managing-labels)
6. [Namespaces](#6-namespaces)
7. [Kubernetes Services](#7-kubernetes-services)
8. [ReplicationController vs ReplicaSet](#8-replicationcontroller-vs-replicaset)
9. [Deployments](#9-deployments)
10. [ResourceQuota](#10-resourcequota)
11. [LimitRange](#11-limitrange)
12. [ConfigMap](#12-configmap)
13. [Taints and Tolerations](#13-taints-and-tolerations)
14. [Node Affinity](#14-node-affinity)
15. [Volumes](#15-volumes)
16. [Kubernetes Secrets](#16-kubernetes-secrets)
17. [StatefulSet, DaemonSet, Job & CronJob](#17-statefulset-daemonset-job--cronjob)
18. [Probes](#18-probes)
19. [Ingress](#19-ingress)
20. [RBAC](#20-rbac)
21. [Network Policies](#21-network-policies)
22. [Autoscaling (HPA, VPA, Cluster Autoscaler)](#22-autoscaling)
23. [PodDisruptionBudget](#23-poddisruptionbudget)
24. [Troubleshooting Cheat Sheet](#24-troubleshooting-cheat-sheet)

**Azure Kubernetes Service (AKS)**

25. [What is AKS?](#25-what-is-aks)
26. [AKS Architecture](#26-aks-architecture)
27. [Creating & Managing an AKS Cluster](#27-creating--managing-an-aks-cluster)
28. [Node Pools (System, User, Spot)](#28-node-pools-system-user-spot)
29. [AKS Networking](#29-aks-networking)
30. [AKS Services & Ingress](#30-aks-services--ingress)
31. [AKS Storage](#31-aks-storage)
32. [AKS Identity & Access (Entra ID, Managed Identity, Workload Identity)](#32-aks-identity--access)
33. [Secrets with Azure Key Vault](#33-secrets-with-azure-key-vault)
34. [Azure Container Registry (ACR) Integration](#34-azure-container-registry-acr-integration)
35. [AKS Scaling & Autoscaling (incl. KEDA)](#35-aks-scaling--autoscaling)
36. [AKS Upgrades & Maintenance](#36-aks-upgrades--maintenance)
37. [AKS Monitoring & Logging](#37-aks-monitoring--logging)
38. [AKS Security & Governance](#38-aks-security--governance)
39. [AKS High Availability & Cost Optimization](#39-aks-high-availability--cost-optimization)
40. [AKS vs EKS vs GKE](#40-aks-vs-eks-vs-gke)
41. [Scenario-Based AKS Interview Questions](#41-scenario-based-aks-interview-questions)

---

# Part 1 — Core Kubernetes

## 1. Kubernetes Architecture

Kubernetes follows a **control plane / worker node** model.

**Control Plane components:**

- **kube-apiserver** — Front end of the control plane. Exposes the Kubernetes API, handles authentication, authorization, and admission control.
- **kube-scheduler** — Decides which node each new pod runs on (based on resources, affinity, taints, etc.).
- **kube-controller-manager** — Runs controllers that drive the actual state toward the desired state (Node, ReplicaSet, Deployment, Job controllers, etc.).
- **etcd** — Consistent key-value store holding all cluster state and configuration.
- **cloud-controller-manager** — Integrates with the cloud provider (load balancers, routes, node lifecycle). In AKS this is managed by Azure.

**Worker Node components:**

- **kubelet** — Agent that ensures containers described in PodSpecs are running and healthy.
- **Container runtime** — Runs containers (containerd in AKS).
- **kube-proxy** — Maintains network rules on nodes to implement Services.
- **Pods** — Smallest deployable units in Kubernetes.

> **AKS note:** In AKS, Microsoft manages the entire control plane (API server, scheduler, controller manager, etcd). You only manage and pay for the worker nodes (plus optional paid tiers for the control plane SLA). See [AKS Architecture](#26-aks-architecture).

---

## 2. Init Containers

Init containers run to completion, **in order, before** the app containers start. Typical uses: waiting for a dependency, running DB migrations, fetching config or secrets, setting file permissions.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  initContainers:
  - name: wait-for-db
    image: busybox:1.36
    command: ['sh', '-c', 'until nslookup db-service; do echo waiting for db; sleep 2; done']
  containers:
  - name: main-container
    image: nginx:1.27
```

**Key points:**

- Each init container must succeed before the next one starts; if one fails, the pod restarts it (per `restartPolicy`).
- Init containers can use different images/tools than the app container and can share volumes with it.
- They do **not** support readiness/liveness probes.
- Resource requests/limits for scheduling use the *highest* init container request vs. the *sum* of app containers.

---

## 3. Pods

A pod is the smallest deployable object in Kubernetes — one or more tightly coupled containers sharing network (one IP) and storage.

```bash
# Create a Pod (imperative)
kubectl run <pod-name> --image=<container-image>

# Generate YAML without creating
kubectl run <pod-name> --image=nginx --dry-run=client -o yaml > pod.yaml

# List Pods (with node and IP)
kubectl get pods -o wide

# Describe a Pod
kubectl describe pod <pod-name>

# Delete a Pod
kubectl delete pod <pod-name>

# Execute a command in a Pod
kubectl exec -it <pod-name> -- <command>

# Execute in a specific container
kubectl exec -it <pod-name> -c <container-name> -- <command>

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<remote-port>

# Logs (current, previous crashed container, follow, specific container)
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl logs -f <pod-name> -c <container-name>

# Attach to a running container
kubectl attach -it <pod-name> -c <container-name>

# Copy files from / to a Pod
kubectl cp <pod-name>:/remote/path /local/path
kubectl cp /local/path <pod-name>:/remote/path

# Get Pod IP / YAML
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'
kubectl get pod <pod-name> -o yaml
```

**Pod lifecycle phases:** `Pending` → `Running` → `Succeeded` / `Failed` (and `Unknown` if the node is unreachable).

---

## 4. Describe Pod vs Inspect Pod

- `kubectl describe pod <pod-name>` shows configuration, status, conditions, and recent **events** (very useful for scheduling and image-pull errors).
- "Inspect" is not a `kubectl` command. It's an informal term (and a `docker inspect` command) for examining a resource — in Kubernetes use `describe`, `get -o yaml`, or `logs`.

---

## 5. Managing Labels

```bash
# Show labels
kubectl get pods --show-labels

# Add / update a label
kubectl label pod <pod-name> <key>=<value>
kubectl label pod <pod-name> <key>=<new-value> --overwrite

# Remove a label
kubectl label pod <pod-name> <key>-

# Filter by label / selector
kubectl get pods -l <key>=<value>
kubectl get pods -l 'env in (dev,qa)'

# Label many pods at once
kubectl label pod -l <selector> <key>=<value>

# Nodes
kubectl label node <node-name> <key>=<value>
kubectl get nodes --show-labels
kubectl label node <node-name> <key>-

# Namespaces
kubectl label namespace <ns> <key>=<value>
kubectl get namespaces --show-labels
```

**Labels vs Annotations:** labels are for selecting/grouping objects; annotations store non-identifying metadata (tool config, build info, cloud-provider settings such as AKS load balancer annotations).

---

## 6. Namespaces

Namespaces partition a cluster into virtual clusters for isolation, quotas, and access control.

| Namespace | Purpose |
|---|---|
| `default` | Default namespace for objects with none specified |
| `kube-public` | Readable by all users (including unauthenticated); rarely used |
| `kube-system` | System components (CoreDNS, kube-proxy, metrics-server; in AKS also `azure-*`, `cloud-node-manager`, CSI drivers) |
| `kube-node-lease` | Node heartbeat Lease objects |

```bash
kubectl create namespace <name>
kubectl get namespaces
kubectl config set-context --current --namespace=<name>
kubectl delete namespace <name>     # deletes everything inside it
kubectl get pods -n <name>
kubectl get pods -A                 # all namespaces
```

> Not every resource is namespaced — nodes, PersistentVolumes, StorageClasses, and ClusterRoles are cluster-scoped. Check with `kubectl api-resources --namespaced=false`.

---

## 7. Kubernetes Services

A Service gives a stable virtual IP and DNS name to a dynamic set of pods selected by labels. Types: **ClusterIP**, **NodePort**, **LoadBalancer**, **ExternalName** (plus Headless).

```bash
kubectl apply -f service.yaml
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints <service-name>       # or: kubectl get endpointslices
kubectl expose deployment <name> --type=NodePort --port=80 --target-port=8080
kubectl delete service <service-name>
```

### ClusterIP (default)
Internal-only virtual IP.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

### NodePort
Opens a static port (30000–32767) on every node, in addition to a ClusterIP.

```yaml
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080   # optional
```

### LoadBalancer
Provisions a cloud load balancer (Azure Load Balancer on AKS, ELB on EKS) in front of the service. See [AKS Services & Ingress](#30-aks-services--ingress).

```yaml
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

### ExternalName
Maps a service name to an external DNS name (a CNAME) — no proxying.

```yaml
spec:
  type: ExternalName
  externalName: mydb.database.windows.net
```

### Headless Service
`clusterIP: None` — DNS returns the individual pod IPs. Used with StatefulSets.

```yaml
spec:
  clusterIP: None
  selector:
    app: my-app
  ports:
  - port: 80
```

---

## 8. ReplicationController vs ReplicaSet

Both keep a specified number of pod replicas running.

| Feature | ReplicationController | ReplicaSet |
|---|---|---|
| API version | `v1` | `apps/v1` |
| Selector | Equality-based only (`app=web`) | Equality- and set-based (`matchLabels`, `matchExpressions`) |
| Status | Legacy / superseded | Current; the recommended replacement |
| Rolling updates | Only via the legacy `kubectl rolling-update` (removed) | Not itself, but managed by a **Deployment**, which creates a new ReplicaSet per revision |
| Direct use | Rarely | Rarely directly; normally created by Deployments |
| Ownership tracking | `ownerReferences` | `ownerReferences` |

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: nginx:1.27
        ports:
        - containerPort: 80
```

---

## 9. Deployments

A Deployment declaratively manages ReplicaSets and gives rolling updates, rollbacks, and scaling for stateless apps.

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=3
kubectl scale deployment web --replicas=5
kubectl set image deployment/web nginx=nginx:1.28
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl rollout restart deployment/web
```

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
```

**Built-in strategies:** `RollingUpdate` (default) and `Recreate` (downtime, kills all old pods first).

**Release patterns (implemented with extra tooling or manifests):**

- **Blue-Green** — Two environments; switch the Service selector or ingress to the new one. Fast rollback, double the resources.
- **Canary** — Send a small share of traffic to the new version first (Argo Rollouts, Flagger, service mesh, or ingress traffic splitting).
- **A/B testing** — Route by header/cookie/user segment.
- **Multi-cluster** — Roll out across clusters/regions with GitOps (Flux — built into AKS as an extension — or Argo CD) or Azure Fleet Manager.

---

## 10. ResourceQuota

Limits aggregate resource consumption **per namespace**.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
```

```bash
kubectl describe resourcequota -n team-a
```

> If a quota covers CPU/memory, every pod in the namespace must declare requests/limits (or a LimitRange must supply defaults), otherwise pod creation is rejected.

---

## 11. LimitRange

Sets **per-container / per-pod** defaults and min/max constraints inside a namespace.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: example-limit-range
  namespace: team-a
spec:
  limits:
  - type: Container
    max:
      memory: 1Gi
      cpu: 500m
    min:
      memory: 64Mi
      cpu: 50m
    default:             # default LIMIT applied if none specified
      memory: 512Mi
      cpu: 250m
    defaultRequest:      # default REQUEST applied if none specified
      memory: 256Mi
      cpu: 100m
```

**ResourceQuota vs LimitRange:** quota caps the *total* for a namespace; LimitRange constrains each *individual* object.

---

## 12. ConfigMap

Decouples non-sensitive configuration from container images.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-configmap
data:
  app.properties: |
    app.debug=true
    app.max_connections=100
  LOG_LEVEL: info
```

> Never put passwords or keys in a ConfigMap — use a [Secret](#16-kubernetes-secrets) (or [Azure Key Vault](#33-secrets-with-azure-key-vault) on AKS).

```bash
kubectl create configmap <name> --from-literal=key1=value1 --from-literal=key2=value2
kubectl create configmap <name> --from-file=<path/to/file>
kubectl create configmap <name> --from-file=<path/to/directory>
kubectl get configmaps
kubectl describe configmap <name>
kubectl edit configmap <name>
kubectl delete configmap <name>
kubectl get configmap <name> -o yaml
```

**Consuming a ConfigMap:**

```yaml
# 1) All keys as environment variables
envFrom:
- configMapRef:
    name: example-configmap

# 2) A single key as an environment variable
env:
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: example-configmap
      key: LOG_LEVEL

# 3) Mounted as files
spec:
  containers:
  - name: mycontainer
    image: myimage
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: example-configmap
```

**Interview tip:** mounted ConfigMaps are updated automatically in the pod (eventually, except `subPath` mounts); environment variables are **not** updated until the pod restarts.

---

## 13. Taints and Tolerations

- **Taints** are set on nodes and repel pods that don't tolerate them.
- **Tolerations** are set on pods and *allow* (not force) scheduling onto tainted nodes.

```bash
kubectl taint nodes <node-name> key=value:NoSchedule
kubectl taint nodes <node-name> key=value:NoSchedule-     # remove
```

```yaml
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

**Effects:**

- **NoSchedule** — New pods without a matching toleration are not scheduled.
- **PreferNoSchedule** — Soft version; scheduler tries to avoid the node.
- **NoExecute** — Also evicts already-running pods that don't tolerate it.

> **AKS examples:** spot node pools get the taint `kubernetes.azure.com/scalesetpriority=spot:NoSchedule` automatically, and dedicated system pools are commonly tainted `CriticalAddonsOnly=true:NoSchedule`. See [Node Pools](#28-node-pools-system-user-spot).

> Taints/tolerations only **repel**. To *attract* a pod to specific nodes, combine them with node affinity or `nodeSelector`.

---

## 14. Node Affinity

Schedules pods onto nodes based on node labels (more expressive than `nodeSelector`).

### `requiredDuringSchedulingIgnoredDuringExecution` (hard rule)

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.azure.com/agentpool
            operator: In
            values:
            - userpool1
```

### `preferredDuringSchedulingIgnoredDuringExecution` (soft rule)

```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - eastus-1
```

"IgnoredDuringExecution" means rules are evaluated only at scheduling time — pods are not moved if node labels change later.

**Related:** `podAffinity` / `podAntiAffinity` (co-locate or spread pods) and `topologySpreadConstraints` (even spread across zones/nodes).

---

## 15. Volumes

### emptyDir
Created when a pod is assigned to a node; deleted when the pod is removed. Used for scratch space or sharing data between containers in a pod. Survives container restarts, not pod deletion.

```yaml
volumes:
- name: shared-data
  emptyDir: {}
```

### hostPath
Mounts a path from the node's filesystem. Avoid in production — it ties pods to a node and is a security risk.

```yaml
volumes:
- name: host-path
  hostPath:
    path: /var/log
```

### PersistentVolume (PV) and PersistentVolumeClaim (PVC)
A **PV** is a piece of storage in the cluster (provisioned by an admin or dynamically via a **StorageClass**). A **PVC** is a user's request for storage that binds to a matching PV.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: <storage-class>
  resources:
    requests:
      storage: 5Gi
```

**Access modes:** `ReadWriteOnce` (RWO), `ReadOnlyMany` (ROX), `ReadWriteMany` (RWX), `ReadWriteOncePod` (RWOP).
**Reclaim policies:** `Retain`, `Delete` (default for dynamically provisioned), `Recycle` (deprecated).

### Amazon EKS volumes (CSI drivers)

> The legacy in-tree `awsElasticBlockStore` plugin has been removed; use the **EBS CSI driver** and **EFS CSI driver**.

**EBS (RWO):**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 5Gi
```

**EFS (RWX):**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: <EFS_FILE_SYSTEM_ID>
  directoryPerms: "700"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes: [ReadWriteMany]
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

For **Azure** equivalents (Azure Disk, Azure Files, Blob), see [AKS Storage](#31-aks-storage).

---

## 16. Kubernetes Secrets

Secrets hold small amounts of sensitive data (passwords, tokens, keys, TLS certs).

- **Base64 is encoding, not encryption.** Anyone with API/etcd access can decode it.
- **Encryption at rest** for etcd must be enabled/configured (in AKS, etcd data is encrypted at rest by the platform; you can additionally use KMS etcd encryption with your own key in Azure Key Vault).
- **Access control** — restrict `get/list/watch` on secrets with RBAC; `list` effectively reveals values.
- **Consumption** — as environment variables or mounted files (files are preferable; they update and don't leak via `env`/process dumps as easily).
- **Immutable Secrets** — set `immutable: true` to prevent changes (protects against accidental edits and reduces API server load). By default Secrets *can* be updated.
- **Best practice** — keep real secrets in an external store (Azure Key Vault, AWS Secrets Manager, HashiCorp Vault) and sync them with the Secrets Store CSI driver or External Secrets Operator.

**Common types:** `Opaque` (default), `kubernetes.io/tls`, `kubernetes.io/dockerconfigjson`, `kubernetes.io/basic-auth`, `kubernetes.io/ssh-auth`, `kubernetes.io/service-account-token`.

```bash
kubectl create secret generic <name> --from-literal=<key>=<value>
kubectl create secret generic <name> --from-file=<path_to_file>
kubectl create secret tls <name> --cert=<cert_file> --key=<key_file>
kubectl create secret docker-registry <name> \
  --docker-server=<server> --docker-username=<user> --docker-password=<pass> --docker-email=<email>

kubectl get secrets
kubectl describe secret <name>
kubectl get secret <name> -o jsonpath="{.data.<key>}" | base64 --decode
kubectl delete secret <name>
```

```yaml
# As a volume
volumes:
- name: secret-vol
  secret:
    secretName: <secret_name>

# As an environment variable
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: <secret_name>
      key: password
```

---

## 17. StatefulSet, DaemonSet, Job & CronJob

| Workload | Purpose | Key traits |
|---|---|---|
| **Deployment** | Stateless apps | Interchangeable pods, rolling updates |
| **StatefulSet** | Stateful apps (databases, Kafka) | Stable names (`app-0`, `app-1`), stable storage per pod (`volumeClaimTemplates`), ordered start/stop, needs a headless Service |
| **DaemonSet** | One pod per node (or subset) | Log shippers, monitoring agents, CNI/CSI plugins |
| **Job** | Run-to-completion task | `completions`, `parallelism`, `backoffLimit` |
| **CronJob** | Scheduled Jobs | Cron syntax, `concurrencyPolicy` |

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: web-headless
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 1Gi
```

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-report
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: report
            image: busybox:1.36
            command: ["sh", "-c", "echo generating report"]
```

---

## 18. Probes

| Probe | Question it answers | On failure |
|---|---|---|
| **Liveness** | Is the container still working? | Container is restarted |
| **Readiness** | Is it ready to receive traffic? | Removed from Service endpoints (not restarted) |
| **Startup** | Has the app finished starting? | Disables other probes until it passes; restarts if it never does |

```yaml
containers:
- name: app
  image: myapp:1.0
  startupProbe:
    httpGet: { path: /healthz, port: 8080 }
    failureThreshold: 30
    periodSeconds: 5
  readinessProbe:
    httpGet: { path: /ready, port: 8080 }
    periodSeconds: 5
  livenessProbe:
    httpGet: { path: /healthz, port: 8080 }
    initialDelaySeconds: 10
    periodSeconds: 10
```

Probe mechanisms: `httpGet`, `tcpSocket`, `exec`, `grpc`.

---

## 19. Ingress

An Ingress routes external HTTP/HTTPS traffic to Services (host- and path-based routing, TLS termination). It requires an **Ingress controller** (NGINX, Traefik, Application Gateway, etc.). The newer **Gateway API** is its successor.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts: [app.example.com]
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

For AKS ingress options (application routing add-on, Application Gateway for Containers), see [AKS Services & Ingress](#30-aks-services--ingress).

---

## 20. RBAC

Role-Based Access Control decides **who** (subject) can do **what** (verbs on resources) and **where** (namespace/cluster).

| Object | Scope |
|---|---|
| `Role` / `RoleBinding` | Namespace |
| `ClusterRole` / `ClusterRoleBinding` | Cluster-wide |

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: dev
  name: read-pods
subjects:
- kind: User            # or Group / ServiceAccount
  name: jane@contoso.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl auth can-i create deployments -n dev
kubectl auth can-i list secrets --as jane@contoso.com -n dev
```

AKS integrates RBAC with **Microsoft Entra ID** — see [AKS Identity & Access](#32-aks-identity--access).

---

## 21. Network Policies

By default all pods can talk to all pods. A `NetworkPolicy` restricts traffic (needs a CNI that enforces it — on AKS: Azure Network Policy Manager, Calico, or Cilium).

```yaml
# Deny all ingress in a namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: prod
spec:
  podSelector: {}
  policyTypes: [Ingress]
---
# Allow frontend -> backend on 8080
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

---

## 22. Autoscaling

| Scaler | What it scales | Based on |
|---|---|---|
| **HPA** (Horizontal Pod Autoscaler) | Number of pod replicas | CPU, memory, custom/external metrics |
| **VPA** (Vertical Pod Autoscaler) | Pod CPU/memory requests | Observed usage |
| **Cluster Autoscaler** | Number of nodes | Pending (unschedulable) pods / underused nodes |
| **KEDA** | Pods, event-driven (including to/from zero) | Queues, event hubs, cron, Prometheus, etc. |

```bash
kubectl autoscale deployment web --cpu-percent=70 --min=2 --max=10
kubectl get hpa
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

> HPA needs **metrics-server** (preinstalled in AKS) and pods must define CPU/memory **requests**.

---

## 23. PodDisruptionBudget

Limits how many pods of an app can be voluntarily disrupted at once (node drains, cluster upgrades, autoscaler scale-down).

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2          # or maxUnavailable: 1
  selector:
    matchLabels:
      app: web
```

> Important on AKS: a too-strict PDB (e.g. `maxUnavailable: 0`) can block node upgrades and drains.

---

## 24. Troubleshooting Cheat Sheet

| Symptom | Common causes | Commands |
|---|---|---|
| `Pending` | Insufficient resources, taints, unbound PVC, affinity mismatch | `kubectl describe pod`, `kubectl get events --sort-by=.lastTimestamp` |
| `ImagePullBackOff` / `ErrImagePull` | Wrong image/tag, missing registry credentials, ACR not attached | `kubectl describe pod`, check imagePullSecrets / `az aks check-acr` |
| `CrashLoopBackOff` | App crash, bad config, failing liveness probe | `kubectl logs <pod> --previous` |
| `OOMKilled` | Memory limit too low | `kubectl describe pod` (Last State), raise limit |
| `CreateContainerConfigError` | Missing ConfigMap/Secret/key | `kubectl describe pod` |
| Service not reachable | Selector/label mismatch, wrong `targetPort`, no ready endpoints | `kubectl get endpoints`, `kubectl describe svc` |
| Node `NotReady` | Kubelet/network/disk issue | `kubectl describe node`, `kubectl get nodes -o wide` |

```bash
kubectl get events -A --sort-by=.lastTimestamp
kubectl top nodes
kubectl top pods -A
kubectl debug node/<node-name> -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0
kubectl run tmp --rm -it --image=busybox:1.36 -- sh     # test DNS/connectivity from inside the cluster
```

---

# Part 2 — Azure Kubernetes Service (AKS)

## 25. What is AKS?

**Azure Kubernetes Service (AKS)** is Azure's managed Kubernetes offering. Azure runs and maintains the control plane for you (API server, etcd, scheduler, controller manager) — you manage the worker nodes' pools and your workloads.

**Why use AKS?**

- No control plane to build, patch, or back up.
- Native integration with Azure services: Entra ID, Azure Monitor, ACR, Key Vault, Azure Policy, Azure Load Balancer/Application Gateway, Azure Disks/Files.
- Built-in autoscaling, upgrades, auto-repair of nodes, availability zones.
- Free tier for dev/test and a paid Standard/Premium tier with an uptime SLA.

**Cluster tiers:**

| Tier | Use |
|---|---|
| **Free** | Dev/test; no financially backed uptime SLA; limited control plane resources |
| **Standard** | Production; uptime SLA (higher with availability zones), more control-plane capacity |
| **Premium** | Standard plus long-term support (LTS) for Kubernetes versions |

---

## 26. AKS Architecture

**Azure-managed (control plane):** kube-apiserver, etcd, kube-scheduler, kube-controller-manager, cloud-controller-manager. Hosted in a Microsoft-managed subscription/VNet.

**Customer-managed (data plane):**

- **Node pools** — Groups of VMs (Azure Virtual Machine Scale Sets, or availability sets in old clusters) running kubelet and containerd.
- **Node resource group** — An auto-created group (default name `MC_<rg>_<cluster>_<region>`) that holds the cluster's VMSS, load balancer, public IPs, NSGs, managed disks, and VNet (if not BYO). **Don't modify it manually.**
- **Your workloads** — Pods, Services, etc.

**Control plane ↔ nodes:** the API server reaches nodes through a secure tunnel (konnectivity). Clusters can be **public** or **private** (API server exposed only through a private endpoint in your VNet).

**Common interview question — "Who is responsible for what?"**

| Azure | You |
|---|---|
| Control plane availability, patching, etcd backup | Workload design, pod security, RBAC |
| Kubernetes version support & node image availability | Choosing when to upgrade clusters and node images |
| Node OS image patches made available | Applying node image upgrades (or enabling auto-upgrade channels) |

---

## 27. Creating & Managing an AKS Cluster

```bash
# Login & subscription
az login
az account set --subscription <subscription-id>

# Resource group
az group create --name myRG --location eastus

# Create a production-style cluster
az aks create \
  --resource-group myRG \
  --name myAKS \
  --tier standard \
  --node-count 3 \
  --zones 1 2 3 \
  --enable-managed-identity \
  --network-plugin azure --network-plugin-mode overlay \
  --enable-cluster-autoscaler --min-count 3 --max-count 6 \
  --enable-oidc-issuer --enable-workload-identity \
  --generate-ssh-keys

# Get kubeconfig credentials
az aks get-credentials --resource-group myRG --name myAKS

# Inspect the cluster
az aks show -g myRG -n myAKS -o table
az aks list -o table

# Scale the default node pool manually
az aks scale -g myRG -n myAKS --node-count 5

# Stop / start the cluster (saves cost in dev/test)
az aks stop  -g myRG -n myAKS
az aks start -g myRG -n myAKS

# Delete
az aks delete -g myRG -n myAKS --yes --no-wait
```

> Flag names and defaults evolve — verify with `az aks create --help` for your CLI version.

**Other ways to create AKS:** Azure Portal, Bicep/ARM, Terraform (`azurerm_kubernetes_cluster`), Pulumi, and AKS Automatic (preconfigured, opinionated production setup).

---

## 28. Node Pools (System, User, Spot)

| Pool type | Purpose |
|---|---|
| **System node pool** | Hosts critical system pods (CoreDNS, metrics-server, konnectivity). Every cluster needs at least one (min 1 node; 3 recommended for production). Must be Linux. |
| **User node pool** | Hosts your application workloads. Can be Linux or Windows, different VM sizes, GPU, etc. |
| **Spot node pool** | User pool using Azure Spot VMs — much cheaper but can be evicted; for batch / fault-tolerant jobs. |

```bash
# Add a user node pool
az aks nodepool add -g myRG --cluster-name myAKS -n userpool1 \
  --node-count 3 --node-vm-size Standard_D4s_v5 --mode User \
  --labels workload=apps

# Add a spot node pool
az aks nodepool add -g myRG --cluster-name myAKS -n spotpool \
  --priority Spot --eviction-policy Delete --spot-max-price -1 \
  --enable-cluster-autoscaler --min-count 0 --max-count 5 --node-count 1

# Dedicate the system pool to system pods only
az aks nodepool update -g myRG --cluster-name myAKS -n nodepool1 \
  --node-taints CriticalAddonsOnly=true:NoSchedule

# Scale / delete
az aks nodepool scale  -g myRG --cluster-name myAKS -n userpool1 --node-count 5
az aks nodepool delete -g myRG --cluster-name myAKS -n userpool1
```

**Scheduling onto a specific pool:**

```yaml
spec:
  nodeSelector:
    kubernetes.azure.com/agentpool: userpool1
```

**Scheduling onto spot nodes** (spot nodes carry the taint `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`):

```yaml
spec:
  tolerations:
  - key: kubernetes.azure.com/scalesetpriority
    operator: Equal
    value: spot
    effect: NoSchedule
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.azure.com/scalesetpriority
            operator: In
            values: ["spot"]
```

**Interview Q: Why separate system and user pools?** To isolate critical cluster components from application load (noisy neighbors), size them independently, and apply different upgrade/scale policies.

---

## 29. AKS Networking

### Network plugins / models

| Model | How pods get IPs | Notes |
|---|---|---|
| **kubenet** (legacy) | Pods get IPs from a separate private CIDR, NATed behind the node; uses route tables | Simple, saves VNet IPs, but limited features and being retired in favor of overlay |
| **Azure CNI (Node Subnet)** | Pods get IPs directly from the VNet subnet | Pods are first-class VNet citizens; consumes many VNet IPs — plan subnet size |
| **Azure CNI Overlay** | Pods get IPs from a private overlay CIDR; nodes use VNet IPs | Scales to large clusters with minimal VNet IP use; **recommended default** for most new clusters |
| **Azure CNI with Dynamic IP allocation** | Pod IPs allocated from a dedicated pod subnet | Better IP utilization than node-subnet mode |
| **Azure CNI Powered by Cilium** | eBPF data plane with Azure CNI | Advanced network policy, observability, performance |

### Network policy engines
Azure Network Policy Manager, Calico, or Cilium (depending on CNI choice).

### Private clusters
The API server gets a private endpoint, reachable only inside the VNet (or peered/connected networks).

```bash
az aks create -g myRG -n myPrivateAKS --enable-private-cluster ...
```

### Outbound (egress) types

- **Load Balancer** (default) — SNAT through the cluster's Standard Load Balancer public IP(s).
- **NAT Gateway** — More SNAT ports; predictable outbound IP.
- **User-defined routing (UDR)** — Force egress through Azure Firewall / NVA.

### DNS
CoreDNS is used in-cluster. Services resolve as `<svc>.<namespace>.svc.cluster.local`.

**Common interview questions:**

- *Kubenet vs Azure CNI?* Kubenet is simpler/uses fewer IPs but has NAT/route-table limits; Azure CNI gives pods VNet-routable IPs (or overlay for scale).
- *What happens if the subnet is too small with Azure CNI (node subnet)?* Scale-out and upgrades fail because there aren't enough IPs (max pods per node × nodes + surge nodes).
- *How do you restrict outbound traffic?* UDR + Azure Firewall, plus Kubernetes NetworkPolicies for pod-level control.

---

## 30. AKS Services & Ingress

### LoadBalancer on AKS
Creating a `Service` of type `LoadBalancer` provisions a frontend IP and rules on the cluster's **Azure Standard Load Balancer**.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-public
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

### Internal load balancer (private IP in the VNet)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-internal
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    # Optional: choose a subnet
    # service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "apps-subnet"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

### Static public IP

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: myRG
    service.beta.kubernetes.io/azure-pip-name: myStaticPIP     # or set spec.loadBalancerIP (deprecated)
```

### Ingress options on AKS

| Option | Description |
|---|---|
| **Application routing add-on** | Managed NGINX ingress controller with Azure DNS and Key Vault certificate integration (`ingressClassName: webapprouting.kube-system.azure.com`) |
| **Application Gateway for Containers** | Azure's managed L7 load balancer (Gateway API/Ingress) — successor to AGIC |
| **Application Gateway Ingress Controller (AGIC)** | Azure Application Gateway (WAF) as the ingress |
| **Self-managed NGINX / Traefik / Istio gateway** | Install via Helm |
| **Azure Front Door** | Global entry point in front of AKS |

```bash
# Enable the application routing add-on
az aks approuter enable -g myRG -n myAKS
# (or at creation: az aks create ... --enable-app-routing)
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: webapprouting.kube-system.azure.com
  rules:
  - host: app.contoso.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

**Interview Q: Service type LoadBalancer vs Ingress?** A LoadBalancer Service gets one Azure LB IP per service (L4). An Ingress shares one entry point for many services with host/path routing, TLS, and WAF options (L7) — cheaper and easier to manage at scale.

---

## 31. AKS Storage

AKS uses **CSI drivers** (installed by default) for Azure storage.

| Storage | Default StorageClass | Access mode | Best for |
|---|---|---|---|
| **Azure Disk** | `managed-csi`, `managed-csi-premium` | RWO (RWX only with shared disks on block volumes) | Databases, single-pod persistent data |
| **Azure Files** (SMB/NFS) | `azurefile-csi`, `azurefile-csi-premium` | RWX | Shared content across pods/nodes |
| **Azure Blob** (blobfuse / NFS) | `azureblob-fuse-premium`, `azureblob-nfs-premium` | RWX | Large unstructured data, read-heavy |
| **Azure Container Storage** | — | RWO | Local NVMe / ephemeral, high-performance workloads |

```bash
kubectl get storageclass
```

**Azure Disk PVC (RWO):**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
```

**Azure Files PVC (RWX):**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-files-pvc
spec:
  accessModes: [ReadWriteMany]
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 20Gi
```

**Custom StorageClass (Premium SSD v2 / retain policy example):**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-retain
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**Interview points:**

- Azure Disks are **zonal**: a pod using a zonal disk can only be scheduled in the same zone. Use `WaitForFirstConsumer` binding and zone-redundant storage (ZRS disks) for zone-resilient designs.
- A disk can attach to only one node at a time (RWO) — if a pod with a disk is rescheduled, the disk must detach/attach, which takes time.
- Volume expansion: set `allowVolumeExpansion: true`, then edit the PVC's requested size.
- Backups: **Azure Backup for AKS** or Velero for PV snapshots and cluster resources.

---

## 32. AKS Identity & Access

There are two separate layers: **how humans/apps access the cluster** and **how pods access Azure resources**.

### 1. Cluster access (users)

- **Kubernetes RBAC** with **Microsoft Entra ID** integration (`--enable-aad`).
- **Azure RBAC for Kubernetes authorization** (`--enable-azure-rbac`) — assign Azure role assignments such as *Azure Kubernetes Service RBAC Reader/Writer/Admin/Cluster Admin* instead of managing Kubernetes bindings.
- Disable local accounts (`--disable-local-accounts`) to force Entra authentication.

```bash
az aks update -g myRG -n myAKS --enable-aad --enable-azure-rbac
az aks get-credentials -g myRG -n myAKS      # then use kubelogin for non-interactive auth
```

### 2. Cluster identity (the cluster's own identity to call Azure)

- **Managed identity** (recommended) — system-assigned or user-assigned; used by the control plane to manage Azure resources (load balancers, disks, routes).
- **Service principal** — legacy; requires secret rotation.
- **Kubelet identity** — separate managed identity used by nodes to pull images from ACR.

### 3. Workload identity (pods → Azure resources)

**Microsoft Entra Workload ID** lets a pod's Kubernetes ServiceAccount be federated with an Entra identity using OIDC — no secrets stored. It replaces the deprecated *AAD Pod Identity*.

```bash
az aks update -g myRG -n myAKS --enable-oidc-issuer --enable-workload-identity
az aks show -g myRG -n myAKS --query oidcIssuerProfile.issuerUrl -o tsv
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  annotations:
    azure.workload.identity/client-id: <USER_ASSIGNED_IDENTITY_CLIENT_ID>
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: myacr.azurecr.io/app:1.0
```

(You also create a *federated identity credential* on the managed identity that trusts the cluster's OIDC issuer and the `system:serviceaccount:<ns>:app-sa` subject.)

---

## 33. Secrets with Azure Key Vault

Use the **Azure Key Vault provider for Secrets Store CSI Driver** to mount secrets, keys, and certificates from Key Vault directly into pods (and optionally sync them to Kubernetes Secrets).

```bash
az aks enable-addons -g myRG -n myAKS --addons azure-keyvault-secrets-provider
```

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: kv-secrets
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "<WORKLOAD_IDENTITY_CLIENT_ID>"
    keyvaultName: "<KEY_VAULT_NAME>"
    tenantId: "<TENANT_ID>"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
  secretObjects:                # optional: also create a Kubernetes Secret
  - secretName: db-secret
    type: Opaque
    data:
    - objectName: db-password
      key: password
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: myacr.azurecr.io/app:1.0
    volumeMounts:
    - name: secrets
      mountPath: /mnt/secrets
      readOnly: true
  volumes:
  - name: secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: kv-secrets
```

**Why Key Vault over native Secrets?** Centralized rotation and auditing, HSM-backed keys, fine-grained Azure RBAC, no secret values committed to Git, and secrets never need to be stored in YAML.

> Tip: the grant uses the Key Vault RBAC role *Key Vault Secrets User* on the identity.

---

## 34. Azure Container Registry (ACR) Integration

```bash
# Create a registry
az acr create -g myRG -n myacr --sku Standard

# Attach ACR to AKS (grants the kubelet identity AcrPull)
az aks update -g myRG -n myAKS --attach-acr myacr

# Or at cluster creation
az aks create -g myRG -n myAKS --attach-acr myacr ...

# Build and push in Azure (no local Docker needed)
az acr build --registry myacr --image app:1.0 .

# Verify AKS can pull from ACR
az aks check-acr -g myRG -n myAKS --acr myacr.azurecr.io
```

```yaml
containers:
- name: app
  image: myacr.azurecr.io/app:1.0     # no imagePullSecret needed once ACR is attached
```

**Troubleshooting `ImagePullBackOff` with ACR:** verify the image name/tag, check the `AcrPull` role assignment for the kubelet identity, check network access (private endpoint/firewall), and run `az aks check-acr`.

---

## 35. AKS Scaling & Autoscaling

| Level | Feature | Command / Resource |
|---|---|---|
| Pods | Horizontal Pod Autoscaler | `kubectl autoscale` / `HorizontalPodAutoscaler` |
| Pods (event-driven) | **KEDA add-on** | `az aks update --enable-keda` |
| Pods (right-sizing) | Vertical Pod Autoscaler add-on | `az aks update --enable-vpa` |
| Nodes | **Cluster Autoscaler** | `--enable-cluster-autoscaler --min-count --max-count` |
| Nodes (newer) | **Node Auto Provisioning (NAP)**, Karpenter-based | Picks VM sizes automatically based on pending pods |
| Burst | Virtual nodes (ACI) | Serverless burst capacity |

```bash
# Enable cluster autoscaler on an existing node pool
az aks nodepool update -g myRG --cluster-name myAKS -n userpool1 \
  --enable-cluster-autoscaler --min-count 2 --max-count 10

# Enable KEDA
az aks update -g myRG -n myAKS --enable-keda
```

**KEDA ScaledObject example (scale on Azure Service Bus queue length):**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: orders-worker
spec:
  scaleTargetRef:
    name: orders-worker
  minReplicaCount: 0
  maxReplicaCount: 20
  triggers:
  - type: azure-servicebus
    metadata:
      queueName: orders
      messageCount: "10"
    authenticationRef:
      name: servicebus-auth
```

**Interview Q: Why isn't my cluster autoscaler adding nodes?** Common reasons: the pod has no resource requests, hit `max-count`, subscription VM quota/regional capacity limits, no node pool fits the nodeSelector/taints, or the pod is Pending for non-capacity reasons (e.g., unbound PVC).

**Interview Q: HPA vs Cluster Autoscaler?** HPA changes the number of pods; Cluster Autoscaler changes the number of nodes in response to pods that can't be scheduled. They work together.

---

## 36. AKS Upgrades & Maintenance

Two separate upgrade types:

1. **Kubernetes version upgrade** (control plane + node pools).
2. **Node OS image upgrade** (security patches without changing Kubernetes version).

```bash
# Check available versions
az aks get-versions -l eastus -o table
az aks get-upgrades -g myRG -n myAKS -o table

# Upgrade control plane + all node pools
az aks upgrade -g myRG -n myAKS --kubernetes-version 1.31.2

# Upgrade only the control plane
az aks upgrade -g myRG -n myAKS --kubernetes-version 1.31.2 --control-plane-only

# Upgrade a single node pool
az aks nodepool upgrade -g myRG --cluster-name myAKS -n userpool1 --kubernetes-version 1.31.2

# Node image only
az aks nodepool upgrade -g myRG --cluster-name myAKS -n userpool1 --node-image-only

# Auto-upgrade channel
az aks update -g myRG -n myAKS --auto-upgrade-channel stable --node-os-upgrade-channel NodeImage
```

(Version numbers above are examples — check `az aks get-versions` for what's currently supported.)

**How a node pool upgrade works (surge upgrade):**

1. Create surge node(s) with the new version.
2. Cordon and drain an old node (respecting PodDisruptionBudgets).
3. Reimage/replace and move on.

```bash
az aks nodepool update -g myRG --cluster-name myAKS -n userpool1 --max-surge 33%
```

**Auto-upgrade channels:** `none`, `patch`, `stable`, `rapid`, `node-image`.

**Planned maintenance windows:**

```bash
az aks maintenanceconfiguration add -g myRG --cluster-name myAKS -n default \
  --weekday Saturday --start-hour 2
```

**Upgrade rules to remember:**

- You can't skip minor versions for the control plane (e.g., 1.29 → 1.31 requires going through 1.30), though AKS supports upgrading node pools within a supported skew range.
- AKS supports a limited window of Kubernetes minor versions (the most recent three at the time of writing); Premium tier offers long-term support.
- Check for deprecated/removed APIs before upgrading (e.g., with `kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis`).

**Rollback?** You can't downgrade the Kubernetes version of a cluster — plan with a staging cluster, blue-green clusters, and backups.

---

## 37. AKS Monitoring & Logging

| Need | Azure service |
|---|---|
| Container logs, node/pod performance | **Container Insights** (Azure Monitor) → Log Analytics |
| Prometheus metrics | **Azure Monitor managed service for Prometheus** |
| Dashboards | **Azure Managed Grafana** |
| Control-plane logs (API server, audit, scheduler) | **Diagnostic settings** → Log Analytics / Storage / Event Hub |
| Alerts | Azure Monitor alert rules, Prometheus rules |
| Distributed tracing | Application Insights / OpenTelemetry |

```bash
# Enable Container Insights
az aks enable-addons -g myRG -n myAKS --addons monitoring

# Enable Azure Monitor managed Prometheus (+ Grafana)
az aks update -g myRG -n myAKS --enable-azure-monitor-metrics
```

**Sample KQL (Log Analytics) — find crashing containers:**

```kusto
KubePodInventory
| where TimeGenerated > ago(1h)
| where ContainerStatus != "running"
| summarize count() by Name, Namespace, ContainerStatus
```

**Built-in diagnostics:** the Azure Portal's *Diagnose and solve problems* blade for AKS, plus `kubectl top`, `kubectl get events`, and `az aks command invoke` (run kubectl against private clusters).

```bash
az aks command invoke -g myRG -n myPrivateAKS --command "kubectl get pods -A"
```

---

## 38. AKS Security & Governance

**Defense in depth checklist:**

- **Identity:** Entra ID + Azure RBAC, disable local accounts, use Workload Identity (no secrets in pods).
- **Network:** private cluster, NetworkPolicies, Azure Firewall for egress, WAF on ingress, authorized IP ranges for the API server (`--api-server-authorized-ip-ranges`).
- **Secrets:** Key Vault CSI driver; enable KMS etcd encryption for additional protection.
- **Images:** ACR with vulnerability scanning (Microsoft Defender for Containers), signed images, restrict allowed registries.
- **Runtime:** Defender for Containers, Pod Security Standards via **Pod Security Admission** (namespace labels), seccomp/AppArmor, non-root containers, read-only root filesystem.
- **Policy:** **Azure Policy add-on** (Gatekeeper/OPA) to enforce rules (no privileged containers, required labels, allowed registries, resource limits).
- **Nodes:** automatic OS patching (node image channel), Azure Linux (Mariner) or Ubuntu, encryption at host, FIPS options.
- **Updates:** keep the cluster within a supported version; use auto-upgrade.

```bash
# Enable Azure Policy add-on
az aks enable-addons -g myRG -n myAKS --addons azure-policy

# Restrict API server access
az aks update -g myRG -n myAKS --api-server-authorized-ip-ranges 203.0.113.0/24

# Pod Security Admission (enforce 'restricted' on a namespace)
kubectl label namespace prod pod-security.kubernetes.io/enforce=restricted
```

**Pod hardening example:**

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
  seccompProfile:
    type: RuntimeDefault
```

---

## 39. AKS High Availability & Cost Optimization

### High availability

- Use the **Standard (or Premium) tier** for the uptime SLA.
- Spread nodes across **availability zones** (`--zones 1 2 3`) and pods with `topologySpreadConstraints`.
- Run ≥ 3 system pool nodes, multiple replicas of every critical workload, and **PodDisruptionBudgets**.
- Use zone-redundant storage (ZRS disks) for stateful workloads.
- Probes + resource requests/limits for reliable scheduling and self-healing.
- Multi-region: deploy two clusters in paired regions behind **Azure Front Door** or **Traffic Manager**, with GitOps/Fleet Manager for consistent config, and geo-replicated ACR.
- Back up with **Azure Backup for AKS** or Velero.

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: web
```

### Cost optimization

- Right-size VMs; set **requests/limits** accurately (consider VPA).
- **Cluster autoscaler** / Node Auto Provisioning to remove idle nodes; scale user pools to 0 when idle.
- **Spot node pools** for batch/fault-tolerant jobs.
- **Stop/start** dev/test clusters on a schedule (`az aks stop/start`).
- **Reserved Instances / Savings Plans** for steady-state nodes.
- **Free tier** for non-production.
- Use ARM (Ampere) VM sizes where supported for better price/performance.
- Use the **AKS cost analysis** add-on and Azure Cost Management; label namespaces/workloads for chargeback.
- Delete unused PVCs, public IPs, and old load balancers.

---

## 40. AKS vs EKS vs GKE

| Feature | **AKS** (Azure) | **EKS** (AWS) | **GKE** (Google Cloud) |
|---|---|---|---|
| Control plane cost | Free tier available; paid Standard/Premium tiers with SLA | Paid per cluster per hour | Free zonal cluster credit; paid per cluster for others |
| Default node mgmt | Node pools (VMSS) | Managed node groups / Fargate | Node pools; Autopilot mode |
| Serverless pods | Virtual nodes (ACI), AKS Automatic | Fargate | Autopilot |
| Identity integration | Microsoft Entra ID | AWS IAM (aws-auth / access entries) | Google Cloud IAM |
| Pod → cloud identity | Entra Workload ID | IRSA / EKS Pod Identity | Workload Identity Federation |
| Block storage | Azure Disk (`disk.csi.azure.com`) | EBS (`ebs.csi.aws.com`) | Persistent Disk (`pd.csi.storage.gke.io`) |
| Shared file storage | Azure Files | EFS | Filestore |
| Registry | ACR | ECR | Artifact Registry |
| L4 load balancer | Azure Load Balancer | NLB / CLB | Google Cloud Load Balancing |
| L7 ingress | App routing add-on, App Gateway for Containers | AWS Load Balancer Controller (ALB) | GKE Ingress / Gateway (Google LB) |
| Secrets integration | Key Vault CSI provider | Secrets Manager / Parameter Store CSI provider | Secret Manager add-on |
| Monitoring | Container Insights, Managed Prometheus/Grafana | CloudWatch Container Insights, AMP/AMG | Cloud Operations, Managed Prometheus |
| Policy | Azure Policy (Gatekeeper) | Gatekeeper / Kyverno (self-managed) | Policy Controller |

---

## 41. Scenario-Based AKS Interview Questions

**Q1. A pod is stuck in `Pending`. How do you debug it on AKS?**
`kubectl describe pod` → read the Events. Typical causes: insufficient CPU/memory (check `kubectl top nodes`, autoscaler max reached, VM quota), taints without tolerations, `nodeSelector` pointing at a pool that doesn't exist, unbound PVC/zone mismatch with an Azure Disk, or exhausted pod IPs with Azure CNI node-subnet.

**Q2. `ImagePullBackOff` when pulling from ACR?**
Check image name/tag, run `az aks check-acr`, confirm the kubelet identity has `AcrPull`, verify private-link/firewall rules, and confirm the registry isn't in a different tenant without proper auth.

**Q3. How would you give a pod access to Azure Storage or Key Vault without secrets?**
Enable OIDC issuer + Workload Identity, create a user-assigned managed identity with the needed Azure role, create a federated credential for the ServiceAccount, annotate the ServiceAccount with the client ID, and label the pod `azure.workload.identity/use: "true"`.

**Q4. How do you upgrade a production AKS cluster with minimal downtime?**
Upgrade a staging cluster first; check deprecated APIs; ensure PDBs and ≥2 replicas; set `max-surge`; schedule in a maintenance window; upgrade the control plane, then node pools one at a time (system pool first); monitor; use auto-upgrade channels for patch/node-image updates.

**Q5. How would you design a secure, private AKS cluster?**
Private cluster (or authorized IP ranges), Entra ID + Azure RBAC with local accounts disabled, Azure CNI Overlay/Cilium with NetworkPolicies, UDR + Azure Firewall for egress, private ACR via Private Link, Key Vault CSI driver, Defender for Containers, Azure Policy, Pod Security Admission.

**Q6. Your nodes are `NotReady` after a scale-out. What do you check?**
`kubectl describe node`, kubelet/CNI pod status in `kube-system`, subnet IP exhaustion, NSG/route-table or UDR blocking the API server/MCR egress, VMSS instance health in the node resource group, and Azure service health.

**Q7. How do you expose an app to the internet securely?**
Ingress via the application routing add-on or Application Gateway for Containers with a WAF, TLS certificates from Key Vault (or cert-manager + Let's Encrypt), restrict origins with Front Door, and use NetworkPolicies so only the ingress namespace can reach the backends.

**Q8. How do you reduce costs on a dev/test AKS environment?**
Free tier, small burstable VMs or Spot pools, autoscaler min of 0 on user pools, `az aks stop` on nights/weekends, shared clusters with namespaces and ResourceQuotas.

**Q9. How do you do multi-environment deployments on AKS?**
Separate clusters (or at minimum node pools/namespaces) for dev/stage/prod; GitOps with Flux (AKS extension) or Argo CD; Helm/Kustomize overlays per environment; Azure DevOps or GitHub Actions pipelines that build to ACR and deploy with `azure/aks-set-context` and `kubectl`/Helm.

**Q10. A stateful pod using an Azure Disk won't start after a node failure.**
Likely a *Multi-Attach* or stuck-attach issue: the disk is still attached to the old (failed) node. Wait for the detach timeout, force-delete the old pod, or check the disk in the portal. Use StatefulSets, ZRS disks, and zone-aware scheduling for resilience.

**Q11. What's the difference between a system node pool and user node pool?**
System pools host critical add-ons (CoreDNS, metrics-server) and must exist with ≥1 node (Linux). User pools host your apps and can scale to 0. You can run apps on system pools unless you taint them with `CriticalAddonsOnly`.

**Q12. How does AKS handle Kubernetes secrets encryption?**
etcd storage is encrypted at rest with platform-managed keys by default; you can enable KMS etcd encryption with a customer-managed key in Key Vault. For higher security, keep secrets in Key Vault and mount them with the CSI driver instead of storing them in etcd at all.

---

## Quick `kubectl` + `az aks` Cheat Sheet

```bash
# Context & config
kubectl config get-contexts
kubectl config use-context <context>
az aks get-credentials -g myRG -n myAKS --overwrite-existing

# Cluster health
kubectl get nodes -o wide
kubectl get pods -A
kubectl top nodes && kubectl top pods -A
kubectl get events -A --sort-by=.lastTimestamp

# AKS operations
az aks list -o table
az aks nodepool list -g myRG --cluster-name myAKS -o table
az aks get-upgrades -g myRG -n myAKS -o table
az aks scale -g myRG -n myAKS --node-count 4
az aks command invoke -g myRG -n myAKS --command "kubectl get pods -A"
```

---

## Contributing

Corrections and additions are welcome — open an issue or pull request.
