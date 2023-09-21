#!/usr/bin/env bash
set -e
_help() {
  cat << EOF
    $(basename "${BASH_SOURCE[0]}") [-h] [-p profile] [-r region]  [-h or ---help] [-p or --profile profilename] [-r or --region awsregion]

    s3-export-import script

    -m or --mode import|export|export-import    the mode to run in
    -dt or --db-type mysql|postgres             the database type to import/export from
    -sh or --source-db-host                     the source database host
    -th or --target-db-host                     the target database host
    -sd or --source-db-name                     the source database name
    -td or --target-db-name                     the target database name
    -su or --source-db-user                     the source database user
    -tu or --target-db-user                     the target database user
    -sp or --source-db-password                 the source database password
    -tp or --target-db-password                 the target database password
    -sb or --source-db-bucket                   the source database bucket
    -tb or --target-db-bucket                   the target database bucket
    -fn or --file-name                          the filename to use
    -s3p or --s3-prefix                         the s3 prefix to use
    -h, --help                                  print this help
    -v, --verbose                               verbose output


EOF
  exit
}

# some parameters will use Environment Variables if set
# otherwise will use the command line parameters

_params() {

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    -r | --region) # mode
        if [[ -v AWS_REGION ]]; then
            echo "AWS_REGION set as environment variable, using : $AWS_REGION"
        else
            $AWS_REGION="${2-}"
        fi
        shift
        ;;
    -m | --mode) # mode
        if [[ -v MODE ]]; then
            echo "MODE set as environment variable, using : $MODE"
        else
            $MODE="${2-}"
        fi
        shift
        ;;
    -dt | --db-type) # db type
        if [[ -v DB_TYPE ]]; then
            echo "DB_TYPE set as environment variable, using : $DB_TYPE"
        else
            $DB_TYPE="${2-}"
        fi
        shift
        ;;
    -sh | --source-db-host) # source db host
        if [[ -v SOURCE_DB_HOST ]]; then
            echo "SOURCE_DB_HOST set as environment variable, using : $SOURCE_DB_HOST"
        else
            $SOURCE_DB_HOST="${2-}"
        fi
        shift
        ;;
    -th | --target-db-host) # target db host
        if [[ -v TARGET_DB_HOST ]]; then
            echo "TARGET_DB_HOST set as environment variable, using : $TARGET_DB_HOST"
        else
            $TARGET_DB_HOST="${2-}"
        fi
        shift
        ;;
    -sd | --source-db-name) # source db name
        if [[ -v SOURCE_DB_NAME ]]; then
            echo "SOURCE_DB_NAME set as environment variable, using : $SOURCE_DB_NAME"
        else
            $SOURCE_DB_NAME="${2-}"
        fi
        shift
        ;;
    -td | --target-db-name) # target db name
        if [[ -v TARGET_DB_NAME ]]; then
            echo "TARGET_DB_NAME set as environment variable, using : $TARGET_DB_NAME"
        else
            $TARGET_DB_NAME="${2-}"
        fi
        shift
        ;;
    -su | --source-db-user) # source db user
        if [[ -v SOURCE_DB_USER ]]; then
            echo "SOURCE_DB_USER set as environment variable, using : $SOURCE_DB_USER"
        else
            $SOURCE_DB_USER="${2-}"
        fi
        shift
        ;;
    -tu | --target-db-user) # target db user
        if [[ -v TARGET_DB_USER ]]; then
            echo "TARGET_DB_USER set as environment variable, using : $TARGET_DB_USER"
        else
            $TARGET_DB_USER="${2-}"
        fi
        shift
        ;;
    -sp | --source-db-password) # source db password
        if [[ -v SOURCE_DB_PASSWORD ]]; then
            echo "SOURCE_DB_PASSWORD set as environment variable, using : $SOURCE_DB_PASSWORD"
        else
            $SOURCE_DB_PASSWORD="${2-}"
        fi
        shift
        ;;
    -tp | --target-db-password) # target db password
        if [[ -v TARGET_DB_PASSWORD ]]; then
            echo "TARGET_DB_PASSWORD set as environment variable, using : $TARGET_DB_PASSWORD"
        else
            $TARGET_DB_PASSWORD="${2-}"
        fi
        shift
        ;;
    -drop | --drop-tables) # drop tables
        if [[ -v DROP_TABLES ]]; then
            echo "DROP_TABLES set as environment variable, using : $DROP_TABLES"
        else
            $DROP_TABLES="${2-}"
        fi
        shift
        ;;
    -s3 | --s3-bucket) # s3 bucket
        if [[ -v S3_BUCKET ]]; then
            echo "S3_BUCKET set as environment variable, using : $S3_BUCKET"
        else
            $S3_BUCKET="${2-}"
        fi
        shift
        ;;
    -fn | --file-name) # file name
        if [[ -v FILE_NAME ]]; then
            echo "FILE_NAME set as environment variable, using : $FILE_NAME"
        else
            $FILE_NAME="${2-}"
        fi
        shift
        ;;
    -s3p | --s3-prefix) # s3 prefix
        if [[ -v S3_PREFIX ]]; then
            echo "S3_PREFIX set as environment variable, using : $S3_PREFIX"
        else
            $S3_PREFIX="${2-}"
        fi
        shift
        ;;
    -?*) echo "Option: $1 is not recognised"; exit 1 ;;
    *) break ;;
    esac
    shift
  done
  args=("$@")
  return 0
}

_params "$@"

# TODO: add way to get AWS credentials from other sources
get_aws_credentials() {
    echo ".."
## shouldn't need to do this if using AWS CLI - should get creds automatically from role.
#     if [[ -z $AWS_ACCESS_KEY_ID ]]; then
#         CREDS=\$(curl -s 169.254.170.2\$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)
#         AWS_ACCESS_KEY_ID=\$(echo \$CREDS | jq -r '.AccessKeyId')
#         AWS_SECRET_ACCESS_KEY=\$(echo \$CREDS | jq -r '.SecretAccessKey')
#         AWS_SESSION_TOKEN=\$(echo \$CREDS | jq -r '.Token')
#     fi
}

# TODO: get database credentaials from AWS Secrets Manager

# if variable is not set error else print varible value
test_var() {
    # if $1 is empty string
    if [[ -z $2 ]]; then
        echo "$1 not set"
        exit 1
    else
        echo "$1: $2"
    fi
}

# function to verify required parameters are set for import
# TODO: don't echo passwords
verify_import_params() {
    test_var "AWS_REGION" $AWS_REGION
    test_var "DB_TYPE" $DB_TYPE
    test_var "TARGET_DB_HOST" $TARGET_DB_HOST
    test_var "TARGET_DB_NAME" $TARGET_DB_NAME
    test_var "TARGET_DB_USER" $TARGET_DB_USER
    test_var "TARGET_DB_PASSWORD" $TARGET_DB_PASSWORD
    test_var "S3_BUCKET" $S3_BUCKET
    test_var "FILE_NAME" $FILE_NAME
}

verify_export_params() {
    test_var "AWS_REGION" $AWS_REGION
    test_var "DB_TYPE" $DB_TYPE
    test_var "SOURCE_DB_HOST" $SOURCE_DB_HOST
    test_var "SOURCE_DB_NAME" $SOURCE_DB_NAME
    test_var "SOURCE_DB_USER" $SOURCE_DB_USER
    test_var "SOURCE_DB_PASSWORD" $SOURCE_DB_PASSWORD
    test_var "S3_BUCKET" $S3_BUCKET
    test_var "FILE_NAME" $FILE_NAME
}

verify_exportimport_params() {
    test_var "AWS_REGION" $AWS_REGION
    test_var "DB_TYPE" $DB_TYPE
    test_var "SOURCE_DB_HOST" $SOURCE_DB_HOST
    test_var "SOURCE_DB_NAME" $SOURCE_DB_NAME
    test_var "SOURCE_DB_USER" $SOURCE_DB_USER
    test_var "SOURCE_DB_PASSWORD" $SOURCE_DB_PASSWORD
    test_var "TARGET_DB_HOST" $TARGET_DB_HOST
    test_var "TARGET_DB_NAME" $TARGET_DB_NAME
    test_var "TARGET_DB_USER" $TARGET_DB_USER
    test_var "TARGET_DB_PASSWORD" $TARGET_DB_PASSWORD
    test_var "FILE_NAME" $FILE_NAME
}

# todo verify option params
# verify_optional_params() {
#     if [[ -z $S3_PREFIX ]]; then
#         echo "$S3_PREFIX not set"
#     else

#     fi
# }

drop_db_tables() {
    # optional, empty tables in target db before import (otherwise can cause errors)
    echo "emptying tables in $TARGET_DB_NAME"
    # run mysql queries to get all the table names in the database
    tables=$(mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -Nse "show tables")
    # disable foreign key checks
    mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -e "SET FOREIGN_KEY_CHECKS = 0;"
    # loop through table names and truncate each table
    for table in $tables; do
        echo droping table $table
        mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -e "SET FOREIGN_KEY_CHECKS = 0; DROP TABLE $table"
    done
    # enable foreign key checks
    mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -e "SET FOREIGN_KEY_CHECKS = 1;"
}

# export from source db
run_export() {
    echo "exporting $SOURCE_DB_NAME database to $FILE_NAME"
    mysqldump -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME > $FILE_NAME
    # TODO: support other DB TYPES
    # if [[ $DB_TYPE == "mysql" ]]; then
    #     mysqldump -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME > $FILE_NAME
    # elif [[ $DB_TYPE == "postgres" ]]; then
    #
    # fi
}

run_import() {
    echo "importing $FILE_NAME to $TARGET_DB_NAME"
    if [[ $DROP_TABLES == "true" ]]; then
        drop_db_tables
    fi
    # disable foreign key checks
    mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -e "SET FOREIGN_KEY_CHECKS = 0;"
    # import
    mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME < $FILE_NAME
    # enable foreign key checks
    mysql -h $TARGET_DB_HOST -u $TARGET_DB_USER -p$TARGET_DB_PASSWORD $TARGET_DB_NAME -e "SET FOREIGN_KEY_CHECKS = 1;"
    # # TODO: support other DB TYPES
    # if [[ $DB_TYPE == "mysql" ]]; then
    #     mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME < $FILE_NAME
    # elif [[ $DB_TYPE == "postgres" ]]; then
    #
    # fi
}

# upload to s3
upload_to_s3() {
    echo "uploading $FILE_NAME to s3://$S3_BUCKET/$S3_PREFIX$FILE_NAME"
    aws --region $AWS_REGION s3 cp  $FILE_NAME s3://$S3_BUCKET/$S3_PREFIX$FILE_NAME
}

# download from s3
download_from_s3() {
    echo "downloading $FILE_NAME from s3://$S3_BUCKET/$S3_PREFIX$FILE_NAME"
    aws --region $AWS_REGION  s3 cp s3://$S3_BUCKET/$S3_PREFIX$FILE_NAME $FILE_NAME
}

# if mode varible is not set then exit, if set to import run import, if set to export run export
if [[ -z $MODE ]]; then
    echo "mode not set"
    exit 1
elif [[ $MODE == "import" ]]; then
    echo "mode set to import"
    get_aws_credentials
    verify_import_params
    download_from_s3
    run_import
elif [[ $MODE == "export" ]]; then
    echo "mode set to export"
    get_aws_credentials
    verify_export_params
    run_export
    upload_to_s3
elif [[ $MODE == "export-import" ]]; then
    echo "mode set to export-import"
    # TODO: add export-import function
    #verify_exportimport_params
    #run_exportimport
else
    echo "mode not recognised"
    exit 1
fi

echo "finished"
exit 0