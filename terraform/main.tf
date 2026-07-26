terraform {
	required_providers {
		kubernetes = {
			source = "hashicorp/kubernetes"
			version = "~> 2.25"
		}
	}
}

provider "kubernetes" {
	config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "prodwatch" {
	metadata {
		name = "prodwatch"
	}
}

resource "kubernetes_deployment" "inventory_service" {
	metadata {
		name = "inventory-service"
		namespace = kubernetes_namespace.prodwatch.metadata[0].name
	}
	spec {
		replicas = 1
		selector {
			match_labels = {
				app = "inventory-service"
			}
		}
		template {
			metadata {
				labels = {
					app = "inventory-service"
				}
			}
			spec {
				container {
					name = "inventory-service"
					image = "inventory-service:v1"
					image_pull_policy = "Never"
					
					port {
						container_port = 8000
					}
					liveness_probe {
						http_get {
							path = "/health"
							port = 8000
						}
						initial_delay_seconds = 5
						period_seconds = 10
					}
					readiness_probe {
						http_get {
							path = "/health"
							port = 8000
						}
						initial_delay_seconds = 5
						period_seconds = 5
					}
					resources {
						requests = {
							cpu = "100m"
							memory = "128Mi"
						}
						limits = {
							cpu = "250m"
							memory = "256Mi"
						}
					}
				}
			}
		}
	}
}

resource "kubernetes_service" "inventory_service" {
	metadata {
		name = "inventory-service"
		namespace = kubernetes_namespace.prodwatch.metadata[0].name
	}
	spec {
		selector = {
			app = "inventory-service"
		}
		port {
			port = 8000
			target_port = 8000
		}
		type = "ClusterIP"
	}
}

resource "kubernetes_config_map" "order_service_config" {
	metadata {
		name = "order-service-config"
		namespace = kubernetes_namespace.prodwatch.metadata[0].name
	}
	data = {
		INVENTORY_SERVICE_URL = "http://inventory-service:8000"
	}
}

resource "kubernetes_deployment" "order_service" {
	metadata {
		name = "order-service"
		namespace = kubernetes_namespace.prodwatch.metadata[0].name
	}
	spec {
		replicas = 1
		selector {
			match_labels = {
				app = "order-service"
			}
		}
		template {
			metadata {
				labels = {
					app = "order-service"
				}
			}
			spec {
				container {
					name = "order-service"
					image = "order-service:v1"
					image_pull_policy = "Never"
					port {
						container_port = 8001
					}
					env {
						name = "INVENTORY_SERVICE_URL"
						value_from {
							config_map_key_ref {
								name = kubernetes_config_map.order_service_config.metadata[0].name
								key = "INVENTORY_SERVICE_URL"
							}
						}
					}
					liveness_probe {
						http_get {
							path = "/health"
							port = 8001
						}
						initial_delay_seconds = 5
						period_seconds = 10
					}
					readiness_probe {
						http_get {
							path = "/health"
							port = 8001
						}
						initial_delay_seconds = 5
						period_seconds = 5
					}
					resources {
						requests = {
							cpu = "100m"
							memory = "128Mi"
						}
						limits = {
							cpu = "250m"
							memory = "256Mi"
						}
					}
				}
			}
		}
	}
}
						
	
resource "kubernetes_service" "order_service" {
	metadata {
		name = "order-service"
		namespace = kubernetes_namespace.prodwatch.metadata[0].name
	}
	spec {
		selector = {
			app = "order-service"
		}
		port {
			port = 8001
			target_port = 8001
		}
		type = "NodePort"
	}
}
