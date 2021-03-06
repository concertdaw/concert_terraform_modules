variable "name" {}
variable "subdomain" {}
variable "source_git_url" {}
variable "commit_sha" {}
variable "cache_dir" {}
variable "buildpacks" {
  default = ["heroku/python"]
}
variable "config_vars" {
  type = "map"
  description = "Due to a terraform bug, you can't leave this empty!"
  default = {
    NULL = ""
  }
}


module "app_git_repo" {
  source = "git@github.com:concert/terraform_modules.git//git_repo"
  git_url = "${var.source_git_url}"
  clone_path = "${var.cache_dir}/${var.source_git_url}"
  commit_sha = "${var.commit_sha}"
}

resource "heroku_app" "app" {
  name = "${var.name}"
  region = "eu"
  buildpacks = "${var.buildpacks}"
  config_vars = ["${var.config_vars}"]
}


resource "null_resource" "git_push" {
  triggers {
    source_git_url = "${var.source_git_url}"
    commit_sha = "${var.commit_sha}"
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${module.app_git_repo.clone_path}
      if ! git config remote.${var.name}.url > /dev/null; then
        git remote add ${var.name} ${heroku_app.app.git_url}
      fi
      git push --force ${var.name} ${module.app_git_repo.target_branch}:master
    EOF
  }
}

output "name" {
  value = "${heroku_app.app.name}"
}

output "git_url" {
  value = "${heroku_app.app.git_url}"
}

output "web_url" {
  value = "${heroku_app.app.web_url}"
}



resource "heroku_domain" "co_uk" {
  app = "${heroku_app.app.name}"
  hostname = "${var.subdomain}.concertdaw.co.uk"
}

resource "heroku_domain" "hyphen_co_uk" {
  app = "${heroku_app.app.name}"
  hostname = "${var.subdomain}.concert-daw.co.uk"
}

resource "heroku_domain" "com" {
  app = "${heroku_app.app.name}"
  hostname = "${var.subdomain}.concertdaw.com"
}

resource "heroku_domain" "hyphen_com" {
  app = "${heroku_app.app.name}"
  hostname = "${var.subdomain}.concert-daw.com"
}

output "domain_map" {
  value = "${map(
    heroku_domain.co_uk.hostname, heroku_domain.co_uk.cname,
    heroku_domain.hyphen_co_uk.hostname, heroku_domain.hyphen_co_uk.cname,
    heroku_domain.com.hostname, heroku_domain.com.cname,
    heroku_domain.hyphen_com.hostname, heroku_domain.hyphen_com.cname
    )}"
}
