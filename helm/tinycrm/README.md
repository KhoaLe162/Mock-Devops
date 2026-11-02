# TinyCRM Helm chart

The chart renders frontend, backend, and MySQL Deployments and three ClusterIP
Services in namespace `tinycrm`. MySQL is fixed at one replica and uses a
disk-backed `emptyDir` mounted at `/var/lib/mysql`, with `Recreate` updates.
No persistent storage, storage driver, managed database, or AWS resource is
required or provisioned. Optional ALB Ingress remains disabled by default.

**All database data is lost when the MySQL Pod is deleted, replaced, rescheduled,
or rolled out.** Data survives a container restart within the same Pod.
This deployment is suitable for disposable development/demo data.

## Configuration traced to the project

| Setting | Chart default and source |
| --- | --- |
| Namespace | `tinycrm`; pass `--namespace tinycrm` to every Helm command |
| Database | `support_module_dev`, from current root `.env` and development override |
| Application user | Supply `dev_user` in the existing Secret, matching current `.env` |
| MySQL | `mysql:8.0`, ClusterIP Service `mysql:3306` |
| Backend | `084250374652.dkr.ecr.ap-southeast-1.amazonaws.com/tinycrm-backend:latest`, port `8080` |
| Frontend | `084250374652.dkr.ecr.ap-southeast-1.amazonaws.com/tinycrm-frontend:latest`, port `8080` |
| Datasource | `jdbc:mysql://mysql:3306/support_module_dev?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| Profile | `dev`, from current `.env`; logging defaults to `INFO` |
| Hibernate | `update`, MySQL8Dialect, matching Compose overrides |

The backend sets the project's `SPRING_DATASOURCE_URL`,
`SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`,
`SPRING_DATASOURCE_DRIVER_CLASS_NAME`, JPA settings, `SERVER_PORT`, and
`SPRING_PROFILES_ACTIVE`. Credentials come exclusively from Secret references.
The short DNS name `mysql` resolves the Service in the same namespace.

Compose host ports `3000` and `3307` are not container ports. Frontend and backend
Services both use `8080`. Service names are fixed: `frontend`, `backend`, `mysql`.
The existing Nginx image requires `backend:8080`; the chart rejects a different
backend Service port. Only one release can own these Service names per namespace.

The Compose/properties database default is instead `support_module`; set
`mysql.database` explicitly if needed. Helm does not read `.env`. Environment
variables override bundled Spring properties, including its MySQL5Dialect.
The chart does not mount `db/init.sql`, which hardcodes `USE support_module`.
Versioned SQL files are not integrated with a migration runner and contain
inconsistent table names. A fresh database uses the existing Hibernate
`ddl-auto=update` behavior; there is no automatic existing-data import.
Compatible UTF-8, UTC, and buffer-pool settings are preserved as MySQL arguments;
obsolete query-cache options from `db/mysql.cnf` are omitted.

## Credentials and prerequisites

Before a future deployment, namespace `tinycrm` and an existing Secret named
`tinycrm-mysql-credentials` must be provisioned securely outside Git.

| Secret key | Content |
| --- | --- |
| `MYSQL_ROOT_PASSWORD` | New strong root password |
| `MYSQL_USER` | `dev_user`, or the chosen non-root application username |
| `MYSQL_PASSWORD` | New strong application password |

Both MySQL and backend reference the same application credentials; only MySQL
receives the root password. Configure names under `mysql.existingSecret` and
`mysql.secretKeys`. No Secret or passwords are rendered by this chart.
Do not commit credentials or put them in values files or shell arguments.
Local `*.local.yaml` and `*.local.yml` files are ignored.

MySQL initialization variables apply only to an empty data directory. A Secret
change does not rotate credentials in a running database: coordinate SQL rotation
and consumer restarts, or deliberately recreate the disposable database.

Confirm the requested images exist and workers can pull ECR images. The MySQL
image also needs Docker Hub access. Private nodes require existing outbound
connectivity. Optional `imagePullSecrets` can be configured. Application images
use `Always`; publishing a new `latest` tag alone does not restart running pods.

## Resource settings and startup

| Component | Replicas | CPU request / limit | Memory request / limit |
| --- | --- | --- | --- |
| Frontend | 1 | 100m / 500m | 128Mi / 256Mi |
| Backend | 1 | 250m / 1 | 512Mi / 1Gi |
| MySQL | fixed 1 | 250m / 1 | 512Mi / 1Gi |

Application requests total 600m CPU and 1152Mi memory, a conservative starting
point for two t3.medium workers. Resources and probes are configurable in
`values.yaml`; actual remaining node capacity and load must still be checked.
The backend JVM heap is bounded at 512Mi under its 1Gi memory limit.

- MySQL startup and readiness perform authenticated SQL checks; liveness uses a
  local `mysqladmin ping`.
- The backend init container waits for authenticated `SELECT 1` against
  `mysql:3306` using the application database and credentials before Java starts.
- Backend startup/readiness/liveness use TCP port 8080 because Actuator is absent.
  These probes confirm the listener, not ongoing database health.
- Frontend probes use the existing Nginx `/health` endpoint.

Backend replicas default to one, with `Recreate` rollouts. Servlet sessions and
avatar uploads under `/tmp/uploads/avatars` are local to the backend Pod. Rollouts
can log users out and lose uploads. Review session handling before scaling.

## Frontend and optional Ingress

The source Vue bundle hardcodes `axios.defaults.baseURL = 'http://localhost:8080'`.
Rebuild the frontend with same-origin API calls and remove other localhost API
references before public access. Runtime `BACKEND_URL` or
`VUE_APP_API_BASE_URL` cannot rewrite a compiled Vue bundle. Nginx already proxies
`/api/` to `backend:8080`. Review hardcoded local CORS origins and replace
startup-created default admin/support credentials before exposing the app.

Ingress stays disabled. The optional template uses class `alb`, IP targets,
internet-facing scheme, and `/health` checks, routing all traffic to Nginx.
Enabling it later requires an existing AWS Load Balancer Controller and its IAM
permissions and may create an AWS ALB. HTTPS additionally needs certificate,
listener/redirect annotations, DNS, and secure-cookie/forwarded-header settings.
Leave it disabled under the current no-AWS-resource requirement.

If an older chart was previously installed, moving to this version discards the
old database workload and changes the database Service name. This chart does not
delete or migrate previously retained storage; handle any old resources separately
only with explicit authorization.

## Local validation

```powershell
helm lint helm/tinycrm --namespace tinycrm --strict
helm template tinycrm helm/tinycrm --namespace tinycrm
```

The namespace guard rejects rendering in `default`. Rendering does not verify
image or Secret availability. No installation, live Kubernetes mutation, or
Terraform operation was performed.
