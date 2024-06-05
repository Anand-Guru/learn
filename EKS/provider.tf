terraform {
  required_version = "1.8.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
}
provider "aws" {
  region     = "us-west-2"
  access_key = ""
  secret_key = ""
}


provider "kubernetes" {
    
  config_path = "~/.kube/config"
  
}

provider "time" {
  
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.cluster-2]

 
 create_duration = "60s"
}