############################## SECRETS ######################################

# Guardamos los datos de conexión a RDS en Secrets Manager:

resource "aws_secretsmanager_secret" "credentials" {
  name        = "rtb-db-secret"
  description = "BBDD secret"
  depends_on = [
    aws_db_instance.vm_db
  ]
}

resource "aws_secretsmanager_secret_version" "credentials_data" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    "host" : aws_db_instance.vm_db.address,
    "db" : var.db_name,
    "username" : var.db_username,
    "password" : var.db_password
  })
  depends_on = [
    aws_secretsmanager_secret.credentials
  ]
}


############################## POLICY ######################################

data "aws_iam_policy_document" "secrets_manager_policy" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.credentials.arn]
  }
}

resource "aws_iam_policy" "secret_policy" {
  name        = "secret_policy"
  description = "Webapp database config retrieving"
  policy      = data.aws_iam_policy_document.secrets_manager_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

############################## ROLE ######################################

resource "aws_iam_role" "role_kc" {
  name               = "role_kc"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy_attachment" "policy_role_assoc" {
  name       = "policy_role_assoc"
  roles      = [aws_iam_role.role_kc.id]
  policy_arn = aws_iam_policy.secret_policy.arn
  depends_on = [
    aws_iam_role.role_kc,
    aws_iam_policy.secret_policy
  ]
}


#  perfil de instancia para pasar un rol de IAM a una instancia EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.role_kc.id
  depends_on = [
    aws_iam_policy_attachment.policy_role_assoc
  ]
}
