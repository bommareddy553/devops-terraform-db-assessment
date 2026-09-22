# Reviewer Notes

## Terraform

- Modular VPC/network, ECS and RDS resources.
- Separate dev/prod roots.
- Separate variable and tfvars files.
- Separate backend configuration.
- RDS is private.
- RDS ingress is restricted to the ECS security group.
- ALB is public; ECS tasks are private.
- Production enables deletion protection, longer backups, Multi-AZ and two NAT gateways.
- Dev is intentionally smaller.

## Database

- PostgreSQL 16 via Docker Compose.
- 120 deterministic hotel bookings.
- Multiple cities, organizations and statuses.
- Booking event records use JSONB.
- Composite index matches the target filter.
- Backup uses PostgreSQL custom format.
- Restore creates a fresh database.

## CI

The GitHub Actions workflow is intentionally plan-only and does not deploy infrastructure.
