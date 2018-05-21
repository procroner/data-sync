<?php

require_once __DIR__ . '/../tables/_REQUIRE_FILE.php';

DoRun(function () use ($TABLE, $DB_HOST, $DB_NAME, $START_TS, $END_TS) {
    $TABLE = Util::getIfValid($TABLE, 'bi_account_finance');
    $conn = DB::conn($DB_HOST, $DB_NAME);
    $count1 = getCount($conn, $TABLE, $START_TS, $END_TS);
    $lastStart = $START_TS - 86400;
    $count2 = getOldCount($conn, $TABLE, $lastStart, $START_TS);
    $diff = abs($count1 - $count2);
    if($diff > 0) {
        $message = date('Y-m-d', $START_TS) . "用户余额异常：" . $diff;
        Notify::sendDingText($message, true);
    }
});

function getCount($conn, $table, $startTs, $endTs) {
    $sql = "
    SELECT ROUND(SUM(IF(reason = 128,amount,0))/100)-ROUND(SUM(IF(reason != 128,amount,0))/100) AS amount 
    FROM $table 
    WHERE create_time >= $startTs AND create_time < $endTs AND class = 'person' AND type = 2";
    return $conn->query($sql)->fetchAll()[0]['amount'];
}

function getOldCount($conn, $table, $startTs, $endTs) {
    $sql = "
    SELECT ROUND(SUM(IF(reason = 128,amount,0))/100) AS amount 
    FROM $table 
    WHERE create_time >= $startTs AND create_time < $endTs AND class = 'person' AND type = 2";
    return $conn->query($sql)->fetchAll()[0]['amount'];
}