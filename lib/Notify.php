<?php
/**
 * User: chenbing
 * Date: 2018/1/22
 * Time: 18:19
 */

class Notify
{
    public static function sendMail()
    {
        //todo
    }

    public static function sendSMS()
    {
        //todo
    }

    public static function sendDingding($title, $body, $file, $isDev = false)
    {
       $content = <<<MSG
#### ${title}
*${file}* 
> ${body[0]}
>
> ===================== 
>
> ${body[1]}
MSG;
        self::sendDingMarkdown($title, $content, $isDev);
    }

    public static function sendDingMarkdown($title, $content, $isDev = false) {
        $data = [
            'msgtype'  => 'markdown',
            'markdown' => [
                'title' => $title,
                'text'  => $content,
            ],
        ];
        self::dingDing($isDev, $data);
    }

    public static function sendDingText($message, $isDev = false)
    {
        $data = [
            'msgtype' => 'text',
            'text'    => [
                'content' => $message,
            ],
        ];
        self::dingDing($isDev, $data);
    }

    public static function dingDing($isDev, $data)
    {
        $token = self::getDingToken($isDev);
        $webhook = "https://oapi.dingtalk.com/robot/send?access_token=${token}";
        $result = CurlRequest::Post($webhook, json_encode($data));
        $result = json_decode($result, JSON_OBJECT_AS_ARRAY);
        return $result;
    }

    public static function getDingToken($isDev = true)
    {
        return $isDev ? Env::get('TEST_DINGDING_TOKEN') : Env::get('DINGDING_TOKEN');
    }
}