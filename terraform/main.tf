# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
# }

# provider "aws" {
#   region = var.region
# }

# data "aws_availability_zones" "available" {}

# locals {
#   cluster_name = var.clusterName
# }

# ##

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = var.clusterName
}

resource "aws_kms_alias" "this" {
  count = length([for alias in data.aws_kms_alias.existing_aliases.aliases : alias if alias.name == "alias/eks/vprofile-eks"]) == 0 ? 1 : 0
  name          = "alias/eks/vprofile-eks"
  target_key_id = aws_kms_key.this.id
}

data "aws_kms_alias" "existing_aliases" {
  provider = aws
  name     = "alias/eks/vprofile-eks"
}

resource "aws_eks_cluster" "this" {
  count = length([for cluster in data.aws_eks_cluster.existing_clusters.clusters : cluster if cluster.name == var.clusterName]) == 0 ? 1 : 0
  name     = var.clusterName
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
}

data "aws_eks_cluster" "existing_clusters" {
  provider = aws
  name     = var.clusterName
}

resource "aws_route" "private_nat_gateway" {
  count = length([for route in data.aws_route_table.existing_routes.routes : route if route.destination_cidr_block == "0.0.0.0/0"]) == 0 ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

data "aws_route_table" "existing_routes" {
  provider = aws
  route_table_id = aws_route_table.private.id
}