aws_region = "ap-south-1"
environment = "dev"
name = "hotel-booking-dev"

vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]

nat_gateway_count = 1

container_image = "nginx:1.27-alpine"
container_port  = 80
task_cpu        = 256
task_memory     = 512
desired_count   = 1

rds_instance_class        = "db.t4g.micro"
rds_allocated_storage     = 20
rds_max_allocated_storage = 50
rds_backup_retention_period = 3
rds_deletion_protection   = false
rds_multi_az              = false
rds_skip_final_snapshot   = true

db_name     = "hotelbookings"
db_username = "appuser"
db_password = "change-me-in-real-deployment"
