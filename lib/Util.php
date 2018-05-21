<?php
/**
 * User: chenbing
 * Date: 2018/1/25
 * Time: 17:30
 */

class Util
{
    public static function getArrVal($array, $key, $default = 0)
    {
        if (array_key_exists($key, $array)) {
            return $array[$key];
        }
        return $default;
    }

    public static function getIfValid($value, $default = false)
    {
        return $value ?: $default;
    }
}