<?php
/**
 * User: chenbing
 * Date: 2018/1/23
 * Time: 09:33
 */

date_default_timezone_set("Asia/Shanghai");

function __autoload($class)
{
    $libDir = realpath(__DIR__ . '/../lib');
    $fileName = str_replace('_', '/', $class);
    if (is_file("${libDir}/${fileName}.php")) {
        require_once "${libDir}/${fileName}.php";
    } else if (is_file("${libDir}/DB/${fileName}.php")) {
        require_once "${libDir}/DB/${fileName}.php";
    } else {
        require_once "/usr/share/pear/${fileName}.php";
    }
}

require_once __DIR__ . '/../common/params.php';


function writeLog($message, $showDate = true)
{
    $now = date('Y-m-d H:i:s');
    if ($showDate) {
        echo $now . ' => ' . $message . PHP_EOL;
    } else {
        echo $message . PHP_EOL;
    }
}

function writeDim()
{
    writeLog("========================================================================", false);
}

function DoRun($callback)
{
    $file = debug_backtrace()[0]['file'];
    global $START_HOUR_DATETIME, $END_HOUR_DATETIME;
    writeDim();
    writeLog("${START_HOUR_DATETIME} ~ ${END_HOUR_DATETIME}");
    $runStart = strtotime('now');
    try {
        $callback();
    } catch (Exception $e) {
        Notify::sendDingMarkdown('Error!', $e->getMessage(), $file);
    }
    $runEnd = strtotime('now');
    $runTime = $runEnd - $runStart;
    $min = intval($runTime / 60);
    $sec = $runTime % 60;
    writeLog("${min} min ${sec} sec");
    writeDim();
    echo 'success';
}