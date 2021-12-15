<?php
 
require_once '../../CV2/lib/db.php';

OpenMyDBWithoutSession();

global $argc, $argv;

if($argc < 4){
	echo "Usage:\n";
	echo "php5 import_update_apk_from_list.php  list_file  apk_pool_dir \n";
	exit;
}

$file_list_name=$argv[1];
$folder=$argv[2];

/* Add app platform info, upload into db when scan apps.
 * jlin10x, 9/oct/2014
 */
$platform=$argv[3];

$first_time = false;
function update_non_ndk_info($apk_id,$apk_folder){
	$cur_dir = dirname(__FILE__);
	//echo "current dir is " . $cur_dir . "\n";
	//echo "Processing apk {"  . $apk_id . "} ......\n";
	//$query_sql = "select t1.pkg_name, t2.apk_file from apk t1, apk_file t2 where t2.apk_id=" . $apk_id . " and t1.apk_id=t2.apk_id";
	$query_sql = "select pkg_name from apk where apk_id=$apk_id";
	//echo "Commnd is " . $query_sql . "\n";

	$result_2 = mysql_query($query_sql);

	$num = mysql_num_rows($result_2);
	if($num <= 0){
		echo "	Error: Can NOT find apk " . $apk_id .  "in apk table !!!\n";
		return;
		//die("        Error: Can NOT find apk " . $apk_id .  " in apk table !!!\n");;
	}


	$row_2 =  mysql_fetch_array($result_2);
	$apk_pkg_name =  trim( $row_2['pkg_name']);

	if(!preg_match('/\.apk$/', $apk_pkg_name)){
		echo "	apk { " . $apk_id . " =>" . $apk_pkg_name . "} is NOT end with .apk!!!\n";
		return;
		//die("  apk { " . $apk_id . " =>" . $apk_pkg_name . "} is NOT end with .apk!!!\n");
	}

	$apk_file_name = $cur_dir . "/apk_non_NDK_pro/apk_file/" . $apk_pkg_name;

	//echo "File name is : $apk_file_name \n";
	$apk_file = fopen($apk_file_name, "w+");
	
	if(!$apk_file){
		echo "Unable to open file" . $apk_file_name . "\n";
		return;
	}

	//fwrite($apk_file, $row_2['apk_file']);

	fclose($apk_file);


	//echo "	apk name is {"  . $apk_pkg_name . "}\n";
    //process the apk file 
   // echo "echo begin to ls";
    //exec("ls ./apk_non_NDK_pro/apk_file");
	$my_cmd = "./apk_non_NDK_pro/process_depend_info.sh $apk_folder $apk_pkg_name";
	//echo "The cmd is " . $my_cmd . "\n";

	/*
	exec($my_cmd,$output, $ret);

	print_r($output);
	unset($output);

	if($ret != 0){
		echo "	Error : Processing terminated!!!\n";
		continue;
	}
	*/

	exec($my_cmd);
	
	$result_file_name = $cur_dir . "/apk_non_NDK_pro/result/" . $apk_pkg_name;
	//echo "Result file is " . $result_file_name . "\n";

	if(file_exists($result_file_name)){

		echo "	CONTAIN non-NKD-lib!!!\n";

		ReOpenMyDBWithoutSession();
        $mysql = "delete from apk_with_non_NDK where apk_id=$apk_id;";


		mysql_query($mysql);

		$i = 0;
		$result_file = fopen($result_file_name, "r");
		while(!feof($result_file)){
			$i++;
			$non_ndk_lib_name = trim(fgets($result_file));
			if($non_ndk_lib_name != ""){
				echo "	[" . $i . "] " . $non_ndk_lib_name . "\n";

				ReOpenMyDBWithoutSession();
				$insert_sql = sprintf('call sp_add_apk_non_ndk_relation(%d,"%s");', 
							$apk_id, mysql_real_escape_string($non_ndk_lib_name));
				//echo "cmd is " . $insert_sql . "\n";
				mysql_query($insert_sql);

			}
		}
		
		fclose($result_file);
		unlink($result_file_name);
	}
	else{
		echo "	NO non-NDK-lib exists!!!\n";
	}
	

	echo "\n";

	unlink($apk_file_name);

	mysql_free_result($result_2);
}


function add_tester_notes($apk_id, $message)
{
	$message = mysql_real_escape_string($message);
	$my_sql="insert into tester_notes (apk_id, note, submitter) value ('$apk_id','$message', '62')";
        $result = mysql_query($my_sql);
	
	
	if (!$result) {
		echo "insert tester notes error " . mysql_error();
	}

}



function add_or_update_apk_file($apk_id, $apk_file_name, $new_version, $old_version, $equals, $first_time,$apk_folder)
{
	$fp=fopen($apk_file_name, "r");
	if ( !$fp ) {
		//die("file open error");
    }
	//$file_data=addslashes(fread($fp, filesize($apk_file_name)));
	
	$my_sql="select apk_id from apk where apk_id='$apk_id'";

	$result=mysql_query($my_sql); // check whether the corrsponding record exist in DB 
	if( $result ){
		$num = mysql_num_rows($result);
		if($num > 0){
			//update_apk_file($apk_id, $apk_file_name);
			//$my_sql="update apk_file set apk_file='$file_data' where apk_id='$apk_id'";
			//mysql_query($my_sql);

			update_non_ndk_info($apk_id,$apk_folder);

			if($equals){
				if($first_time){
					$message = "[Git Update] : Update the apk file even version not change in case the version  is NOT right!!!\n";
					add_tester_notes($apk_id, $message);
					echo $message;
				}
				else{
					$message = "[Git Update] : The apk file is updated but the version is not changed (Version still $new_version)!!!\n";
                                        add_tester_notes($apk_id, $message);
                                        echo $message;
				}
			}
			else{
				$message = "[Git Update] : Update the apk file from version " . $old_version . " to version " . $new_version . "\n";
				add_tester_notes($apk_id, $message);
				echo $message;
			}
		}else{
			$my_sql="insert into apk_file (apk_id, apk_file) value ('$apk_id','$file_data')"; 
			mysql_query($my_sql);
			update_non_ndk_info($apk_id,$apk_folder);

			$message = "[Git Update] : Upload the apk file -- Version : " . $new_version . "\n";
			add_tester_notes($apk_id, $message);	
			echo $message;
		}

	}

	fclose($fp);
}



function import_update_apk_info($folder, $file_name, $first_time,$pl)
{
	//echo "File name is " . $file_name . "\n";

	$apk_file_name = $folder . "/" . $file_name;

	if(!file_exists($apk_file_name)){
		echo "The APK file does NOT exist : " . $apk_file_name . "\n";
		return;
	}
	
	echo "Processing APK : " . $apk_file_name . " ......\n";

	$my_cmd = "./generate_apk_info.sh  \"" . $apk_file_name  . "\"    \"" . $file_name . "\"";

	//echo "command is " . $my_cmd . "\n";
	exec($my_cmd);

	$result_file_name = "./" . $file_name . ".dump";

	if(file_exists($result_file_name)){
		$result_file = fopen($result_file_name, "r");
		$i = 0;
		/*
		result_array[0] : apk_name
		result_array[1] : pkg_name
		result_array[2] : cv_name
		result_array[3] : apk_version
		result_array[4] : test_category_id
		result_array[5] : versionCode
		result_array[6] : Publish date
		*/
                while(!feof($result_file)){
                        $result = trim(fgets($result_file));
                        if($result != ""){
				$result_array[$i] = $result;
				echo " " . $result_array[$i] . "\n";
				$i++;
                        }
			
                }

                fclose($result_file);

		//echo "cv_name = $result_array[2]\n";
		$my_sql = "select apk_id, apk_version from apk where cv_name='$result_array[2]' and app_platform='$pl';";
		$result=mysql_query($my_sql);

		if( $result ){
                        $num = mysql_num_rows($result);

                        if($num > 0){
				echo "APK exist!!!\n";
				$row = mysql_fetch_array($result);
				$apk_id = $row['apk_id'];
				$apk_version = $row['apk_version'];

				if($first_time){
					#echo "first_time: result_array[0]= $result_array[0]\n";
                                        $my_sql="update apk set apk_name='$result_array[0]', pkg_name='$result_array[1]', apk_version='$result_array[3]', test_category_id='$result_array[4]', app_platform='$pl', versioncode='$result_array[5]', pub_date='$result_array[6]'  where apk_id='$apk_id'";
                                        mysql_query($my_sql);
					
					$message = "[Git Update] : Update the apk info based on the apk in Git Repository!!!\n";
                                        add_tester_notes($apk_id, $message);
                                        echo $message;
			
					$equals = true;
                                        add_or_update_apk_file($apk_id, $apk_file_name, $result_array[3], $apk_version, $equals, $first_time,$folder);	
					
				}
				else if($apk_version != $result_array[3]){
					#echo "elseif: result_array[0]= $result_array[0]\n";
					$my_sql="update apk set apk_name='$result_array[0]', pkg_name='$result_array[1]', apk_version='$result_array[3]', test_category_id='$result_array[4]', app_platform='$pl', versioncode='$result_array[5]', pub_date='$result_array[6]' where apk_id='$apk_id'";
					//$my_sql="update apk set apk_version='$result_array[3]' where apk_id='$apk_id'";
					mysql_query($my_sql);

					$equals = false;
					add_or_update_apk_file($apk_id, $apk_file_name, $result_array[3], $apk_version, $equals, $first_time,$folder);

				}
				else{
					#echo "else: result_array[0]= $result_array[0]\n";
					$equals = true;
					$my_sql="update apk set apk_name='$result_array[0]', pkg_name='$result_array[1]', apk_version='$result_array[3]', test_category_id='$result_array[4]', app_platform='$pl', versioncode='$result_array[5]', pub_date='$result_array[6]' where apk_id='$apk_id'";
					mysql_query($my_sql);
					add_or_update_apk_file($apk_id, $apk_file_name, $result_array[3], $apk_version, $equals, $first_time,$folder);
					
				}
			}
			else{
				echo "APK does NOT exist!!!\n";
				$p_apk_name = $result_array[0];
				$p_pkg_name = $result_array[1];
				$p_cv_name = $result_array[2];
				$p_apk_version = $result_array[3];
				$p_test_category_id = $result_array[4];
				$p_versioncode = $result_array[5];
				$p_publish_date = $result_array[6];
	
				$my_sql = sprintf('insert into apk (apk_name, pkg_name, apk_version, cv_name, test_category_id, psi_compatible, ppd_compatible, ported, is_active, user_name, app_platform, versioncode, pub_date) values ("%s","%s","%s","%s",%d, "%s", "%s", "%s", %d, "%s", "%s", "%s", "%s");'
					,mysql_real_escape_string($p_apk_name)
                        		,mysql_real_escape_string($p_pkg_name)
                        		,mysql_real_escape_string($p_apk_version)
                        		,mysql_real_escape_string($p_cv_name)
					,$p_test_category_id
					,'N'
					,'N'
					,'N'
					,0
                    ,'lvcai xu'
                    ,$pl
                    ,$p_versioncode
                    ,$p_publish_date
                        	);
				#echo "+++++++not exist, mysql=$my_sql";
				//$my_sql = "insert into apk (apk_name, pkg_name, cv_name, apk_version, test_category_id, psi_compatible, ppd_compatible, ported, is_active, user_name) values ($p_apk_name,$p_pkg_name,$p_cv_name,$p_apk_version, $p_test_category_id);";

				$result = mysql_query($my_sql);

				if ($result) {
					//$num = mysql_num_rows($result);
					//if ($num > 0) {
						$apk_id = mysql_insert_id();

						//update_non_ndk_info($apk_id);

						$message = "[Git Update] : Newly add application, Version : " . $result_array[3]  . "!!\n";
						
						echo "The newly insert id is " . $apk_id . "\n";
						add_tester_notes($apk_id, $message);
						$equals = true;
						add_or_update_apk_file($apk_id, $apk_file_name, $result_array[3], $result_array[3], $equals, $first_time,$folder);
					//}
				}
				else{
					echo "insert error " . mysql_error();
				}
				
			}
		}
		else{
			echo "search error " . mysql_error();
		}
		
	}
	else{
		echo "The result file does NOT exist : " . $result_file_name . "\n";
	}
	

}

function send_import__update_message($subject, $to_list, $from_list, $cc_list, $message)
{

$cc="Cc:" . $cc_list;
$to="To:" . $to_list;
$from="From:" . $from_list;

$tmp_file= './tmp_apk_list.html';

//save the html email
if($handle=fopen($tmp_file,"w"))
{
        fwrite($handle,"$message");
}
else
{
        //die("Cannot create tmp file");
	echo "Cannot create tmp file";
	return;
}
flush();
fclose($handle);

//the send command
$command = "cat $tmp_file | /usr/bin/formail -I '$from' -I '$cc' -I '$to' -I 'MIME-Version:1.0' -I 'Content-type:text/html;charset=utf-8' -I '$subject' | /usr/sbin/sendmail -t";

exec($command);


}

$file_content_head="
<html>
        <head>

                <Title>GIT APP MANAGEMENT SYSTEM - APK Info Update</Title>
                <meta http-equiv='Content-Type' content='text/html;charset='utf-8'/>
                <style type='text/css' media='all'>
TABLE TR.odd TH {BACKGROUND:#E5E5E5}
.odd {BACKGROUND:#FFFFFF}
TABLE TR.even TH {BACKGROUND: #d5d5d5}
.even { BACKGROUND: #F1F7FF}
.title {BACKGROUND: #A9A9F5;font-weight:bold;}
.new_silver_table {
        border: 1px solid #999;
        border-top-width: 1px;
        border-right-width: 1px;
        border-bottom-width: 1px;
        border-left-width: 1px;
        border-top-style: solid;
        border-right-style: solid;
        border-bottom-style: solid;
        border-left-style: solid;
        border-top-color: #999;
        border-right-color: #999;
        border-bottom-color: #999;
        border-left-color: #999;
        border-image: initial;
}
                </style>
        </head>
        <body style='font-family:Times New Roman'>
                <table bordercolor='#c0c0c0' width='100%' cellpadding='4' cellspacing='0' border='0'><tbody>
                <tr align='center'><td style='font-weight:bold;'><font size='4'>GIT APP MANAGEMENT SYSTEM - APK Info Update Message </font><br></td></tr>
                <tr><td><hr></td></tr>
                <tr align='left'><td>This message is auto-generated by GIT UPDATE System!</td></tr>
                </tbody></table>
                <hr>
                <table align='center' bordercolor='#000000' width='100%' cellpadding='0' cellspacing='0' border='2'><tbody>
                        <thead>
                                <tr><td style='text-align:center;font-weight:bold;background:#6495ED;' colspan='2' >The Newly Updated APK Summary</td></tr>
";

$file_content_foot="
                        </thead>
                        <tbody>
                        
                </tbody>
        </table>
        </body>
</html>
";

$file_content_apk_name="";



$dir = opendir($folder);

if($dir){
	$count=0;
	//while(($file_name = readdir($dir)) != false)
	if(file_exists($file_list_name)){
		$list_file = fopen($file_list_name, "r");
		while(!feof($list_file))
		{
			$apk_name = trim(fgets($list_file));
			if(preg_match('/\.apk$/', $apk_name)){
				echo "File is : " . $apk_name . "\n";
				$count++;
				echo "\n------------  Processing the " . $count ." App ----------\n";
                import_update_apk_info($folder, $apk_name, $first_time, $platform);
				echo "------------------------------------------------------------\n";
				
				$file_content_apk_name .= "
                                <tr>
                                        <th class='title'>APK Name</th>
                                        <th align='left'>$apk_name</th>
                                </tr>";			
			}
		}

		echo "Totally Process " . $count . " Application !!!!\n";

		$file_content_apk_name .="
                                <tr><td style='text-align:left;font-weight:bold;background:#6495ED;' colspan='2' >Totally Process $count Application!!</td></tr>";


                $file_content="" . $file_content_head . $file_content_apk_name . $file_content_foot;

                $subject = "Subject:[Update][GIT_UPDATE_APK] GIT APK Pool Update!";
                $from_list = "Git_Update_auto-no-replay@intel.com";

                $cc_list = "lvcai.xu@intel.com";
                $to_list = "jianx.lin@intel.com";
                //send_import__update_message($subject, $to_list, $from_list, $cc_list, $file_content);


	}
	else{
		echo "[Error] Cannot find the list file : " . $file_list_name . "\n";
	}
}

CloseMyDB();
?>

