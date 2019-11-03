#!/usr/bin/perl

#build 20191023

use DBI; # DBI  Perl!!!

#=======================CONFIGURATION BEGIN============================

my $dbtype = "1"; #type of db - 0 - MySQL, 1 - PostGRESQL

#mysql default config
if($dbtype==0){
my $host = "localhost"; # host s DB
my $port = "3306"; # port DB
my $user = "mysql-user"; # username k DB
my $pass = "pass"; # pasword k DB
my $db = "test4"; # name DB
}
#postgresql default config
if($dbtype==1){
$host = "localhost"; # host s DB
$port = "5432"; # port DB
$user = "postgres"; # username k DB
$pass = "pass"; # pasword k DB
$db = "test4"; # name DB
}

#make conection to DB
if($dbtype==0){ #mysql
$dbh = DBI->connect("DBI:mysql:$db:$host:$port",$user,$pass);
}

if($dbtype==1){ #postgre
$dbh = DBI->connect("dbi:Pg:dbname=$db","$user",$pass,{PrintError => 1});
}

#очистим таблицу квот от алиасов, которые были удалены, а в таблице квот остались
$sql_refreshquota="delete from scsq_mod_quotas where aliasid not in (select id from scsq_alias);";
$sth = $dbh->prepare($sql_refreshquota);
$sth->execute; #



#get aliasid from quotas module
$sql_getquota="select aliasid,active, quota, quotamonth, datemodified, quotaday from scsq_mod_quotas";
$sthr = $dbh->prepare($sql_getquota);
$sthr->execute; #

while (@row = $sthr->fetchrow_array())

    {
$aliasid = $row[0];
$active = $row[1];
$quota = $row[2];
$quotamonth = $row[3];
$datemodified = $row[4];
$quotaday = $row[5];

$sql_queryAlias = "SELECT tableid, typeid FROM scsq_alias WHERE id=".$aliasid.";";
$sth = $dbh->prepare($sql_queryAlias);
$sth->execute; #
@rowAlias=$sth->fetchrow_array;

if($rowAlias[1] eq 0){
$columnname = "login";
}
else
{
$columnname = "ipaddress";
}

#$queryd="'2018-11-26'"; #for debug

if($dbtype==0){
$queryd="date(sysdate())";
$sql_queryDate = "SELECT unix_timestamp($queryd) ;";
}

if($dbtype==1){
	
$queryd="current_date";
#$queryd="to_timestamp('2019-08-07','YYYY-MM-DD')"; #for debug

$sql_queryDate = "SELECT extract(epoch from $queryd) ;";
}


$sth = $dbh->prepare($sql_queryDate);
$sth->execute; #
@datenow=$sth->fetchrow_array;


$querydate=$datenow[0];

$datestart=$querydate;
$dateend=$querydate + 86400;
	
$queryOneAliasTraffic="
 	SELECT 
	   SUM(sizeinbytes) as s
 
		   FROM scsq_quicktraffic 
		   WHERE date>".$datestart." 
		     AND date<".$dateend."
	             AND ".$columnname." = ".$rowAlias[0]." 
		   GROUP BY ".$columnname."
	;";

$sth = $dbh->prepare($queryOneAliasTraffic);
$sth->execute; #

$DaySumSizeTraffic = $sth->fetchrow_array;
$DaySumSizeTraffic = int(($DaySumSizeTraffic + 0)/1024/1024); 
#print int($DaySumSizeTraffic/1000/1000);
#print "\n";


#month quota


#$queryd="'2018-11-26'"; #for debug

if($dbtype==0){
$queryd="sysdate()";
$querydstart="DATE_FORMAT($queryd,\"%Y-%m-1\")";
$querydend="DATE_FORMAT($queryd + INTERVAL 1 MONTH,\"%Y-%m-1\")";

$sql_queryDate = "SELECT unix_timestamp($querydstart),unix_timestamp($querydend) ;";
}

if($dbtype==1){
$queryd="current_date";
#$queryd="to_timestamp('2019-08-07','YYYY-MM-DD')"; #for debug
$querydstart="to_char($queryd,'YYYY-MM-1')";
$querydend="to_char($queryd + INTERVAL '1 MONTH','YYYY-MM-1')";

$sql_queryDate = "SELECT extract(epoch from to_timestamp($querydstart,'YYYY-MM-DD')),extract(epoch from to_timestamp($querydend,'YYYY-MM-DD')) ;";
}

$sth = $dbh->prepare($sql_queryDate);
$sth->execute; #
@datenow=$sth->fetchrow_array;


$datestart=$datenow[0];
$dateend=$datenow[1];
	
$queryOneAliasTraffic="
 	SELECT 
	   SUM(sizeinbytes) as s
 
		   FROM scsq_quicktraffic 
		   WHERE date>".$datestart." 
		     AND date<".$dateend."
	             AND ".$columnname." = ".$rowAlias[0]." 
		   GROUP BY ".$columnname."
	;";

$sth = $dbh->prepare($queryOneAliasTraffic);
$sth->execute; #

$MonthSumSizeTraffic = $sth->fetchrow_array;
$MonthSumSizeTraffic = int(($MonthSumSizeTraffic + 0)/1024/1024);

#print int($MonthSumSizeTraffic);


$status=0;
if($active eq 0){
$status=0;
}
else
{
if(($DaySumSizeTraffic > int($quota)) and int($quota >= 0 )){
$status=1; #текущий траффик вышел за пределы квоты

}

if(($MonthSumSizeTraffic > int($quotamonth))and(int($quotamonth) >=0)){

$status=2; #текущий месячный траффик вышел за пределы месячной квоты
}



if(($DaySumSizeTraffic < int($quota))and($MonthSumSizeTraffic < int($quotamonth))){
$status=0; #нет превышения квоты
}


#if((0 < $quota)and(0 < $quotamonth)){
#$status=0; #нет превышения квоты
#}



}
if($querydate > $datemodified) { #если текущая дата перешла на новый день, то обновим текущую квоту на дефолтную дня
$newdayquota = "quota=$quotaday,datemodified=$querydate,";
}
else
{
$newdayquota="";
}

#print $querydate." - ".$datemodified;

$sql_updatequota = "UPDATE scsq_mod_quotas SET $newdayquota sumday=$DaySumSizeTraffic,summonth=$MonthSumSizeTraffic, status=$status where aliasid=$aliasid;";
$sth = $dbh->prepare($sql_updatequota);
$sth->execute; #


     }
print "Quotas updated";


#disconnecting from DB
#$rc = $dbh->disconnect;
