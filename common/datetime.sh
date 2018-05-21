#!/usr/bin/env bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/color.sh

function getDiffDay()
{
    local someDate=$1
    local diffDays=$2
    echo $(date +%Y%m%d -d "${someDate} ${diffDays} days")
    return 0
}

# 根据提供的日期(Ymd)获取该月的第一天日期(Ymd)
function getFirstDayOfMonth()
{
    local someDate=$1
    local thisYearMonth=`date +"%Y%m" -d "${someDate}"`
    local firstDayOfDate="${thisYearMonth}01"

    echo $firstDayOfDate
    return 0
}

# 根据提供的日期(Ymd)获取该月的总天数
function getTotalDaysOfMonth()
{
    local someDate=$1
    local totalDays=`cal $(date +"%m %Y" -d "${someDate}") | awk 'NF {DAYS = $NF}; END {print DAYS}'`

    echo $totalDays
    return 0
}

# 根据提供的日期(Ymd)获取该月的最后一天的日期(Ymd)
function getLastDayOfMonth()
{
    local someDate=$1
    local addOneDay=$2

    local totalDays=$(getTotalDaysOfMonth "${someDate}")
    local thisYearMonth=`date +"%Y%m" -d "${someDate}"`
    local lastDayOfDate="${thisYearMonth}${totalDays}"

    if [ "${addOneDay}" = "y" ];then
        echo $(getDiffDay ${lastDayOfDate} 1)
    else
        echo $lastDayOfDate
    fi
    return 0
}

# 根据提供的日期(Ymd)获取该年的第一天日期(Ymd)
function getFirstDayOfYear()
{
    local someDate=$1
    echo $(date +%Y0101 -d ${someDate})
    return 0
}

# 根据提供的日期(Ymd)获取该年的最后一天日期(Ymd)
function getLastDayOfYear()
{
    local someDate=$1
    local addOneDay=$2

    local lastDay=$(date +%Y1231 -d ${someDate})
    if [ "${addOneDay}" = "y" ];then
        echo $(getDiffDay ${lastDay} 1)
    else
        echo $lastDay
    fi
    return 0
}

# 根据提供的日期(Ymd)获取该周的第一天日期(Ymd)
function getFirstDayOfWeek()
{
    local someDate=$1
    local weekDay=$(date +%u -d ${someDate})
    if [ $weekDay -eq 1 ];then
        echo $someDate
    else
        local addDays=$(( $weekDay - 1))
        echo $(date +%Y%m%d -d "${someDate} -${addDays} days")
    fi
    return 0
}

# 根据提供的日期(Ymd)获取该周的最后一天日期(Ymd)
function getLastDayOfWeek()
{
    local someDate=$1
    local addOneDay=$2
    local firstDay=$(getFirstDayOfWeek $someDate)
    local addDays=6

    if [ "${addOneDay}" = "y" ];then
        addDays=7
    fi
    echo $(getDiffDay ${firstDay} ${addDays})

    return 0
}

# 根据提供的日期以及改日期的格式获取时间
# $1 提供的时间
# $2 是否是结束时间（yes or no）
function getDate()
{
    local someDate=$1
    local addNext=$2
    local formattedDate=''

    local someDateLength=${#someDate}
    case "${someDateLength}" in

        #如果提供了完整的时间(Ymd)：20171221，开始时间就是该天：20171221，结束时间则是是第二天：20171222
        8)
            formattedDate=$someDate
            if [ "${addNext}" = "yes" ];then
                formattedDate=`date +"%Y%m%d" -d "${formattedDate} + 1day"`
            fi
            ;;

        #如果只提供了年月(Ym)：201712，开始时间就是该月的第一天：20171201，结束时间则是下个月第一天：20180101
        6)
            formattedDate="${someDate}01"
            if [ "${addNext}" = "yes" ];then
                formattedDate=$(getLastDayOfMonth "${formattedDate}")
                formattedDate=`date +"%Y%m%d" -d "${formattedDate} +1 day"`
            fi
            ;;

        #如果只提供了年(Y)：2017，开始时间就是该年的第一天：20170101，结束时间则是第二年的第一天：20180101
        4)
            formattedDate="${someDate}0101"
            if [ "${addNext}" = "yes" ];then
                formattedDate="${someDate}1231"
                formattedDate=`date +"%Y%m%d" -d "${formattedDate} +1 day"`
            fi
            ;;

        #否则开始时间是昨天，结束时间是今天
        *)
            formattedDate=`date +%Y%m%d -d '-1day'`
            if [ "${addNext}" = "yes" ];then
                formattedDate=`date +%Y%m%d`
            fi
            ;;
    esac

    echo $formattedDate
    return 0
}

function strToTime()
{
    local timeString="$1"
    if [ "${timeString}" != "" ] && [[ $timeString =~ [^[:digit:]] ]];then
        echo `date +%Y%m%d -d "${timeString}"`
    else
        echo $timeString
    fi
    return 0
}

function RunCommandByRange()
{
    local start=$1
    local end=$2
    local command=$3
    local format=$4
    local params=$5
    local run=$6
    local sleep=$7

    local startTs=`date +%s -d "${start}"`
    local endTs=`date +%s -d "${end}"`
    local days=$(( ($endTs - $startTs)/86400 + 1 ))
    local count=0

    end=`date -d "+1 day $end" +%Y%m%d`
    while [[ $start -lt $end ]]
    do
        count=$(( $count+1 ))
        runCommand="${command} ${format}${start} ${params}"
        echo
        echo -e "   ${COLOR_PURPLE}=> [${count}/${days}]${COLOR_END} ${COLOR_UL_CYAN}${runCommand}${COLOR_END}"
        [ "$run" != "false" ] || ${runCommand}
        wait
        start=`date -d "+1 day $start" +%Y%m%d`
        sleep $sleep
    done
}