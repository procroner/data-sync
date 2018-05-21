#!/usr/bin/env bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../env.sh

function dingDing() {
    local msgTitle=$1
    local msgHeader=$2
    local msgBody=$3
    local scriptFile=$4
    local dingToken=${DINGDING_TOKEN}
    if [ "$DEV" = "true" ];then
        dingToken=${TEST_DINGDING_TOKEN}
    fi

    local url="https://oapi.dingtalk.com/robot/send?access_token=${dingToken}"
    local curlParams=$(cat <<EOL
        {
            "msgtype": "markdown",
            "markdown": {
                "title":"${msgTitle}",
                "text": "#### ${msgTitle} \n *${scriptFile}* \n\n > ${msgBody} \n\n  > ===================== \n\n > ${msgHeader}"
            }
        }
EOL
)

    curl "${url}" -H 'Content-Type: application/json' -d "${curlParams}" > /dev/null 2>&1
}

function sendNotify()
{
    local msgTitle=$1
    local msgHeader=$2
    local msgBody=$3
    local scriptFile=$4

    dingDing "${msgTitle}" "${msgHeader}" "${msgBody}" "${scriptFile}"
}