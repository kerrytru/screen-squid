<?php
#build 20170501

if(isset($_GET['srv']))
  $srv=$_GET['srv'];
else
  $srv=0;
?>

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
* {padding:0;margin:0;}
ul {list-style-type:none;padding-left:1em}
body {margin:0.5em;padding:0.5em}

</style>
<link rel="stylesheet" type="text/css" href="../javascript/example.css"/>
</head>
<body>
<br />


<br />
<script type="text/javascript" src="../javascript/sortable.js"></script>
<script language=javascript>






function switchTables()
{
   if (document.getElementById("loginsTable").style.display == "table" ) {
          document.getElementById("loginsTable").style.display="none";

} else {
document.getElementById("loginsTable").style.display="table";
}
   if (document.getElementById("ipaddressTable").style.display == "table" ) {
          document.getElementById("ipaddressTable").style.display="none";

} else {
document.getElementById("ipaddressTable").style.display="table";
}

}

function PartlyReportsLogin(idReport, dom, login,loginname,site)
{
parent.right.location.href='reports/reports.php?srv=<?php echo $srv ?>&id='+idReport+'&date='+window.document.fastdateswitch_form.date_field_hidden.value+'&dom='+dom+'&login='+login+'&loginname='+loginname+'&site='+site;
}

function PartlyReportsIpaddress(idReport, dom, ip,ipname,site)
{
parent.right.location.href='reports/reports.php?srv=<?php echo $srv ?>&id='+idReport+'&date='+window.document.fastdateswitch_form.date_field_hidden.value+'&dom='+dom+'&ip='+ip+'&ipname='+ipname+'&site='+site;
}


</script>


<?php

include("../config.php");


   
$end=microtime(true);

$runtime=$end - $start;

echo "<br /><br /><font size=2>".$_lang['stEXECUTIONTIME']." ".round($runtime,3)." ".$_lang['stSECONDS']."</font><br />";

echo $_lang['stCREATORS'];

$newdate=strtotime(date("d-m-Y"))-86400;
$newdate=date("d-m-Y",$newdate);

  mysqli_free_result($result);
  mysqli_close($link);

?>
<form name=fastdateswitch_form>
    <input type="hidden" name=date_field_hidden value="<?php echo $newdate; ?>">
    <input type="hidden" name=dom_field_hidden value="<?php echo 'day'; ?>">
    <input type="hidden" name=group_field_hidden value="<?php echo $currentgroupid; ?>">
    <input type="hidden" name=groupname_field_hidden value="<?php echo $currentgroup; ?>">
    <input type="hidden" name=typeid_field_hidden value="<?php echo $typeid; ?>">
    </form>
</body>
</html>