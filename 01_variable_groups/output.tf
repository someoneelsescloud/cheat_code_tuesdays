output "localadmin" {
  value = random_password.password.result
  sensitive = true
}
