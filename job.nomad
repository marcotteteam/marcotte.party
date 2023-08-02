job "mastodon" {
  datacenters = ["dc1"]

  group "mastodon" {
    count = 1
    task "server" {
      driver = "docker"
      config {
        image        = "marcoacierno/mastodon:latest"
        network_mode = "host"
      }

      resources {
        cpu    = 5000
        memory = 5000
      }

      volume_mount {
        volume      = "uploads"
        destination = "/opt/mastodon/public/system"
      }

      env {
        LOCAL_DOMAIN             = "marcotte.party"
        WEB_CONCURRENCY          = "0"         # exactly 1 Puma process
        OVERMIND_FORMATION       = "sidekiq=1" # exactly 1 sidekiq process
        MALLOC_ARENA_MAX         = "2"
        MAX_THREADS              = "5"
        RAILS_ENV                = "production"
        RAILS_LOG_TO_STDOUT      = "enabled"
        RAILS_SERVE_STATIC_FILES = "false"
        REDIS_HOST               = "localhost"
        REDIS_PORT               = "6379"
        SMTP_SERVER              = "smtp.eu.mailgun.org"
        SMTP_PORT                = "587"
        SMTP_FROM_ADDRESS        = "marcotte@email.marcotte.party"
        SMTP_LOGIN               = "postmaster@email.marcotte.party"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/envs.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/mastodon" -}}
SMTP_PASSWORD = {{ .SMTP_PASSWORD }}
DATABASE_URL = "postgresql://mastodon:{{ .POSTGRES_PASSWORD }}@localhost:5432/mastodon"
{{- end -}}
EOF
      }
    }

    task "db" {
      driver = "docker"

      config {
        image        = "postgres:15.3"
        network_mode = "host"
      }
      env {
        POSTGRES_USER = "mastodon"
        POSTGRES_DB   = "mastodon"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/envs.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/mastodon" -}}
POSTGRES_PASSWORD = {{ .POSTGRES_PASSWORD }}
{{- end -}}
EOF
      }

    }

    task "redis" {
      driver = "docker"
      config {
        image        = "marcoacierno/mastodon-redis:latest"
        network_mode = "host"
      }

      resources {
        cpu    = 2000
        memory = 2000
      }
    }

    volume "uploads" {
      type      = "host"
      read_only = false
      source    = "mastodon-uploads"
    }
  }
}
