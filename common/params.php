<?php
/**
 * User: chenbing
 * Date: 2018/1/23
 * Time: 09:34
 */

date_default_timezone_set("Asia/Shanghai");

$shortOpts = "h";
$longOpts = array(
    "test",
    "silent",
    "dev",
    "dt::",
    "start::",
    "end::",
    "hour::",
    "all",
    "enhour",
    "dbhost::",
    "dbname::",
    "table::",
    "help",
    "truncate",

);
$options = getopt($shortOpts, $longOpts);


if (paramHas('help') || paramHas('h')) {
    usage();
    die;
}

$TODAY = date('Ymd');
$YESTERDAY = date('Ymd', strtotime('yesterday'));
$TODAY_DT = $TODAY;
$YESTERDAY_DT = $YESTERDAY;
$TODAY_TS = strtotime($TODAY_DT);
$YESTERDAY_TS = strtotime($YESTERDAY_DT);

$START = paramGet('start');
$END = paramGet('end');
$TEST = paramHas('test');
$SILENT = paramHas('silent');
$DB_HOST = paramGet('dbhost', Env::get('TARGET_MYSQL_HOST'));
$DB_NAME = paramGet('dbname', Env::get('TARGET_MYSQL_DB'));
$TABLE = paramGet('table');
$DT = paramGet('dt');
$HOUR = paramGet('hour');
$ENABLE_HOUR = paramHas('enhour');
$IS_ALL = paramHas('all');
$DEV = paramHas('dev');
$TRUNCATE = paramHas('truncate');

if ($HOUR && (int)$HOUR < 10) {
    $HOUR = "0${HOUR}";
}

$START_DT = $YESTERDAY;
$END_DT = $TODAY;

if($DT) {
    $START_DT = $DT;
    $END_DT = formatDate($DT, true);
} else {
    if($START) {
        $START_DT = formatDate($START);
        if($END) {
            $addNext = strlen(strval($END)) < 8;
            $END_DT = formatDate($END, $addNext);
        } else {
            $END_DT = formatDate($START, true);
        }
    }
}

//if(intval($START_DT) >= intval($TODAY_DT)) {
//    $START_DT = $YESTERDAY_DT;
//}
//
//if(intval($END_DT) > intval($TODAY_DT) || intval($END_DT) < intval($START_DT)) {
//    $END_DT = $TODAY_DT;
//}

$START_TS = strtotime($START_DT);
$END_TS = strtotime($END_DT);
$START_DATE = date('Y-m-d', $START_TS);
$END_DATE = date('Y-m-d', $END_TS);
$START_DATETIME = "${START_DATE} 00:00:00";
$END_DATETIME = "${END_DATE} 00:00:00";
$START_HOUR_DATETIME = $START_DATETIME;
$END_HOUR_DATETIME = $END_DATETIME;
$START_HOUR_TS = strtotime($START_HOUR_DATETIME);
$END_HOUR_TS = strtotime($END_HOUR_DATETIME);

if($ENABLE_HOUR) {
    $NOW_HOUR = date('H');
    if($HOUR) {
        $NOW_HOUR = $HOUR;
    }
    $END_HOUR_DATETIME = "${START_DATE} ${NOW_HOUR}:00:00";
    $END_HOUR_TS = strtotime($END_HOUR_DATETIME);
    $START_HOUR_TS = $END_HOUR_TS - 3600;
    $START_HOUR_DATETIME = date('Y-m-d H:i:s', $START_HOUR_TS);
}

if ($TEST) {
    echo "\033[4;36m  ${START_HOUR_DATETIME} (${START_HOUR_TS}) - ${END_HOUR_DATETIME} (${END_HOUR_TS})  \033[0m" . PHP_EOL;
    exit;
}

function usage()
{
    $help = <<<MSG
    
        \033[1;36m--test\033[0m              开启测试，启用该选项后打印开始时间和结束时间，不执行脚本
        \033[1;36m--silent\033[0m            关闭钉钉失败通知
        \033[1;36m--dev\033[0m               钉钉通知启用测试token
        \033[1;36m--dt\033[0m                运行某天的数据，默认今天，比--start和--end优先
        \033[1;36m--start\033[0m             开始时间，可选，默认昨天
        \033[1;36m--end\033[0m               结束时间，可选，默认今天
        \033[1;36m--hour\033[0m              小时
        \033[1;36m--all\033[0m               所有数据
        \033[1;36m--enhour\033[0m            开启小时
        \033[1;36m--dbhost\033[0m            mysql服务器host，如89、14，可选。不填启用env中的值
        \033[1;36m--dbname\033[0m            mysql的库，如yc_bit，可选。不填启用env中的值
        \033[1;36m--table\033[0m             mysql的表
        \033[1;36m--truncate\033[0m          truncate表
    \033[1;36m-h, --help\033[0m              帮助

MSG;
    echo $help . PHP_EOL;
}

function paramHas($key)
{
    global $options;
    return array_key_exists($key, $options);
}

function paramGet($key, $default = false)
{
    global $options;
    if (paramHas($key)) {
        return $options[$key];
    }
    return $default;
}

function formatDate($someDate, $addNext = false)
{
    $someDate = date('Ymd', strtotime($someDate));
    $dateLen = strlen(strval($someDate));
    switch ($dateLen) {
        case 8:
            $result = $someDate;
            if ($addNext) {
                $result = dayDiff($someDate);
            }
            break;
        case 6:
            $result = "${someDate}01";
            if ($addNext) {
                $result = date('Ymd', strtotime("first day of next month ${result}"));
            }
            break;
        case 4:
            $result = "${someDate}0101";
            if ($addNext) {
                $nextYear = (int)$someDate + 1;
                $result = "${nextYear}0101";
            }
            break;
        default:
            $result = date('Ymd', strtotime('yesterday'));
            if ($addNext) {
                $result = date('Ymd');
            }
    }
    return $result;
}

function dayDiff($dateString, $diffDay = 1)
{
    $diffString = $diffDay > 0 ? '+' . $diffDay : $diffDay;
    $timeString = $dateString . ' ' . $diffString . ' day';
    return date('Ymd', strtotime($timeString));
}