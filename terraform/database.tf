resource "aws_db_subnet_group" "sub_strapi" {
  #name       = "strapi-db-docker-subnet"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "strapi" {
  identifier              = "docker-strapi-postgres"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  db_name                 = "strapi"
  username                = "strapi"
  password                = "StrapiPassword123!"
  port                    = 5432

  publicly_accessible     = true
  skip_final_snapshot     = true

  vpc_security_group_ids  = [aws_security_group.strapi_sg.id] 

}
