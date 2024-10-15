resource "kubernetes_secret" "database_env" {
  metadata {
    name = "database-env"
  }

  data = {
    MYSQL_ROOT_PASSWORD = var.db_root_password
    MYSQL_DATABASE      = var.db_name
    MYSQL_USER          = var.db_user
    MYSQL_PASSWORD      = var.db_password
  }
}

resource "kubernetes_persistent_volume" "mariadb_pv" {
  metadata {
    name = "mariadb-pv"
  }

  spec {
    capacity = {
      storage = "1Gi"
    }
    volume_mode  = "Filesystem"
    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/data/mariadb"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb_pvc" {
  metadata {
    name = "mariadb-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_stateful_set" "mariadb_statefulset" {
  metadata {
    name = "mariadb-statefulset"
  }

  spec {
    service_name = "mariadb"
    replicas     = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        toleration {
          key      = "database"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }

        container {
          name  = "mariadb"
          image = "mariadb:5.5"

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_env.metadata[0].name
                key  = "MYSQL_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_env.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_env.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_env.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          port {
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "mariadb-storage"
          }
        }

        volume {
          name = "mariadb-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mariadb_pvc.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mariadb-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mariadb_service" {
  metadata {
    name = "mariadb"
    labels = {
      app = "mariadb"
    }
  }

  spec {
    port {
      port        = 3306
      target_port = 3306
    }
    
    selector = {
      app = "mariadb"
    }
  }
}
