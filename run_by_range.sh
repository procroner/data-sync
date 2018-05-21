#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/common/color.sh
source ${CURRENT_DIR}/common/datetime.sh

function usage() {
    echo -e ""
    echo -e "      ${COLOR_CYAN}    --start${COLOR_END}        开始时间，默认昨天"
    echo -e "      ${COLOR_CYAN}    --end${COLOR_END}          结束时间，默认昨天"
    echo -e "      ${COLOR_CYAN}-r, --reverse${COLOR_END}      是否反序运行，默认正序"
    echo -e "      ${COLOR_CYAN}    --type${COLOR_END}         分割类型，默认day，可选月month，周week，天day，小时hour"
    echo -e "      ${COLOR_CYAN}    --table${COLOR_END}        表脚本"
    echo -e "      ${COLOR_CYAN}    --file${COLOR_END}         自定义脚本"
    echo -e "      ${COLOR_CYAN}-h, --help${COLOR_END}         帮助"
    echo -e "      ${COLOR_CYAN}-t, --test${COLOR_END}         开发测试，不运行，只打印时间参数"
    echo -e "      ${COLOR_CYAN}    --params${COLOR_END}       需要传递给脚本的参数"
    echo -e "      ${COLOR_CYAN}    --sleep${COLOR_END}        跑完一次后的间隔时间"
    echo -e ""
    exit
}

function getEngine() {
    local filePath=$1 #文件全路径
    NAME=$(basename "$filePath")
    EXT="${NAME##*.}"  #文件扩展名
    NAME="${NAME%.*}"  #文件名，不包含扩展名
    echo $EXT
    return 0
}

# 接受用户传递的参数
OPTS=`getopt -o hrt --long start:,end:,type:,table:,file:,params:,sleep:,help,reverse,test -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

TODAY=`date +%Y%m%d`
YESTERDAY=`date +%Y%m%d -d '-1day'`

START=$YESTERDAY
END=$YESTERDAY
REVERSE=false
TYPE=day
TABLE=
FILE=
TEST=false
PARAMS=
SLEEP=0

while true; do
  case "$1" in
    -h | --help ) usage; shift ;;
    --start ) START="$2"; shift; shift ;;
    --end ) END="$2"; shift; shift ;;
    -r | --reverse ) REVERSE="true"; shift; shift ;;
    -t | --test ) TEST="true"; shift; shift ;;
    --type ) TYPE="$2"; shift; shift ;;
    --table ) TABLE="$2"; shift; shift ;;
    --file ) FILE="$2"; shift; shift ;;
    --params ) PARAMS="$2"; shift; shift ;;
    --sleep ) SLEEP="$2"; shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

#tables中的脚本
if [ "${TABLE}" != "" ];then
    SCRIPT="$PWD/tables/${TABLE}"
    FORMAT="--dt="
#自定义脚本
else
    SCRIPT="$FILE"
    FORMAT=""
fi

ENGINE=$(getEngine "${SCRIPT}")
COMMAND="${ENGINE} ${SCRIPT}"
RunCommandByRange "${START}" "${END}" "${COMMAND}" "${FORMAT}" "${PARAMS}" "${TEST}" "${SLEEP}"
echo