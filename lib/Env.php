<?php
/**
 * User: chenbing
 * Date: 2018/1/25
 * Time: 10:52
 */

class Env
{
    public static function parse()
    {
        $envFile = __DIR__ . '/../.env';
        $envArray = [];
        $handle = fopen($envFile, 'r');
        if ($handle) {
            while (($line = fgets($handle, 4096)) !== false) {
                if (strpos($line, '=') !== false) {
                    $param = explode('=', $line);
                    $envArray[trim($param[0])] = trim($param[1]);
                }
            }
            fclose($handle);
        }

        return $envArray;
    }

    public static function has($key)
    {
        return array_key_exists($key, self::parse());
    }

    public static function get($key, $default = false)
    {
        if (self::has($key)) {
            return self::parse()[$key];
        }
        return $default;
    }
}