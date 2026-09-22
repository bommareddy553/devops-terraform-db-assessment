aws_region = "ap-south-1"
environment = "prod"
name = "hotel-booking-prod"

vpc_cidr             = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]

nat_gateway_count = 2

container_image = "nginx:1.27-alpine"
container_port  = 80
task_cpu        = 512
task_memory     = 1024
desired_count   = 2

rds_instance_class        = "db.t4g.small"
rds_allocated_storage     = 50
rds_max_allocated_storage = 200
rds_backup_retention_period = 14
rds_deletion_protection   = true
rds_multi_az              = true
rds_skip_final_snapshot   = false

db_name     = "hotelbookings"
db_username = "appuser"
db_password = "change-me-in-real-deployment"
