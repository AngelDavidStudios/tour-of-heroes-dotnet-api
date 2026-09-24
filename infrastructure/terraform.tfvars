# Database configuration
# WARNING: Do not store sensitive passwords in this file in production!
# Use environment variables, Azure Key Vault, or Terraform Cloud variables instead.
# These values are for demonstration purposes only.
db_user                    = "mradministrator"
db_password                = "thisIsDog11"

# Database provider: "SqlServer" or "PostgreSQL"
database_provider          = "SqlServer"

# PostgreSQL-specific password (optional, uses db_password if not set)
postgresql_admin_password  = null

# Project configuration
project_name               = "tour-of-heroes"
environment                = "prod"
