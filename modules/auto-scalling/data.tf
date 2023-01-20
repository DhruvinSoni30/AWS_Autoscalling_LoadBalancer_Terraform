data "template_file" "user_data" {
    template = file("/Users/dhruvins/Desktop/AWS_Autoscalling_LoadBalancer_Terraform/modules/auto-scalling/container.sh")
}