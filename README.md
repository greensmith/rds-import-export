# rds-import-export

container to import / export RDS databases on AWS.

- currently only runs on fargate containers
- currently only supports import OR export of MySQL RDS
- todo: other container types
- todo: other db types.
- todo: export and import between two dbs

## environment variables used

- AWS_REGION: the aws region used (required for S3 bucket to work)
- DB_TYPE: the db type (e.g. mysql)
- SOURCE_DB_HOST: the host address for the db export
- SOURCE_DB_NAME: db to export
- SOURCE_DB_USER: username for db export
- SOURCE_DB_PASSWORD: password for db export
- TARGET_DB_HOST: the host address for the db import
- TARGET_DB_NAME: db to import
- TARGET_DB_USER: username for db import
- TARGET_DB_PASSWORD: password for db import
- FILE_NAME: the file name to use (e.g. myfile.sql)
- S3_PREFIX: optional, a prefix to use (e.g. data/export/)

## example fargate task definition

``` json
{
  "family": "dump-mysql-db-task-def",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "dump-mysql-db-container",
      "image": "greensmith/rds-import-export:latest",
      "essential": true,
      "linuxParameters": {
          "initProcessEnabled": true
      },
      "environment": [
        {
        "name":"MODE",
        "value": "export"
        },
        {
        "name":"DB_TYPE",
        "value": "mysql"
        },
        {
        "name":"SOURCE_DB_HOST",
        "value": "source-rds-hostname.us-east-1.rds.amazonaws.com"
        },
        {
        "name":"SOURCE_DB_NAME",
        "value": "sourcedb"
        },
        {
          "name": "SOURCE_DB_PORT",
          "value": "3306"
        },
        {
        "name":"TARGET_DB_HOST",
        "value": "target-rds-hostname.us-east-1.rds.amazonaws.com"
        },
        {
        "name":"TARGET_DB_NAME",
        "value": "targetdb"
        },
        {
          "name": "TARGET_DB_PORT",
          "value": "3306"
        },
        {
          "name": "S3_BUCKET",
          "value": "my_s3_bucket"
        },
        {
        "name":"S3_PREFIX",
        "value": "myexports/"
        },
        {
        "name":"FILE_NAME",
        "value": "filename.sql"
        },
        {
          "name": "AWS_REGION",
          "value": "us-east-1"
        }
      ],
      "secrets":[
        {
          "name": "SOURCE_DB_USER",
          "valueFrom": "secret_arn:username::"
        },
        {
          "name": "SOURCE_DB_PASSWORD",
          "valueFrom": "secret_arn:password::"
        },
        {
          "name": "TARGET_DB_USER",
          "valueFrom": "secret_arn:username::"
        },
        {
          "name": "TARGET_DB_PASSWORD",
          "valueFrom": "secret_arn:password::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/dump-mysql-db",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "dump-mysql-db"
        }
      }
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "task_exec_role",
  "taskRoleArn": "task_role"
}
```