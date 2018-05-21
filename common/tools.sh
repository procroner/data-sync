#!/usr/bin/env bash

LOG_FILE_PATH="/tmp/logs/bi_sync"

function writeLog()
{
    local message=$1
    local showDate=$2

    local today=`date +%Y%m%d`
    local logFile="${LOG_FILE_PATH}/bi_sync_${today}.log"
    local runTime=`date +"%F %T"`

    [ ! -d $LOG_FILE_PATH ] && mkdir -p $LOG_FILE_PATH
    [ ${USER} = `stat -c '%U' ${logFile}` ] && chmod 777 $logFile

    if [ "${showDate}" != "no" ];then
         message="${runTime} => ${message}"
    fi

    echo -e $message >> $logFile
    echo -e $message

    return 0
}

function writeDim()
{
    local hostIP=`hostname --ip-address`
    writeLog "====================================== ${USER}@${hostIP} ======================================" "no"
    return 0
}