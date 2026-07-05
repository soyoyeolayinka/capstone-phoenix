output "control_plane_public_ip" {
  description = "Public IP for SSH and kubeconfig server rewrite."
  value       = module.compute.control_plane_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP used by workers to join k3s."
  value       = module.compute.control_plane_private_ip
}

output "worker_public_ips" {
  description = "Worker public IPs for SSH."
  value       = module.compute.worker_public_ips
}

output "worker_private_ips" {
  description = "Worker private IPs."
  value       = module.compute.worker_private_ips
}

output "ansible_inventory" {
  description = "Rendered inventory values to copy into infra/ansible/inventory.ini."
  value = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    control_plane_public_ip  = module.compute.control_plane_public_ip
    control_plane_private_ip = module.compute.control_plane_private_ip
    worker_public_ips        = module.compute.worker_public_ips
    worker_private_ips       = module.compute.worker_private_ips
    ssh_user                 = "ubuntu"
  })
}
