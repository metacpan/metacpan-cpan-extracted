#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/A_rowsetprops.t 5     07-09-09 0:10 Sommar $
#
# This test suite tests rowset properties, that is CommandTimeout and
# QueryNotification.
#
# $History: A_rowsetprops.t $
# 
# *****************  Version 5  *****************
# User: Sommar       Date: 07-09-09   Time: 0:10
# Updated in $/Perl/OlleDB/t
# Correct checks for the provider version.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-11-13   Time: 17:25
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-11-06   Time: 23:31
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-11-06   Time: 20:49
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

$^W = 1;
$| = 1;

my $olle = testsqllogin();
my ($sqlver) = split(/\./, $olle->{SQL_version});
my ($doqn) = ($sqlver >= 9 and $olle->{Provider} >= PROVIDER_SQLNCLI);

$olle->{ErrInfo}{PrintMsg}    = 17;
$olle->{ErrInfo}{PrintLines}  = 17;
$olle->{ErrInfo}{PrintText}   = 17;
$olle->{ErrInfo}{MaxSeverity} = 17;
$olle->{ErrInfo}{CarpLevel}   = 17;
$olle->{ErrInfo}{SaveMessages} = 1;

if ($olle->{Provider} == PROVIDER_SQLOLEDB) {
   print "1..11\n";
}
elsif ($sqlver < 9) {
   print "1..9\n";
}
else {
   print "1..18\n";
}

# Test command timeout on its own.
delete $olle->{ErrInfo}{Messages};
$olle->sql("WAITFOR DELAY '00:00:45'");
if (not $olle->{ErrInfo}{Messages}) {
   print "ok 1\n";
}
else {
   print "not ok 1\n";
}

delete $olle->{ErrInfo}{Messages};
$olle->{CommandTimeout} = 2;
$olle->sql("WAITFOR DELAY '00:00:45'");
if ($olle->{ErrInfo}{Messages}[0]{'text'} =~ /Timeout expired/i) {
   print "ok 2\n";
}
else {
   print "not ok 2\n";
}

# Test that we don't accept non-hash values for QueryNotification.
eval('$olle->{QueryNotification} = [1, 2, 3]');
if ($@ and $@ =~ /must be a hash ref/) {
   print "ok 3\n";
}
else {
   print "not ok 3 # \$\@ = '$@'\n";
}

eval('$olle->{QueryNotification} = undef');
if ($@ and $@ =~ /must be a hash ref/) {
   print "ok 4\n";
}
else {
   print "not ok 4 # \$\@ = '$@'\n";
}

# Test what happens when we fail to set Service for Query Notification.
delete $olle->{ErrInfo}{Messages};
$olle->{QueryNotification}{Message} = 'It keeps me wondering';
my $name = $olle->sql_one("SELECT name FROM master..sysdatabases WHERE dbid = 2", SCALAR);
if ($olle->{ErrInfo}{Messages}[0]{Text} =~ /no Service element/ and
    $olle->{ErrInfo}{Messages}[0]{Severity} == 10 and
    not defined $olle->{ErrInfo}{Messages}[1]) {
   print "ok 5\n";
}
else {
   print "not ok 5\n";
}
if ($name eq 'tempdb') {
   print "ok 6\n";
}
else {
   print "not ok 6\n";
}


if ($olle->{Provider} == PROVIDER_SQLOLEDB) {
# With SQLOLEDB, just check that we get good error message when we try to
# use query notification.
   delete $olle->{ErrInfo}{Messages};
   $olle->{CommandTimeout} = 2;
   $olle->{QueryNotification}{Service} = 'service=OlleServce';
   $olle->{QueryNotification}{Crap}    = 18;
   $olle->sql("WAITFOR DELAY '00:00:45'");
   if ($olle->{ErrInfo}{Messages}[0]{Text} =~ /QueryNotification .*ignored/i and
       $olle->{ErrInfo}{Messages}[0]{Severity} == 10) {
      print "ok 7\n";
   }
   else {
      print "not ok 7\n";
   }
   if ($olle->{ErrInfo}{Messages}[1]{'text'} =~ /Timeout expired/i) {
      print "ok 8\n";
   }
   else {
      print "not ok 8\n";
   }
   if (%{$olle->{QueryNotification}} == 0) {
      print "ok 9\n";
   }
   else {
      print "not ok 9\n";
   }

   delete $olle->{ErrInfo}{Messages};
   $olle->{CommandTimeout} = 0;
   $olle->{QueryNotification}{Service} = 'service=OlleServce';
   $olle->{QueryNotification}{Crap}    = 18;
   $name = $olle->sql(<<SQLEND, SCALAR, SINGLEROW);
   WAITFOR DELAY '00:00:05'
   SELECT name FROM master..sysdatabases WHERE dbid = 3
SQLEND
   if ($olle->{ErrInfo}{Messages}[0]{Text} =~ /QueryNotification .*ignored/i and
       $olle->{ErrInfo}{Messages}[0]{Severity} == 10 and
       not defined $olle->{ErrInfo}{Messages}[1]) {
      print "ok 10\n";
   }
   else {
      print "not ok 10\n";
   }
   if ($name eq 'model') {
      print "ok 11\n";
   }
   else {
      print "not ok 11\n";
   }

   exit;
}

# We have Native Client. But if we don't have SQL 2005, QN has no effect.
# But test this.
if ($sqlver < 9) {
   delete $olle->{ErrInfo}{Messages};
   $olle->{CommandTimeout} = 0;
   $olle->{QueryNotification}{Service} = 'service=OlleSerivce';
   $olle->{QueryNotification}{Crap}    = 18;
   $name = $olle->sql(<<SQLEND, SCALAR, SINGLEROW);
   WAITFOR DELAY '00:00:05'
   SELECT name FROM master..sysdatabases WHERE dbid = 3
SQLEND
   if (not defined $olle->{ErrInfo}{Messages}[0]{Text}) {
      print "ok 7\n";
   }
   else {
      print "not ok 7\n";
   }
   if ($name eq 'model') {
      print "ok 8\n";
   }
   else {
      print "not ok 8\n";
   }
   if (%{$olle->{QueryNotification}} == 0) {
      print "ok 9\n";
   }
   else {
      print "not ok 9\n";
   }

   exit;
}

# We have SQL Native Client and SQL 2005, so we can do query notification for
# real. First create a database with a queue and a service and then a table to
# query. We use a second connection to monitor the test.
my $monitor = testsqllogin();
$monitor->sql("CREATE DATABASE OlleQN");
$monitor->sql("USE OlleQN");
$olle->sql("USE OlleQN");
my $dbid = $monitor->sql_one('SELECT db_id()', SCALAR);
$monitor->sql(<<SQLEND);
CREATE QUEUE OlleQueue WITH RETENTION = OFF
CREATE SERVICE OlleService ON QUEUE OlleQueue
   ([http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification])
SQLEND
$monitor->sql(<<SQLEND);
CREATE TABLE qntest (a int NOT NULL PRIMARY KEY,
                     b nchar(5) NOT NULL,
                     c datetime NOT NULL)

INSERT qntest (a, b, c)
   SELECT 1, 'ALFKI', '19991212'
   UNION
   SELECT 2, 'BERGS', '19980612'
   UNION
   SELECT 3, 'VINET', '19991009'
   UNION
   SELECT 4, 'CILLA', '19990513'
   UNION
   SELECT 5, 'ALFKI', '19981112'
   UNION
   SELECT 6, 'LAKKA', '19991111'
   UNION
   SELECT 7, 'MALMÖ', '19990101'
   UNION
   SELECT 8, 'ALFKI', '19990630'
SQLEND

# First test. Default message and no timeout of any sort.
delete $olle->{ErrInfo}{Messages};
$olle->{CommandTimeout} = 0;
$olle->{QueryNotification}{Service} = 'service=OlleService;local database=OlleQN';
$olle->sql("SELECT a, b, c FROM dbo.qntest WHERE b = N'ALFKI'");
if (%{$olle->{QueryNotification}} == 0) {
   print "ok 7\n";
}
else {
   print "not ok 7\n";
}

if (not exists $olle->{ErrInfo}{Messages})  {
   print "ok 8\n";
}
else {
   print "not ok 8\n";
}

my $timeout = $monitor->sql_one(<<SQLEND, SCALAR);
SELECT timeout FROM sys.dm_qn_subscriptions WHERE database_id = $dbid
SQLEND
if ($timeout == 432000) {
   print "ok 9\n";
}
else {
   print "not ok 9\n";
}

# Run insert, so that we get a notification.
$monitor->sql("INSERT qntest (a, b, c) VALUES (10, 'ALFKI', '20010109')");

# And then get the nofification
my %data = $olle->sql(<<'SQLEND', SINGLEROW);
DECLARE @xml TABLE (x xml NOT NULL);
RECEIVE convert(xml, message_body) FROM OlleQueue INTO @xml
SELECT message = c.value(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                           (qn:Message)[1]', 'nvarchar(MAX)'),
       source  = c.value(N'@source', 'nvarchar(255)'),
       info    = c.value(N'@info',   'nvarchar(255)'),
       type    = c.value(N'@type',   'nvarchar(255)')
FROM   @xml x
CROSS  APPLY  x.x.nodes(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                /qn:QueryNotification') AS T(c)
SQLEND

if ($data{'source'} eq 'data' and $data{'type'} eq 'change' and
    $data{'info'} eq 'insert' and
    $data{'message'} =~ /Query notification .* Win32::SqlServer/) {
    print "ok 10\n";
}
else {
    print "not ok 10\n";
}

# There should now not be any subscriptions.
delete $olle->{ErrInfo}{Messages};
$olle->sql("SELECT a, b, c FROM dbo.qntest WHERE b = N'ALFKI'");
$timeout = $monitor->sql_one(<<SQLEND, [['int', $dbid]], SCALAR);
SELECT COUNT(*) FROM sys.dm_qn_subscriptions WHERE database_id = ?
SQLEND
if ($timeout == 0) {
    print "ok 11\n";
}
else {
    print "not ok 11\n";
}
if (not exists $olle->{ErrInfo}{Messages})  {
   print "ok 12\n";
}
else {
   print "not ok 12\n";
}


# This time set a timeout and a user-defined message. With shrimps in it.
delete $olle->{ErrInfo}{Messages};
$olle->{QueryNotification}{Service} = 'service=OlleService;local database=OlleQN';
$olle->{QueryNotification}{Message} = "<21 PA\x{0179}DZIERNIKA 2004>";
$olle->{QueryNotification}{Timeout} = 4711;
$olle->sql("SELECT a, b, c FROM dbo.qntest WHERE b = N'ALFKI'");

if (not exists $olle->{ErrInfo}{Messages})  {
   print "ok 13\n";
}
else {
   print "not ok 13\n";
}


$timeout = $monitor->sql_one(<<SQLEND, SCALAR);
SELECT timeout FROM sys.dm_qn_subscriptions WHERE database_id = $dbid
SQLEND
if ($timeout == 4711) {
   print "ok 14\n";
}
else {
   print "not ok 14\n";
}

# Get us a notification.
$monitor->sql("DELETE qntest WHERE a = 10");

# And then get the nofification
%data = $olle->sql(<<'SQLEND', SINGLEROW);
DECLARE @xml TABLE (x xml NOT NULL);
RECEIVE convert(xml, message_body) FROM OlleQueue INTO @xml
SELECT message = c.value(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                           (qn:Message)[1]', 'nvarchar(MAX)'),
       source  = c.value(N'@source', 'nvarchar(255)'),
       info    = c.value(N'@info',   'nvarchar(255)'),
       type    = c.value(N'@type',   'nvarchar(255)')
FROM   @xml x
CROSS  APPLY  x.x.nodes(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                /qn:QueryNotification') AS T(c)
SQLEND

if ($data{'source'} eq 'data' and $data{'type'} eq 'change' and
    $data{'info'} eq 'delete' and
    $data{'message'} eq "<21 PA\x{0179}DZIERNIKA 2004>") {
    print "ok 15\n";
}
else {
    print "not ok 15\n";
}

# Test with empty string for Message
delete $olle->{ErrInfo}{Messages};
$olle->{QueryNotification}{Service} = 'service=OlleService;local database=OlleQN';
$olle->{QueryNotification}{Message} = '';
$olle->sql("SELECT a, b, c FROM dbo.qntest WHERE b = N'ALFKI'");
if (not exists $olle->{ErrInfo}{Messages}) {
   print "ok 16\n";
}
else {
   print "not ok 16\n";
}


# Get us a notification.
$monitor->sql("DELETE qntest WHERE a = 1");

# And then get the nofification
%data = $olle->sql(<<'SQLEND', SINGLEROW);
DECLARE @xml TABLE (x xml NOT NULL);
RECEIVE convert(xml, message_body) FROM OlleQueue INTO @xml
SELECT message = c.value(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                           (qn:Message)[1]', 'nvarchar(MAX)'),
       source  = c.value(N'@source', 'nvarchar(255)'),
       info    = c.value(N'@info',   'nvarchar(255)'),
       type    = c.value(N'@type',   'nvarchar(255)')
FROM   @xml x
CROSS  APPLY  x.x.nodes(N'declare namespace qn="http://schemas.microsoft.com/SQL/Notifications/QueryNotification";
                /qn:QueryNotification') AS T(c)
SQLEND

if ($data{'source'} eq 'data' and $data{'type'} eq 'change' and
    $data{'info'} eq 'delete' and
    $data{'message'} =~ /Query notification .* Win32::SqlServer/) {
    print "ok 17\n";
}
else {
    print "not ok 17\n";
}


# Combine with a CommandTimeout
delete $olle->{ErrInfo}{Messages};
$olle->{CommandTimeout} = 2;
$olle->{QueryNotification}{Service} = 'service=OlleService;local database=OlleQN';
$olle->sql("SELECT a, b, c FROM dbo.qntest WHERE b = N'ALFKI'");

# This time we do not get us a notification.
$olle->sql('WAITFOR (RECEIVE * FROM OlleQueue)');
if ($olle->{ErrInfo}{Messages}[0]{'text'} =~ /Timeout expired/i) {
   print "ok 18\n";
}
else {
   print "not ok 18\n";
}



$olle->sql('USE master');
$monitor->sql("USE master");
$monitor->sql('DROP DATABASE OlleQN');
