# DevOps Assessment — Terraform + Database Reliability

This repository demonstrates AWS infrastructure design with Terraform and practical PostgreSQL database operations using Docker Compose.

## Architecture

```text
Internet
   |
   v
ALB (public subnets)
   |
   v
ECS/Fargate (private subnets)
   |
   | TCP/5432
   v
RDS PostgreSQL (private subnets)
```

### Security model

- ALB accepts HTTP traffic from the internet.
- ECS tasks accept application traffic only from the ALB security group.
- RDS accepts PostgreSQL traffic only from the ECS security group.
- RDS has no public IP and is deployed in private subnets.
- Dev and prod have separate Terraform roots and state paths.

## Repository layout

```text
infra/
  modules/
    network/
    ecs/
    rds/
  envs/
    dev/
    prod/
database/
  migrations/
  seed/
scripts/
.github/workflows/
docker-compose.yml
```

## Prerequisites

- Terraform >= 1.6
- Docker + Docker Compose
- PostgreSQL client (`psql`, optional; scripts use the Docker container)
- Git

## Local database

Start PostgreSQL:

```bash
docker compose up -d
docker compose ps
```

The database is initialized automatically from:

- `database/migrations/001_create_tables.sql`
- `database/seed/001_seed_data.sql`

Verify:

```bash
docker compose exec -T postgres \
  psql -U appuser -d bookings -c "SELECT COUNT(*) AS bookings FROM hotel_bookings;"

docker compose exec -T postgres \
  psql -U appuser -d bookings -c "SELECT COUNT(*) AS events FROM booking_events;"
```

Expected seed data is at least 100 bookings and multiple booking events.

## Query optimization

The target query is:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

The migration creates:

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
ON hotel_bookings (city, created_at);
```

`city` is an equality predicate and `created_at` is a range predicate, so the composite index is ordered to narrow the candidate rows before PostgreSQL performs the aggregation.

Check the plan:

```bash
docker compose exec -T postgres psql -U appuser -d bookings <<'SQL'
EXPLAIN (ANALYZE, BUFFERS)
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
SQL
```

With a small local dataset PostgreSQL may still choose a sequential scan because that can be cheaper than using an index. The important point is that the index supports the production query shape; `EXPLAIN ANALYZE` should be used with representative production-scale data before declaring an index beneficial.

## Backup

Create a timestamped custom-format PostgreSQL dump:

```bash
./scripts/backup.sh
```

Backups are written to:

```text
backups/bookings_YYYYMMDD_HHMMSS.dump
```

## Restore

Restore the most recent backup into a fresh database:

```bash
./scripts/restore.sh
```

The script creates a new database named similar to:

```text
bookings_restore_20260922_174800
```

Verify:

```bash
docker compose exec -T postgres \
  psql -U appuser -d <restore_database_name> \
  -c "SELECT COUNT(*) FROM hotel_bookings;"
```

The restore database is intentionally separate from the source database so the recovery procedure does not destroy the original data.

## Terraform

Each environment is an independent Terraform root:

```text
infra/envs/dev
infra/envs/prod
```

### Dev

- Smaller ECS/RDS sizing
- ECS desired count: 1
- RDS backup retention: 3 days
- Deletion protection: false
- Multi-AZ: false

### Prod

- Larger ECS/RDS sizing
- ECS desired count: 2
- RDS backup retention: 14 days
- Deletion protection: true
- Multi-AZ: true
- Two NAT gateways

### Validate dev

```bash
cd infra/envs/dev
terraform fmt -recursive
terraform init
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
```

### Validate prod

```bash
cd infra/envs/prod
terraform fmt -recursive
terraform init
terraform validate
terraform plan -refresh=false -var-file=prod.tfvars
```

The included backend files use Terraform's local backend so `terraform init` works without requiring an already-created AWS S3 state bucket. For a real deployment, replace the backend configuration with an S3 backend and enable state locking according to the organization's current Terraform/AWS standards.

> `terraform plan` requires valid AWS credentials and a reachable AWS account when resources are actually planned. No `terraform apply` is required for this assessment.

## GitHub Actions

The workflow runs on pull requests and performs:

1. `terraform fmt -check`
2. `terraform init`
3. `terraform validate`
4. `terraform plan -refresh=false`

The workflow uses `-input=false` and does not perform `terraform apply`.

## Design notes

### Networking

- Two public subnets are used for the ALB.
- Two private subnets are used for ECS and RDS.
- NAT gateways provide outbound internet access from private ECS tasks.
- RDS is placed in a dedicated DB subnet group using private subnets.

### IAM

The ECS task execution role is separate from the task role. The execution role is used by ECS to pull images and publish logs.

For a production application, application credentials should be stored in AWS Secrets Manager or SSM Parameter Store rather than in Terraform variables or source control.

### RDS

RDS is configured with:

- private subnets
- encryption at rest
- deletion protection controlled per environment
- backup retention controlled per environment
- PostgreSQL 16
- storage encryption
- no public accessibility

