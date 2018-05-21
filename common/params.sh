#!/usr/bin/env bash

# 处理时间字符串
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/datetime.sh
source ${CURRENT_DIR}/color.sh
source ${CURRENT_DIR}/../env.sh

function usage() {
    echo -e ""
    echo -e "      ${COLOR_CYAN}-t, --test${COLOR_END}         开启测试，启用该选项后打印开始时间和结束时间，不执行脚本"
    echo -e "      ${COLOR_CYAN}-s, --silent${COLOR_END}       关闭钉钉失败通知"
    echo -e "      ${COLOR_CYAN}    --dev${COLOR_END}          钉钉通知启用测试token"
    echo -e "      ${COLOR_CYAN}    --dt${COLOR_END}           运行某天的数据，默认今天，比--start和--end优先"
    echo -e "      ${COLOR_CYAN}    --start${COLOR_END}        开始时间，可选，默认昨天"
    echo -e "      ${COLOR_CYAN}    --end${COLOR_END}          结束时间，可选，默认今天"
    echo -e "      ${COLOR_CYAN}    --hour${COLOR_END}         小时"
    echo -e "      ${COLOR_CYAN}    --all${COLOR_END}          所有数据"
    echo -e "      ${COLOR_CYAN}    --enhour${COLOR_END}       开启小时"
    echo -e "      ${COLOR_CYAN}    --dbhost${COLOR_END}       mysql服务器host，如89、14，可选。不填启用env中的值"
    echo -e "      ${COLOR_CYAN}    --dbnmae${COLOR_END}       mysql的库，如yc_bit，可选。不填启用env中的值"
    echo -e "      ${COLOR_CYAN}    --table${COLOR_END}        表名，可选"
    echo -e "      ${COLOR_CYAN}-h, --help${COLOR_END}         帮助"
    echo -e ""
    exit
}

function getIfValid() {
    local value=$1
    local default=$2
    if [ "${value}" = "" ];then
        echo $default
    else
        echo $value
    fi
}

# 接受用户传递的参数
OPTS=`getopt -o hts --long help,test,silent,all,enhour,dev,dt:,hour:,start:,end:,dbhost:,dbname:,table: -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

TODAY=`date +%Y%m%d`
YESTERDAY=`date +%Y%m%d -d '-1day'`

START=
END=
DEBUG=false
SILENT=false
DB_HOST=${TARGET_MYSQL_HOST}
DB_NAME=${TARGET_MYSQL_DB}
DT=
HOUR=
ENABLE_HOUR=false
IS_ALL=false
DEV=false
TABLE=

while true; do
  case "$1" in
    -t | --test ) DEBUG=true; shift ;;
    -s | --silent ) SILENT=true; shift ;;
    --dev ) DEV=true; shift ;;
    --enhour ) ENABLE_HOUR=true; shift ;;
    --all ) IS_ALL=true; shift ;;
    -h | --help ) usage; shift ;;
    --start ) START="$2"; shift; shift ;;
    --end ) END="$2"; shift; shift ;;
    --dt ) DT="$2"; shift; shift ;;
    --hour ) HOUR="$2"; shift; shift ;;
    --dbhost ) DB_HOST="$2"; shift; shift ;;
    --dbname ) DB_NAME="$2"; shift; shift ;;
    --table ) TABLE="$2"; shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

START=$(strToTime "${START}")
END=$(strToTime "${END}")
DT=$(strToTime "${DT}")

if [ "${HOUR}" != "" ] && [ $HOUR -lt 10 ];then
    HOUR="0${HOUR}"
fi

# 开始时间和结束时间默认是昨天和今天（Ymd格式）
START_DT=$YESTERDAY
END_DT=$TODAY

# 处理用户自定义时间
if [ "$DT" != "" ];then
    START_DT=$DT
    END_DT=$(getDate "${DT}" "yes")
else
    if [ "${START}" != "" ]; then
        START_DT=$(getDate "${START}" "no")
        if [ "${END}" != "" ];then
            if [ ${#END} -lt 8 ];then
                 END_DT=$(getDate "${END}" "yes")
            else
                 END_DT=$(getDate "${END}" "no")
            fi
        else
            END_DT=$(getDate "${START}" "yes")
        fi
    fi
fi

#if [ $START_DT -gt $TODAY ];then
#    START_DT=$YESTERDAY
#fi
#
#if [ $END_DT -gt $TODAY ] || [ $END_DT -lt $START_DT ];then
#    END_DT=$TODAY
#fi

START_TS=`date -d $START_DT +%s`
END_TS=`date -d $END_DT +%s`

START_DATE=`date -d ${START_DT} +"%F"`
END_DATE=`date -d ${END_DT} +"%F"`
START_DATETIME="${START_DATE} 00:00:00"
END_DATETIME="${END_DATE} 00:00:00"

NOW_HOUR=`date +%H`
USE_HOUR=$NOW_HOUR

START_HOUR_DATETIME=$START_DATETIME
END_HOUR_DATETIME=$END_DATETIME
START_HOUR_TS=`date -d "${START_HOUR_DATETIME}" +%s`
END_HOUR_TS=`date -d "${END_HOUR_DATETIME}" +%s`
if [ "${ENABLE_HOUR}" = "true" ];then
    if [ "${HOUR}" != "" ];then
        USE_HOUR=$HOUR
    fi
    START_HOUR_DATETIME="${START_DATE} ${USE_HOUR}:00:00"
    START_HOUR_TS=`date -d "${START_HOUR_DATETIME}" +%s`
    END_HOUR_TS=$(( ${START_HOUR_TS} + 3600 ))
    END_HOUR_DATETIME=`date -d @${END_HOUR_TS} +"%F %T"`
fi

TODAY_DT=$TODAY
YESTERDAY_DT=$YESTERDAY
TODAY_TS=`date -d $TODAY +%s`
YESTERDAY_TS=`date -d $YESTERDAY +%s`

NOW_DATETIME=`date +"%F %T"`
NOW_TS=`date +%s -d "${NOW_DATETIME}"`

# 主要针对单天时间
THIS_YEAR_START_DT=$(getFirstDayOfYear ${START_DT})
THIS_YEAR_END_DT=$(getLastDayOfYear ${START_DT} y)
THIS_MONTH_START_DT=$(getFirstDayOfMonth ${START_DT})
THIS_MONTH_END_DT=$(getLastDayOfMonth ${START_DT} y)
THIS_WEEK_START_DT=$(getFirstDayOfWeek ${START_DT})
THIS_WEEK_END_DT=$(getLastDayOfWeek ${START_DT} y)

LAST_7DAYS_START_DT=$(getDiffDay ${START_DT} -5)
LAST_30DAYS_START_DT=$(getDiffDay ${START_DT} -28)


if [ "${DEBUG}" = "true" ];then
    echo
    echo -e "   ${COLOR_UL_CYAN}  ${START_HOUR_DATETIME} (${START_HOUR_TS}) - ${END_HOUR_DATETIME} (${END_HOUR_TS})  ${COLOR_END}"
    echo

    echo -e "     available variables: "
    echo

    echo -e "       ${COLOR_CYAN}DB_HOST${COLOR_END}                        ${DB_HOST}"
    echo -e "       ${COLOR_CYAN}DB_NAME${COLOR_END}                        ${DB_NAME}"
    echo -e "       ${COLOR_CYAN}TABLE${COLOR_END}                          ${TABLE}"
    echo

    echo -e "       ${COLOR_CYAN}NOW_DATETIME${COLOR_END}                   ${NOW_DATETIME}"
    echo -e "       ${COLOR_CYAN}NOW_TS${COLOR_END}                         ${NOW_TS}"
    echo -e "       ${COLOR_CYAN}NOW_HOUR${COLOR_END}                       ${NOW_HOUR}"
    echo -e "       ${COLOR_CYAN}TODAY_DT${COLOR_END}                       ${TODAY_DT}"
    echo -e "       ${COLOR_CYAN}TODAY_TS${COLOR_END}                       ${TODAY_TS}"
    echo -e "       ${COLOR_CYAN}YESTERDAY_DT${COLOR_END}                   ${YESTERDAY_DT}"
    echo -e "       ${COLOR_CYAN}YESTERDAY_TS${COLOR_END}                   ${YESTERDAY_TS}"
    echo

    echo -e "       ${COLOR_CYAN}USE_HOUR${COLOR_END}                       ${USE_HOUR}"
    echo

    echo -e "       ${COLOR_CYAN}START_DT${COLOR_END}                       ${START_DT}"
    echo -e "       ${COLOR_CYAN}START_TS${COLOR_END}                       ${START_TS}"
    echo -e "       ${COLOR_CYAN}START_DATE${COLOR_END}                     ${START_DATE}"
    echo -e "       ${COLOR_CYAN}START_DATETIME${COLOR_END}                 ${START_DATETIME}"
    echo -e "       ${COLOR_CYAN}START_HOUR_DATETIME${COLOR_END}            ${START_HOUR_DATETIME}"
    echo -e "       ${COLOR_CYAN}START_HOUR_TS${COLOR_END}                  ${START_HOUR_TS}"
    echo

    echo -e "       ${COLOR_CYAN}END_DT${COLOR_END}                         ${END_DT}"
    echo -e "       ${COLOR_CYAN}END_TS${COLOR_END}                         ${END_TS}"
    echo -e "       ${COLOR_CYAN}END_DATE${COLOR_END}                       ${END_DATE}"
    echo -e "       ${COLOR_CYAN}END_DATETIME${COLOR_END}                   ${END_DATETIME}"
    echo -e "       ${COLOR_CYAN}END_HOUR_DATETIME${COLOR_END}              ${END_HOUR_DATETIME}"
    echo -e "       ${COLOR_CYAN}END_HOUR_TS${COLOR_END}                    ${END_HOUR_TS}"
    echo

    echo -e "       ${COLOR_CYAN}THIS_YEAR_START_DT${COLOR_END}             ${THIS_YEAR_START_DT}"
    echo -e "       ${COLOR_CYAN}THIS_YEAR_END_DT${COLOR_END}               ${THIS_YEAR_END_DT}"
    echo -e "       ${COLOR_CYAN}THIS_MONTH_START_DT${COLOR_END}            ${THIS_MONTH_START_DT}"
    echo -e "       ${COLOR_CYAN}THIS_MONTH_END_DT${COLOR_END}              ${THIS_MONTH_END_DT}"
    echo -e "       ${COLOR_CYAN}THIS_WEEK_START_DT${COLOR_END}             ${THIS_WEEK_START_DT}"
    echo -e "       ${COLOR_CYAN}THIS_WEEK_END_DT${COLOR_END}               ${THIS_WEEK_END_DT}"
    echo

    echo -e "       ${COLOR_CYAN}LAST_7DAYS_START_DT${COLOR_END}            ${LAST_7DAYS_START_DT}"
    echo -e "       ${COLOR_CYAN}LAST_30DAYS_START_DT${COLOR_END}           ${LAST_30DAYS_START_DT}"
    echo

    exit
fi