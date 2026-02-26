region               = "ap-south-1"
project              = "my-project"
instance_type        = "t3.small"

desired_capacity     = 2

rds_allocated_storage = 50
rds_instance_class    = "db.t3.small"

lambda_memory_size    = 256

enable_deletion_protection = false