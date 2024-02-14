output "master-internal-ip" {
  description = "Master private IP"
  value       = google_compute_instance.master.network_interface.0.network_ip
}

output "master-external-ip" {
  description = "Master public IP"
  value       = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
}

output "worker1-internal-ip" {
  description = "Master private IP"
  value       = google_compute_instance.worker1.network_interface.0.network_ip
}

output "worker1-external-ip" {
  description = "Master public IP"
  value       = google_compute_instance.worker1.network_interface.0.access_config.0.nat_ip
}

output "worker2-internal-ip" {
  description = "Master private IP"
  value       = google_compute_instance.worker2.network_interface.0.network_ip
}

output "worker2-external-ip" {
  description = "Master public IP"
  value       = google_compute_instance.worker2.network_interface.0.access_config.0.nat_ip
}

output "worker3-internal-ip" {
  description = "Master private IP"
  value       = google_compute_instance.worker3.network_interface.0.network_ip
}

output "worker3-external-ip" {
  description = "Master public IP"
  value       = google_compute_instance.worker3.network_interface.0.access_config.0.nat_ip
}

