#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/server.sh
source ${CURRENT_DIR}/tools.sh
source ${CURRENT_DIR}/config.sh

function printDateRange() {
    if [ "${IS_ALL}" = "true" ];then
        writeLog "ALL DATA"
    else
        writeLog "${START_HOUR_DATETIME} ~ ${END_HOUR_DATETIME}"
    fi
}

function printFinalResult() {
    local RETURN_CODE=$1
    local TOTAL_RUN_TIME=$2

    if [ ${RETURN_CODE} -eq 0 ];then
        writeLog "${COLOR_GREEN}Success: ${TOTAL_RUN_TIME}s${COLOR_END}"
    else
        writeLog "${COLOR_RED}Fail: ${TOTAL_RUN_TIME}s${COLOR_END}"
    fi
}

function printETLSignal() {
    echo "success"
}

function getMysqlClient() {
    local mysqlHost=$1
    # 如果不传mysql服务器，则选用env中的TARGET_MYSQL_HOST
    if [ "${mysqlHost}" = "" ];then
        mysqlHost=$DB_HOST
    fi
    case $mysqlHost in
        14)
            echo "${S14_MYSQL}"
            ;;
        89)
            echo "${S89_MYSQL}"
            ;;
        53)
            echo "${S53_MYSQL}"
            ;;
        54)
            echo "${S54_MYSQL}"
            ;;
        * )
            echo ""
            ;;
    esac

    return 0
}

function getServerClient() {
    local serverHost=$1
    case $serverHost in
        88)
            echo "${S88_CLIENT}"
            ;;
        * )
            echo ""
            ;;
    esac

    return 0
}

function DoExportFromHiveToMysql() {
    local targetMysqlTableName=$1
    local hiveSql=$2
    local scriptFile=$3
    local mysqlHost=$4

    local mysqlClient=$(getMysqlClient "${mysqlHost}")
    if [ "${mysqlClient}" = "" ];then
        echo "DB host is not provided!"
        exit
    fi

    # 如果表名不包含数据库名，则默认使用env中的TARGET_MYSQL_DB
    if [[ $targetMysqlTableName != *"."* ]]; then
        targetMysqlTableName="${DB_NAME}.${targetMysqlTableName}"
    fi

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    exportFromHiveToMysql "${mysqlClient}" "${targetMysqlTableName}" "${hiveSql}" "${scriptFile}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoRunOnMysql()
{
    local mysqlSql=$1
    local scriptFile=$2
    local mysqlHost=$3

    mysqlClient=$(getMysqlClient "${mysqlHost}")
    if [ "${mysqlClient}" = "" ];then
        echo "DB host is not provided!"
        exit
    fi

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    runOnMysql "${mysqlClient}" "${mysqlSql}" "" "${scriptFile}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoRunOnHive()
{
    local hiveSql=$1
    local scriptFile=$2

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    runOnHive "${hiveSql}" "/dev/null" "${scriptFile}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoExportFromMysqlToMysql()
{
    local sourceMysqlHost=$1
    local targetMysqlTableName=$2
    local mysqlSql=$3
    local scriptFile=$4
    local targetMysqlHost=$5

    local sourceMysqlClient=$(getMysqlClient "${sourceMysqlHost}")
    local targetMysqlClient=$(getMysqlClient "${targetMysqlHost}")
    if [ "${targetMysqlClient}" = "" ];then
        echo "DB host is not provided!"
        exit
    fi

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    exportFromMysqlToMysql "${sourceMysqlClient}" "${targetMysqlClient}" "${targetMysqlTableName}" "${mysqlSql}" "${scriptFile}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoExportFrom53ToMysql()
{
    local targetMysqlTableName=$1
    local mysqlSql=$2
    local scriptFile=$3
    local targetMysqlHost=$4

    DoExportFromMysqlToMysql 53 "${targetMysqlTableName}" "${mysqlSql}" "${scriptFile}" "${targetMysqlHost}"
}

# 54和89是同一台服务器
function DoExportFrom89ToMysql()
{
    local targetMysqlTableName=$1
    local mysqlSql=$2
    local scriptFile=$3
    local targetMysqlHost=$4

    DoExportFromMysqlToMysql 89 "${targetMysqlTableName}" "${mysqlSql}" "${scriptFile}" "${targetMysqlHost}"
}

function DoScpFileToMysql()
{
    local sourceServer=$1
    local tableName=$2
    local sourceFile=$3
    local scriptFile=$4
    local targetMysqlHost=$5

    local targetFile="/tmp/scp_file_`date +%s`.txt"
    local serviceClient=$(getServerClient "${sourceServer}")
    if [ "${serviceClient}" = "" ];then
        echo "Server host is not provided!"
        exit
    fi

    local targetMysqlClient=$(getMysqlClient "${targetMysqlHost}")
    if [ "${targetMysqlClient}" = "" ];then
        echo "DB host is not provided!"
        exit
    fi

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    scpFromServerToMysql "${serviceClient}" "${targetMysqlClient}" "${tableName}" "${sourceFile}" "${scriptFile}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoScpFrom88ToMysql()
{
    local tableName=$1
    local sourceFile=$2
    local scriptFile=$3
    local targetMysqlHost=$4

    DoScpFileToMysql 88 "${tableName}" "${sourceFile}" "${scriptFile}" "${targetMysqlHost}"
}

function DoExportFromMysqlToHive()
{
    local sourceMysqlHost=$1
    local targetHiveTableName=$2
    local mysqlSql=$3
    local scriptFile=$4
    local hivePartition=$5
    local sourceMysqlClient=$(getMysqlClient "${sourceMysqlHost}")

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    exportFromMysqlToHive "${sourceMysqlClient}" "${targetHiveTableName}" "${mysqlSql}" "${scriptFile}" "${hivePartition}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoExportFrom89ToHive() {
    local targetHiveTableName=$1
    local mysqlSql=$2
    local scriptFile=$3
    local hivePartition=$4

    DoExportFromMysqlToHive 89 "${targetHiveTableName}" "${mysqlSql}" "${scriptFile}" "${hivePartition}"
}

function DoExportFrom53ToHive() {
    local targetHiveTableName=$1
    local mysqlSql=$2
    local scriptFile=$3
    local hivePartition=$4

    DoExportFromMysqlToHive 53 "${targetHiveTableName}" "${mysqlSql}" "${scriptFile}" "${hivePartition}"
}

function DoExportFromHiveToHive()
{
    local targetHiveTableName=$1
    local hiveSql=$2
    local scriptFile=$3
    local hivePartition=$4

    writeDim
    printDateRange
    local startRunAt=`date +%s`

    exportFromHiveToHive "${targetHiveTableName}" "${hiveSql}" "${scriptFile}" "${hivePartition}"
    RETURN_CODE=$?

    local endRunAt=`date +%s`
    local totalRunSeconds=$[ $endRunAt - $startRunAt ]
    printFinalResult ${RETURN_CODE} ${totalRunSeconds}
    writeDim
    printETLSignal
    return $RETURN_CODE
}

function DoTruncateHiveTable() {
    local tableName=$1
    local scriptFile=$2
    local hiveSql="TRUNCATE TABLE ${tableName}"
    DoRunOnHive "${hiveSql}" "${scriptFile}"
}