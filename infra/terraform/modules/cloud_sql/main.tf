resource "random_password" "db" {
  length  = 24
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "${var.instance_name}-${var.environment}"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = var.tier
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    availability_type = var.high_availability ? "REGIONAL" : "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_self_link
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      # google provider >= 6: backup_retention_days removed; use backup_retention_settings.
      # Daily backups: retaining N backups approximates N days of history.
      transaction_log_retention_days = min(var.backup_retention_days, 7)
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # uuid-ossp: no Cloud SQL instance flag; enabled in-app via Alembic revision 0005_uuid_ossp.
    database_flags {
      name  = "cloudsql.enable_pgvector"
      value = "on"
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  deletion_protection = var.environment == "prod"
}

resource "google_sql_database" "app" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = var.db_user
  instance = google_sql_database_instance.main.name
  password = random_password.db.result
}
