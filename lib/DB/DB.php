<?php
/**
 * User: chenbing
 * Date: 2018/1/23
 * Time: 17:47
 */

include_once __DIR__ . '/Medoo.php';

class DB
{
    public static $dbs = [
        89  => [
            'server'   => '',
            'username' => '',
            'password' => '',
        ],
        53  => [
            'server'   => '',
            'username' => '',
            'password' => '',
        ],
        14  => [
            'server'   => '',
            'username' => '',
            'password' => '',
        ],
        143 => [
            'server'   => '',
            'username' => '',
            'password' => '',
        ],
    ];

    public static function getDB($dbHost, $dbName = null)
    {
        $db = self::$dbs[$dbHost];
        $base = [
            'charset'       => 'utf8',
            'database_type' => 'mysql',
        ];
        if ($dbName) {
            $base['database_name'] = $dbName;
        }
        return new Medoo(array_merge($base, $db));
    }

    public static function db89($dbName = null)
    {
        return self::getDB(89, $dbName);
    }

    public static function db89YcBit()
    {
        return self::db89('yc_bit');
    }

    public static function db143($dbName = null)
    {
        return self::getDB(143, $dbName);
    }

    public static function dbOnlineOrder()
    {
        return self::db143('yc_order');
    }

    public static function conn($dbHost = null, $dbName = null)
    {
        return self::getDB(Env::get('DB_HOST', $dbHost), Env::get('DB_NAME', $dbName));
    }
}