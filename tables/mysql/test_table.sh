#!/usr/bin/env bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../_SOURCE_FILE.sh

TABLE_NAME=$(getIfValid "${TABLE}" "ods_user")

WHERE_CONDITION=""
if [ "${IS_ALL}" != "true" ];then
    WHERE_CONDITION="WHERE update_time >= ${START_TS} AND update_time < ${END_TS}"
fi

mysqlSql="SELECT a FROM my_db.test_table ${WHERE_CONDITION}"

DoExportFrom53ToMysql "${DB_NAME}.${TABLE_NAME}" "${mysqlSql}"  "$PWD/`basename $0`"
