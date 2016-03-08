<?php

require_once '../../../CV2/lib/db.php';
require_once '../../../Classes/PHPExcel.php';
require_once '../../../Classes/PHPExcel/Writer/Excel2007.php';
require_once '../../../Classes/PHPExcel/Reader/Excel2007.php';
require_once '../../../Classes/PHPExcel/Reader/Excel5.php';
require_once '../../../Classes/PHPExcel/Reader/CSV.php';
require_once '../../../Classes/PHPExcel/IOFactory.php';


OpenMyDBWithoutSession();


$result_csv_file_name="AppInfo.csv";
$cur_dir = dirname(__FILE__);

$result_file_name = $cur_dir . "/" . $result_csv_file_name;

if(file_exists($result_file_name)){
    $PHPReader=new PHPExcel_Reader_CSV();
    if(!($PHPReader->canRead($result_file_name))){
        die("Unable to read file contents");
    }

    $PHPExcel = $PHPReader->load($result_file_name);

    $PHPExcel->setActiveSheetIndex(0);

    $objWorksheet = $PHPExcel->getActiveSheet();

    $highestRow = $objWorksheet->getHighestRow(); // e.g. 10
    $highestColumn = $objWorksheet->getHighestColumn(); // e.g 'F'

    $highestColumnIndex = PHPExcel_Cell::columnIndexFromString($highestColumn);

    $count_total = 0;
    $count_process = 0;
    for ($row = 2; $row <= $highestRow; ++$row) {
        $count_total++;
        $package_name = $objWorksheet->getCellByColumnAndRow(0, $row)->getCalculatedValue();
        $lastest_version = trim($objWorksheet->getCellByColumnAndRow(1, $row)->getCalculatedValue());
        echo "$package_name : $lastest_version \n";
        if($lastest_version != "N/A"){
            $sql = sprintf('call sp_update_apk_lastest_version_by_pkg_name("%s","%s");'
                                                ,mysql_real_escape_string($package_name)
                                                ,mysql_real_escape_string($lastest_version)
                                                );
            
            ReOpenMyDBWithoutSession();
            mysql_query($sql); 
            $count_process++;
        }

       
    }

    echo "Process  $count_process / $count_total  apk!!!!\n";


}


