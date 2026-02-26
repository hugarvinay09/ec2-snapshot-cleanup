region               = "ap-south-1"
project              = "my-project"
instance_type        = "t3.micro"

desired_capacity     = 1

rds_allocated_storage = 20
rds_instance_class    = "db.t3.micro"

lambda_memory_size    = 128

enable_deletion_protection = false