include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//kafka"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
  vpc_cidr   = dependency.vpc.outputs.vpc_cidr
}