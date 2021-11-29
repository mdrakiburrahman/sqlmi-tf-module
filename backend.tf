terraform {
  backend "remote" {
    hostname = "app.terraform.io" // for Terraform Cloud, this may be omitted or set to `app.terraform.io`
    organization = "raki-k8s-workspace"

    workspaces {
      name = "sqlmiops-sqlmi"
    }
  }
}