#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/tools.sh
source ${CURRENT_DIR}/notice.sh
source ${CURRENT_DIR}/color.sh

PRJ_TEMP_PATH=/tmp

function removeFile() {
    local filePath=$1
    [ -e ${filePath} ] && rm -rf ${filePath}
    return $?
}

function getFileRows() {
    local filePath=$1
    local lines=$(wc -l ${filePath} |  awk {'print $1'})
    echo $lines
}

function getFileSize() {
    local filePath=$1
    local size=$(ls -lah ${filePath} | awk -F " " {'print $5'})
    echo $size
}

function scpFromServer()
{
    local serverClient=$1
    local sourceFile=$2
    local targetFile=$3
    local scriptFile=$4

    local errorFile="${PRJ_TEMP_PATH}/scp_error_`date +%s`.txt"
    if scp ${serverClient}:${sourceFile} ${targetFile} 2>${errorFile} > /dev/null;then
        local lines=$(getFileRows "${targetFile}")
        local size=$(getFileSize "${targetFile}")
        local message="${targetFile}: ${COLOR_UL_CYAN} ${lines} ${COLOR_END} rows (${COLOR_UL_CYAN} ${size} ${COLOR_END})"
        writeLog "${message}"
        if [ $lines -le 0 ];then
            [ "${SILENT}" = "false" ] && sendNotify "Scp file is empty" "${targetFile}" "${message}" "${scriptFile}"
            removeFile "${targetFile}"
            return 1
        else
            return 0
        fi
    else
        local errorMessage=`cat ${errorFile}`
        writeLog "${COLOR_RED}!!SCP ERROR!! ${errorMessage}${COLOR_END}"
        [ "${SILENT}" = "false" ] && sendNotify "Scp Error" "${sourceFile}" "${errorMessage}" "${scriptFile}"
        removeFile "${targetFile}"
        return 1
    fi
}

function scpFromServerToMysql()
{
    local serverClient=$1
    local mysqlClient=$2
    local tableName=$3
    local sourceFile=$4
    local scriptFile=$5
    local targetFile="${PRJ_TEMP_PATH}/scp_file_`date +%s`.txt"

    if scpFromServer "${serverClient}" "${sourceFile}" "${targetFile}" "${scriptFile}";then
        if loadIntoMysql "${mysqlClient}" "${tableName}" "${targetFile}" "${sourceFile}";then
            removeFile "${targetFile}"
            return 0
        else
            removeFile "${targetFile}"
            return 1
        fi
    else
        removeFile "${targetFile}"
        return 1
    fi
}

function runOnMysql()
{
    local mysqlClient=$1
    local runSql=$2
    local outputFile=$3
    local scriptFile=$4

    local errorFile="${PRJ_TEMP_PATH}/run_mysql_error_`date +%s`.txt"
    if [ "${outputFile}" = "" ];then
        outputFile=$errorFile
    fi

    writeLog "${runSql}"
    if mysql ${mysqlClient} --default-character-set=utf8 -N -e "${runSql}" 2>${errorFile} > ${outputFile}
    then
        removeFile "${errorFile}"
        return 0
    else
        local errorMessage=`cat ${errorFile}`
        writeLog "${COLOR_RED}!!MYSQL ERROR!! ${errorMessage}${COLOR_END}"
        [ "${SILENT}" = "false" ] && sendNotify "MySQL Run Error" "${runSql}" "${errorMessage}" "${scriptFile}"
        removeFile "${errorFile}"
        return 1
    fi
}

function runOnHive()
{
    local hiveSql=$1
    local outputFile=$2
    local scriptFile=$3

    local errorFile="${PRJ_TEMP_PATH}/run_hive_error_`date +%s`.txt"
    if [ "${outputFile}" = "" ];then
        outputFile=$errorFile
    fi

    writeLog "${hiveSql}"
    if hive -e "set hive.auto.convert.join=false;${hiveSql}" 2>${errorFile} > ${outputFile}
    then
        removeFile "${errorFile}"
        return 0
    else
        local errorMessage=`cat ${errorFile}`
        local hiveError=`echo $errorMessage | cut -d \[ -f 2`
        hiveError="[${hiveError}"

        writeLog "${COLOR_RED}!!HIVE ERROR!! ${hiveError}${COLOR_END}"
        [ "${SILENT}" = "false" ] && sendNotify "Hive Run Error" "${hiveSql}" "${hiveError}" "${scriptFile}"
        removeFile "${errorFile}"
        return 1
    fi
}

function exportFromHive()
{
    local hiveSql=$1
    local exportFile=$2
    local scriptFile=$3

    if runOnHive "${hiveSql}" "${exportFile}" "${scriptFile}"
    then
        local lines=$(getFileRows "${exportFile}")
        local size=$(getFileSize "${exportFile}")
        local message="${exportFile}: ${COLOR_UL_CYAN} ${lines} ${COLOR_END} rows (${COLOR_UL_CYAN} ${size} ${COLOR_END})"
        writeLog "${message}"
        if [ $lines -le 0 ];then
            [ "${SILENT}" = "false" ] && sendNotify "File dumped from Hive is empty" "${hiveSql}" "${message}" "${scriptFile}"
            removeFile "${exportFile}"
            return 1
        else
            return 0
        fi
    else
        removeFile "${exportFile}"
        return 1
    fi
}

function exportFromMysql()
{
    local mysqlClient=$1
    local mysqlSql=$2
    local exportFile=$3
    local scriptFile=$4

    if runOnMysql "${mysqlClient}" "${mysqlSql}" "${exportFile}" "${scriptFile}"
    then
        local lines=$(getFileRows "${exportFile}")
        local size=$(getFileSize "${exportFile}")
        local message="${exportFile}: ${COLOR_UL_CYAN} ${lines} ${COLOR_END} rows (${COLOR_UL_CYAN} ${size} ${COLOR_END})"
        writeLog "${message}"
        if [ $lines -le 0 ];then
            [ "${SILENT}" = "false" ] && sendNotify "File dumped from MySQL is empty" "${mysqlSql}" "${message}" "${scriptFile}"
            removeFile "${exportFile}"
            return 1
        else
            return 0
        fi
    else
        removeFile "${exportFile}"
        return 1
    fi
}

function loadIntoHive()
{
    local tableName=$1
    local filePath=$2
    local scriptFile=$3
    local partition=$4

    if runOnHive "LOAD DATA LOCAL INPATH '$filePath' OVERWRITE INTO TABLE $tableName ${partition};" "" "$scriptFile"
    then
        writeLog "Load file ${filePath} into [Hive]${tableName} success!"
        removeFile "${filePath}"
        return 0
    else
        writeLog "${COLOR_RED}!!Load file ${filePath} into [Hive]${tableName} failed!${COLOR_END}"
        removeFile "${filePath}"
        return 1
    fi
}

function loadIntoMysql()
{
    local mysqlClient=$1
    local tableName=$2
    local filePath=$3
    local scriptFile=$4

    local mysqlHost=$(echo "${mysqlClient}" | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+')

    if runOnMysql "${mysqlClient}" "LOAD DATA LOCAL INFILE '$filePath' REPLACE INTO TABLE $tableName;" "" "$scriptFile"
    then
        writeLog "Load file ${filePath} into [MySQL-${mysqlHost}]${tableName} success!"
        removeFile "${filePath}"
        return 0
    else
        writeLog "${COLOR_RED}!!Load file ${filePath} into [MySQL-${mysqlHost}]${tableName} failed!${COLOR_END}"
        removeFile "${filePath}"
        return 1
    fi
}

function exportFromMysqlToMysql()
{
    local sourceMysqlClient=$1
    local targetMysqlClient=$2
    local targetMysqlTableName=$3
    local mysqlSql=$4
    local scriptFile=$5

    local nowTs=`date +%s`
    local exportFile="${PRJ_TEMP_PATH}/${targetMysqlTableName}_${nowTs}.txt"

    if exportFromMysql "${sourceMysqlClient}" "${mysqlSql}" "${exportFile}" "${scriptFile}";then
        if loadIntoMysql "${targetMysqlClient}" "${targetMysqlTableName}" "${exportFile}" "${scriptFile}";then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function exportFromHiveToMysql()
{
    local targetMysqlClient=$1
    local targetMysqlTableName=$2
    local hiveSql=$3
    local scriptFile=$4

    local nowTs=`date +%s`
    local exportFile="${PRJ_TEMP_PATH}/${targetMysqlTableName}_${nowTs}.txt"

    if exportFromHive "${hiveSql}" "${exportFile}" "${scriptFile}";then
        if loadIntoMysql "${targetMysqlClient}" "${targetMysqlTableName}" "${exportFile}" "${scriptFile}";then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function exportFromHiveToHive()
{
    local targetHiveTableName=$1
    local hiveSql=$2
    local scriptFile=$3
    local hivePartition=$4

    local nowTs=`date +%s`
    local exportFile="${PRJ_TEMP_PATH}/${targetHiveTableName}_${nowTs}.txt"

    if exportFromHive "${hiveSql}" "${exportFile}" "${scriptFile}";then
        if loadIntoHive "${targetHiveTableName}" "${exportFile}" "${scriptFile}" "${hivePartition}";then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function exportFromMysqlToHive()
{
    local sourceMysqlClient=$1
    local targetHiveTableName=$2
    local mysqlSql=$3
    local scriptFile=$4
    local hivePartition=$5

    local nowTs=`date +%s`
    local exportFile="${PRJ_TEMP_PATH}/${targetHiveTableName}_${nowTs}.txt"

    if exportFromMysql "${sourceMysqlClient}" "${mysqlSql}" "${exportFile}" "${scriptFile}";then
        if loadIntoHive "${targetHiveTableName}" "${exportFile}" "${scriptFile}" "${hivePartition}";then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}