# Utiliser le role existant du Lab AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
