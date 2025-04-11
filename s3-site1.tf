# Variável de buckets
locals {
  buckets = ["cliente.com.br", "cliente.com.br-dev"]
}

# Criação dos buckets e suas configurações
resource "aws_s3_bucket" "aws_site_cliente" {
  for_each = toset(local.buckets)

  bucket        = each.key
  force_destroy = true

  tags = {
    Name        = each.key
    Environment = each.key == "cliente.com.br" ? "prod" : "dev"
  }
}

resource "aws_s3_bucket_website_configuration" "site_cliente" {
  for_each = aws_s3_bucket.aws_site_cliente

  bucket = each.value.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cliente_cors" {
  for_each = aws_s3_bucket.aws_site_cliente

  bucket = each.value.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_cliente_public_access_block" {
  for_each = aws_s3_bucket.aws_site_cliente

  bucket                  = each.value.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_cliente_policy" {
  for_each = aws_s3_bucket.aws_site_cliente

  bucket = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = each.value.arn
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource  = "${each.value.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket_cliente_public_access_block]
}


resource "aws_s3_object" "index" {
  for_each     = aws_s3_bucket.aws_site_cliente
  bucket       = each.value.bucket
  key          = "index.html"
  content      = <<EOF
    <!DOCTYPE html>
    <html>
    <head>
        <title>Listagem de Arquivos</title>
    </head>
    <body>
        <h1>Listagem de Arquivos</h1>
        carregando, aguarde.... <br> Bucket: ${each.value.bucket}
    </body>
    </html>
  EOF
  content_type = "text/html"
}
