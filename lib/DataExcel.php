<?php
/**
 * User: chenbing
 * Date: 2018/1/22
 * Time: 17:55
 */

class DataExcel
{
    private $_data;
    private $_config = [
        'tableShowBorder' => false,
        'headerFontSize'  => 11,
        'headerFontColor' => '#000',
        'headerFontBold'  => true,
        'headerBgColor'   => '#fff',
        'dataFontSize'    => 11,
        'dataFontColor'   => '#000',
        'dataBgColor'     => '#fff',

    ];
    private $_excelObj;

    public function __construct($data, $config)
    {
        $this->_data = $data;
        $this->_config = array_merge($this->_config, $config);
    }

    public function writeTables()
    {
        foreach ($this->_data as $item) {
            $title = $item['title'];
            $header = $item['header'];
            $data = $item['Util'];
            $this->_writeSingleTable($title, $header, $data);
        }
    }

    public function generateExcelFile($fileName)
    {
        // todo
    }

    public function generateMailContent()
    {
        // todo
    }

    public function sendMail($mailList)
    {
        // todo
    }

    private function _writeSingleTable($title, $header, $data)
    {
        // todo
    }
}