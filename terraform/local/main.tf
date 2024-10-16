resource "kubernetes_secret" "ormconfig_env" {
  metadata {
    name = "ormconfig-env"
  }
  data = {
    "ormconfig.env" = file("${path.module}/../../ormconfig.env")
  }
}

resource "kubernetes_deployment" "myapp" {
  metadata {
    name      = "myapp"
    labels = {
      app = "myapp"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "myapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }

      spec {
        topology_spread_constraint {
          max_skew               = 1
          topology_key           = "topology.kubernetes.io/zone"
          when_unsatisfiable     = "DoNotSchedule"

          label_selector {
            match_labels = {
              app = "myapp"
            }
          }
        }

        container {
          name  = "myapp"
          image = "ihsrp/infra-test:latest"

          port {
            container_port = 3000
          }

          volume_mount {
            name      = "ormconfig-env"
            mount_path = "/app/ormconfig.env"
            sub_path  = "ormconfig.env"
          }
        }

        volume {
          name = "ormconfig-env"

          secret {
            secret_name = "ormconfig-env"
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "myapp_hpa" {
  metadata {
    name      = "myapp-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "myapp"
    }

    min_replicas = 3
    max_replicas = 10

    metric {
      type = "Resource"
      
      resource {
        name = "cpu"
        
        target {
          type               = "Utilization"
          average_utilization = 75
        }
      }
    }
  }
}


resource "kubernetes_pod_disruption_budget" "myapp_pdb" {
  metadata {
    name      = "myapp-pdb"
  }

  spec {
    min_available = 1

    selector {
      match_labels = {
        app = "myapp"
      }
    }
  }
}

resource "kubernetes_service" "myapp_service" {
  metadata {
    name      = "myapp-service"
  }

  spec {
    selector = {
      app = "myapp"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}