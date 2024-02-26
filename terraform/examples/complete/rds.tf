# # RDS 서브넷 1
# resource "aws_subnet" "rds_subnet_1" {
#   vpc_id            = aws_vpc.amz_draw_vpc.id
#   cidr_block        = "192.168.5.0/24" # Start from a higher range
#   availability_zone = var.azs[0]
#   tags = {
#     Name = "${var.infra_name}-rds-1"
#   }
#   depends_on = [ aws_subnet.private_subnet_1 ]
# }

# # RDS 서브넷 2
# resource "aws_subnet" "rds_subnet_2" {
#   vpc_id            = aws_vpc.amz_draw_vpc.id
#   cidr_block        = "192.168.6.0/24"  # Ensure there's no overlap
#   availability_zone = var.azs[1]
#   tags = {
#     Name = "${var.infra_name}-rds-2"
#   }
#   depends_on = [ aws_subnet.private_subnet_2 ]
# }


# # DB(RDS) 서브넷 그룹 생성
# resource "aws_db_subnet_group" "rds_subnet_group" {
#   name        = "ecommerce-seoul-mariadb-subnet-group"
#   subnet_ids  = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]
#   tags = {
#     Name = "My_DB_Subnet_Group"
#   }
# }

# # 라우팅 테이블에 서브넷 ID 연결 ( 퍼블릭 서브넷 )
# resource "aws_route_table_association" "rds_subnet_1_association" {
#   subnet_id      = aws_subnet.rds_subnet_1.id
#   route_table_id = aws_route_table.private_rt.id

# }

# # 라우팅 테이블에 서브넷 ID 연결 ( 퍼블릭 서브넷 )
# resource "aws_route_table_association" "rds_subnet_2_association" {
#   subnet_id      = aws_subnet.rds_subnet_2.id
#   route_table_id = aws_route_table.private_rt.id
# }

# RDS 인스턴스 생성
# resource "aws_db_instance" "default" {
#   allocated_storage    = 20
#   storage_type         = "gp2"
#   engine               = "mariadb"
#   engine_version       = "10.6.14"  # MariaDB 엔진 버전을 확인하세요
#   instance_class       = "db.t3.medium"
#   identifier           = "amzdraw-seoul-mariadb"  # 데이터베이스 인스턴스 식별자
#   db_name              = "amzdraw-DB"  # 데이터베이스 이름
#   username             = "dohyungjunyong"
#   password             = "dohyungjunyong"
#   parameter_group_name = "default.mariadb10.6"  # MariaDB에 맞는 파라미터 그룹
#   db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
#   skip_final_snapshot  = true
# }