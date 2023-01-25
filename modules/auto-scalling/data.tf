data "template_file" "user_data" {
    template = file("container.sh")
}
