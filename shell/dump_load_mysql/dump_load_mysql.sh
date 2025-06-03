#!/bin/bash

# ============================================
# 腳本名稱：dump_load_mysql.sh
#
# 說明：
#   此工具腳本可用來將 MySQL 資料表匯出成 .sql 檔案，
#   或將 .sql 檔案匯入至 MySQL 資料庫中。
#
# 使用方式：
#   ./dump_load_mysql.sh (dump|load)
#
#   - dump：將 MySQL 資料表匯出為個別的 .sql 檔案
#   - load：將 .sql 檔案逐一匯入至 MySQL 資料庫
#
# 注意事項：
#   - 請先在腳本中設定以下變數，才能正確連線資料庫與操作檔案：
#
#     MYSQL_HOST                     # 資料庫主機位址（例如：127.0.0.1）
#     MYSQL_PORT                     # 資料庫連接埠（例如：3306）
#     MYSQL_DATABASE                 # 目標資料庫名稱
#     MYSQL_USER                     # 資料庫使用者名稱
#     MYSQL_PASSWORD                 # 資料庫密碼
#     SQL_FILES_DIR                  # 存放 .sql 檔案的目錄（例如：/path/to/sqls）
#
#     EXCLUDED_TABLES                # （可選）不需匯出的資料表名稱清單，預設為空。
#                                    # 例如：EXCLUDED_TABLES=("logs" "temp_data")
#                                    # dump 時這些資料表將會被略過不匯出。
#
#   - 使用 load 指令時，會讀取 SQL_FILES_DIR 中所有副檔名為 .sql 的檔案並載入。
#   - 使用 dump 指令時，會將每個資料表分別匯出為一個 .sql 檔案，儲存在 SQL_FILES_DIR。
#
# 使用範例：
#   ./dump_load_mysql.sh dump
#   ./dump_load_mysql.sh load
# ============================================


MYSQL_HOST=''
MYSQL_PORT=''
MYSQL_DATABASE=''
MYSQL_USER=''
MYSQL_PASSWORD=''
SQL_FILES_DIR=''
EXCLUDED_TABLES=()

dump() {
    for table in $(mysql -h $MYSQL_HOST --port $MYSQL_PORT -u $MYSQL_USER -p"$MYSQL_PASSWORD" -Nse "SHOW TABLES" $MYSQL_DATABASE); do
        if [[ " ${EXCLUDED_TABLES[@]} " =~ " $table " ]]; then
            echo "Skipping excluded table: $table"
            continue
        fi

        echo "Exporting table: $table"
        mysqldump -h $MYSQL_HOST --port $MYSQL_PORT -u $MYSQL_USER -p"$MYSQL_PASSWORD" --no-create-info $MYSQL_DATABASE "$table" > "${SQL_FILES_DIR}/${table}.sql"
        echo
    done
}

load() {
    for sql_file in "$SQL_FILES_DIR"/*.sql; do
        if [[ -f "$sql_file" ]]; then
            echo "Importing SQL file: $sql_file"
            table="$(basename "$sql_file" .sql)"
            mysql -h $MYSQL_HOST --port $MYSQL_PORT -u $MYSQL_USER -p"$MYSQL_PASSWORD" -Ne "SET FOREIGN_KEY_CHECKS = 0;TRUNCATE TABLE $table;SET FOREIGN_KEY_CHECKS = 1;" $MYSQL_DATABASE
            mysql -h $MYSQL_HOST --port $MYSQL_PORT -u $MYSQL_USER -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < "$sql_file"

            if [[ $? -ne 0 ]]; then
                echo "Failed to import $sql_file"
            fi

            echo
        fi
    done
}

# Check if the user provided an argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <type>"
    echo "Valid types: dump, load"
    exit 1
fi

# Get the type argument
type="$1"

# Call the appropriate function based on the type
case "$type" in
    dump)
        dump
        ;;
    load)
        load
        ;;
    *)
        echo "Error: Invalid type '$type'. Valid types are: dump, load"
        exit 1
        ;;
esac