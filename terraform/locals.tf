locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_github_no_pass.pub"))
}
