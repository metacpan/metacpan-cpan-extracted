#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/9_loginproperties.t 29    19-07-19 22:42 Sommar $
#
# This test suite tests that setloginproperty, Autoclose and CommandTimeout.
#
# $History: 9_loginproperties.t $
# 
# *****************  Version 29  *****************
# User: Sommar       Date: 19-07-19   Time: 22:42
# Updated in $/Perl/OlleDB/t
# Added test to make sure that AutoTranslate is still off when a
# connection string is used.
# 
# *****************  Version 28  *****************
# User: Sommar       Date: 19-07-17   Time: 21:42
# Updated in $/Perl/OlleDB/t
# Adapted the test to changes in SQL_version.
# 
# *****************  Version 27  *****************
# User: Sommar       Date: 15-05-24   Time: 22:26
# Updated in $/Perl/OlleDB/t
# Ripped out code specific for SQL 6.5 and some cleanup for SQL 7.
# 
# *****************  Version 26  *****************
# User: Sommar       Date: 12-08-19   Time: 14:53
# Updated in $/Perl/OlleDB/t
# Turns out that the character value from xp_msver has trailing blanks,
# which matters so that we retrieve SQL_version from @@version.
# 
# *****************  Version 25  *****************
# User: Sommar       Date: 12-08-15   Time: 21:29
# Updated in $/Perl/OlleDB/t
# New checks for the new login property ApplicationIntent and checks of
# what happens when you change the provider with an existing object.
# 
# *****************  Version 24  *****************
# User: Sommar       Date: 10-10-29   Time: 17:51
# Updated in $/Perl/OlleDB/t
# Cut two tests, since we cannot assume that we can use Window auth. 
#
# *****************  Version 23  *****************
# User: Sommar       Date: 10-10-29   Time: 17:28
# Updated in $/Perl/OlleDB/t
# Cut test 4, because on SQL 2008 error message if SQL auth is not
# enabled is the same as if it is enabled.
#
# *****************  Version 22  *****************
# User: Sommar       Date: 10-10-29   Time: 16:10
# Updated in $/Perl/OlleDB/t
# Final fix to the sql_init tests.
#
# *****************  Version 21  *****************
# User: Sommar       Date: 10-10-29   Time: 15:25
# Updated in $/Perl/OlleDB/t
# Reworked the tests for sql_init.
#
# *****************  Version 20  *****************
# User: Sommar       Date: 10-10-29   Time: 9:38
# Updated in $/Perl/OlleDB/t
# Added tests to handle the various forms of sql_init.
#
# *****************  Version 19  *****************
# User: Sommar       Date: 08-03-23   Time: 23:28
# Updated in $/Perl/OlleDB/t
# Handle empty provider value, so that it does not yield warnings about
# not being numeric.
#
# *****************  Version 18  *****************
# User: Sommar       Date: 07-11-12   Time: 22:14
# Updated in $/Perl/OlleDB/t
# Added two tests to see if we retrieve SqlVersion properly.
#
# *****************  Version 17  *****************
# User: Sommar       Date: 07-09-09   Time: 0:11
# Updated in $/Perl/OlleDB/t
# Correct checks for the provider version. Print error message for checks
# on changing passwords.
#
# *****************  Version 16  *****************
# User: Sommar       Date: 07-07-07   Time: 16:43
# Updated in $/Perl/OlleDB/t
# Added support for specifying different providers.
#
# *****************  Version 15  *****************
# User: Sommar       Date: 07-06-10   Time: 21:45
# Updated in $/Perl/OlleDB/t
# When testing that pooling is off, permit errors for monitor, since the
# error level is 16 on Katmai.
#
# *****************  Version 14  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 05-11-06   Time: 20:48
# Updated in $/Perl/OlleDB/t
# Move CommantTimeout tests to A_rowsetprops.t
#
# *****************  Version 12  *****************
# User: Sommar       Date: 05-10-16   Time: 23:34
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 11  *****************
# User: Sommar       Date: 05-08-20   Time: 22:50
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 10  *****************
# User: Sommar       Date: 05-08-14   Time: 19:55
# Updated in $/Perl/OlleDB/t
# Added tests for DisconnectOn
#
# *****************  Version 9  *****************
# User: Sommar       Date: 05-08-11   Time: 22:52
# Updated in $/Perl/OlleDB/t
# Added tests for is_connected().
#
# *****************  Version 8  *****************
# User: Sommar       Date: 05-07-25   Time: 0:41
# Updated in $/Perl/OlleDB/t
# Reworked the test for Network Address.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-06-27   Time: 22:36
# Updated in $/Perl/OlleDB/t
# Test for integrated security did not cater for the case connection was
# trusted, but user was not granted access.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-06-27   Time: 21:40
# Updated in $/Perl/OlleDB/t
# Change directory to the test directory.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-06-25   Time: 17:10
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-06-20   Time: 23:00
# Updated in $/Perl/OlleDB/t
# Added test for OldPassword.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-05-29   Time: 22:24
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-05-29   Time: 21:30
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-05-23   Time: 0:36
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

# This test script reads OLLEDBTEST directly, because it uses more fields
# from it.
my ($olledbtest) = $ENV{'OLLEDBTEST'};
my ($mainserver, $mainuser, $mainpw,
    $secondserver, $seconduser, $secondpw, $provider);
($mainserver, $mainuser, $mainpw, $secondserver, $seconduser, $secondpw, $provider) =
     split(/;/, $olledbtest) if defined $olledbtest;
   undef $provider if defined $provider and $provider !~ /\S/;

sub setup_testc {
    # Creates a test connection object with some common initial settings.
    my ($userpw) = @_;
    $userpw = 1 if not defined $userpw;
    my $testc;
    $testc = new Win32::SqlServer;
    $testc->{Provider} = $provider if defined $provider;
    $testc->setloginproperty('Server', $mainserver) if $mainserver;
    if ($userpw and $mainuser) {
       $testc->setloginproperty('Username', $mainuser);
    }
    if ($userpw and $mainpw) {
       $testc->setloginproperty('Password', $mainpw);
    }
    $testc->{ErrInfo}{PrintMsg}    = 17;
    $testc->{ErrInfo}{PrintLines}  = 17;
    $testc->{ErrInfo}{PrintText}   = 17;
    $testc->{ErrInfo}{MaxSeverity} = 17;
    $testc->{ErrInfo}{CarpLevel}   = 17;
    $testc->{ErrInfo}{SaveMessages} = 1;
    return $testc;
}

$^W = 1;

$| = 1;

chdir dirname($0);

print "1..45\n";

# Set up a monitor connection and get login configuration.
my $monitor = sql_init($mainserver, $mainuser, $mainpw, undef, $provider);
my ($monitorsqlver) = split(/\./, $monitor->{SQL_version});
my %loginconfig = $monitor->sql_one("EXEC master..xp_loginconfig 'login mode'");

# This is the connection we use for tests.
my $testc;

# Reappears every now and then.
my $errmsg;

# First tests, do we handle various values for Integrated Security corectly?
# Default we should connect with Integrated security.
$testc = setup_testc(0);
$testc->connect();
if (not $testc->{ErrInfo}{Messages} or
    $testc->{ErrInfo}{Messages}[0]{'text'} =~
       /(trusted .+ connection)|(Login failed for .+\\.+)/) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}
$testc->disconnect;

# Explicit enable with numeric value.
$testc = setup_testc(0);
$testc->setloginproperty('IntegratedSecurity', 1);
$testc->connect();
if (not $testc->{ErrInfo}{Messages} or
    $testc->{ErrInfo}{Messages}[0]{'text'} =~
       /(trusted .+ connection)|(Login failed for .+\\.+)/) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}
$testc->disconnect;


# Test login with Integrated Security off and nothing else on.
$testc->setloginproperty('IntegratedSecurity', 0);
delete $testc->{ErrInfo}{Messages};
$testc->connect();
$errmsg = $testc->{ErrInfo}{Messages}[0]{'text'};
if ($errmsg =~ /Invalid authorization specification/)  {
   print "ok 3\n";
}
else {
   print "not ok 3 # $errmsg\n";
}
$testc->disconnect;

# Test database property. And try autoconnect, while we're at it.
$testc = setup_testc;
$testc->{AutoConnect} = 1;
my $db = $testc->sql_one('SELECT db_name()');
# Do we have tempdb as default?
if ($db eq 'tempdb') {
   print "ok 4\n";
}
else {
   print "not ok 4 # $db\n";
}

# Test explicit database.
$testc->setloginproperty('Database', 'master');
$db = $testc->sql_one('SELECT db_name()');
if ($db eq 'master') {
   print "ok 5\n";
}
else {
   print "not ok 5 # $db\n";
}

# Test server property. Here we can't test the default value, as there might
# not be a local server. But we want to test what happens when we change
# servers.
if ($secondserver and $secondserver ne $mainserver) {
   $testc = setup_testc;
   $testc->{AutoConnect} = 1;

   # Set up connection to second server.
   $testc->setloginproperty('Server', $secondserver);
   if ($seconduser) {
      $testc->setloginproperty('Username', $seconduser);
      $testc->setloginproperty('Password', $secondpw);
   }
   else {
      $testc->setloginproperty('IntegratedSecurity', "SSPI");
   }

   # Get SQL version first thing we do.  xp_msver returns one more
   # componenet in version string that we don't have.
   my $newsqlver = $testc->{SQL_version};
   my @sqlver = split('\.', $newsqlver);
   my %thissqlver = $testc->sql_one("EXEC master..xp_msver 'Productversion'");
   my @thissqlver = split('\.', $thissqlver{'Character_Value'});
   if ($thissqlver[0] == $sqlver[0] and 
       $thissqlver[1] == $sqlver[1] and
       $thissqlver[2] == $sqlver[2]) {
      print "ok 6\n";
   }
   else {
      print "not ok 6\n";
   }

   # But did we really change servers? (We can't test for SERVERNAME, as
   # $secondserver may be an IP-address or an alias.)
   my $servername1 = $monitor->sql_one('SELECT @@servername', SCALAR);
   my $servername2 = $testc->sql_one('SELECT @@servername', SCALAR);
   if ($servername1 ne $servername2) {
      print "ok 7\n";
   }
   else {
      print "not ok 7\n";
   }

   # And change back. Now we execute a command before we look at SQL_version.
   $testc->setloginproperty('Server', $mainserver);
   if ($mainuser) {
      $testc->setloginproperty('Username', $mainuser);
      $testc->setloginproperty('Password', $mainpw);
   }
   else {
      $testc->setloginproperty('IntegratedSecurity', "SSPI");
   }
   @sqlver = split('\.', $testc->{SQL_version});
   %thissqlver = $testc->sql_one("EXEC master..xp_msver 'Productversion'");
   @thissqlver = split('\.', $thissqlver{'Character_Value'});
   if ($thissqlver[0] == $sqlver[0] and 
       $thissqlver[1] == $sqlver[1] and
       $thissqlver[2] == $sqlver[2]) {
      print "ok 8\n";
   }
   else {
      print "not ok 8\n";
   }
}
else {
   print "ok 6 # skip, no second server.\n";
   print "ok 7 # skip, no second server.\n";
   print "ok 8 # skip, no second server.\n";
}

# Time for a new object. We're going to test connection pooling now.
# Pooling should be on by default.
$testc = setup_testc;
$testc->connect;
$monitor->{ErrInfo}{PrintText} = 2;    # Suppress DBCC messages on SQL 7.
my $spid = $testc->sql_one('SELECT @@spid', SCALAR);
$testc->sql("PRINT 'Cornershot'");
$testc->disconnect;
my $inputbuffer;
$inputbuffer = $monitor->sql("DBCC INPUTBUFFER($spid) WITH NO_INFOMSGS",
                             SINGLESET, HASH);
my $colname = 'EventInfo';
if ($$inputbuffer[0] and $$inputbuffer[0]{$colname} =~ /^PRINT 'Cornershot'/) {
   print "ok 9\n";
}
else {
   print "not ok 9 # $$inputbuffer[0]{$colname}";
}

# Pooling off.
$testc->setloginproperty('Pooling', 0);
$testc->connect;
$spid = $testc->sql_one('SELECT @@spid', SCALAR);
$testc->sql("PRINT 'Penalty kick'");
$testc->disconnect;
sleep(1); # Permit for the test connection to actually go away.
$monitor->{ErrInfo}{SaveMessages} = 1;
$monitor->{ErrInfo}{MaxSeverity} = 16;
$monitor->{ErrInfo}{PrintMsg} = 17;
$monitor->{ErrInfo}{PrintLines} = 17;
$monitor->{ErrInfo}{PrintText} = 17;
$monitor->{ErrInfo}{CarpLevel} = 17;
delete $monitor->{ErrInfo}{Messages};
$inputbuffer = $monitor->sql("DBCC INPUTBUFFER($spid) WITH NO_INFOMSGS",
                             SINGLEROW, HASH);
if ($monitor->{ErrInfo}{Messages} and
    $monitor->{ErrInfo}{Messages}[0]{'text'} =~ /(Invalid SPID|does not process input)/i) {
   print "ok 10\n";
}
else {
   print "not ok 10\n";
}
$monitor->{ErrInfo}{MaxSeverity} = 10;
$monitor->{ErrInfo}{PrintMsg} = 1;
$monitor->{ErrInfo}{PrintLines} = 11;
$monitor->{ErrInfo}{PrintText} = 0;
$monitor->{ErrInfo}{CarpLevel} = 11;


# Pooling on again
$testc->setloginproperty('Pooling', 1);
$testc->connect;
$spid = $testc->sql_one('SELECT @@spid', SCALAR);
$testc->sql("PRINT 'Elfmeter'");
$testc->disconnect;
$monitor->{ErrInfo}{PrintText} = 1;  # Suppress DBCC messages on SQL 7.
$monitor->{ErrInfo}{SaveMessages} = 1;
$inputbuffer = $monitor->sql("DBCC INPUTBUFFER($spid) WITH NO_INFOMSGS",
                             SINGLESET, HASH);
if ($$inputbuffer[0] and $$inputbuffer[0]{$colname} =~ /^PRINT 'Elfmeter'/) {
   print "ok 11\n";
}
else {
   print "not ok 11 # $$inputbuffer[0]{'EventInfo'}\n";
}
$monitor->{ErrInfo}{PrintText} = 0;

# Testing Appname. There is a default which should be the script name,
$testc = setup_testc;
$testc->{AutoConnect} = 1;
my $name = $testc->sql_one('SELECT app_name()', SCALAR);
if ($name eq '9_loginproperties.t') {
   print "ok 12\n";
}
else {
   print "not ok 12 # $name\n";
}

# And set explicit.
$testc->setloginproperty('Appname', 'Papperstapet');
$name = $testc->sql_one('SELECT app_name()', SCALAR);
if ($name eq 'Papperstapet') {
   print "ok 13\n";
}
else {
   print "not ok 13 # $name\n";
}

$testc->setloginproperty('Language', 'Spanish');
$name = $testc->sql_one("SELECT convert(varchar, convert(datetime, '20030112'))");
if ($name =~ /^Ene 12 2003/) {
   print "ok 14\n";
}
else {
   print "not ok 14 # $name\n";
}


# AttachFilename. 
{
   $monitor->{ErrInfo}{PrintText} = 1;  # Suppress output from CREATE/DROP Database
   $monitor->sql('CREATE DATABASE OlleDB$test COLLATE Greek_CI_AS');
   my @helpdb = $monitor->sql_sp('sp_helpdb', ['OlleDB$test']);
   $monitor->sql_sp('sp_detach_db', ['OlleDB$test']);
   $monitor->{ErrInfo}{PrintText} = 0;
   my $filename = $helpdb[1]{'filename'};
   $filename =~ s!\\\\!\\!g;
   $filename =~ s!\s+$!!g;
   $testc = setup_testc;
   $testc->setloginproperty('AttachFilename', $filename);
   $testc->setloginproperty('Database', 'OlleDB test');
   $testc->setloginproperty('Pooling', 0);
   $testc->connect;
   $db = $testc->sql_one('SELECT db_name()');
   if ($db eq 'OlleDB test') {
      print "ok 15\n";
   }
   else {
      print "not ok 15 # $db\n";
   }
   $testc->disconnect;
}


# Network address. This works like server - maybe.
$testc = new Win32::SqlServer;
$testc->{Provider} = $provider if defined $provider;
$testc->setloginproperty('Networkaddress', $mainserver);
if ($mainuser) {
   $testc->setloginproperty('Username', $mainuser);
   $testc->setloginproperty('Password', $mainpw);
}
else {
   $testc->setloginproperty('IntegratedSecurity', "SSPI");
}
$testc->{ErrInfo}{PrintMsg}    = 17;
$testc->{ErrInfo}{PrintLines}  = 17;
$testc->{ErrInfo}{PrintText}   = 17;
$testc->{ErrInfo}{MaxSeverity} = 17;
$testc->{ErrInfo}{SaveMessages} = 1;
$testc->connect;
if (not exists($testc->{ErrInfo}{Messages})) {
   my $servername1 = $monitor->sql_one('SELECT @@servername', SCALAR);
   my $servername2 = $testc->sql_one('SELECT @@servername', SCALAR);
   if ($servername1 eq $servername2) {
      print "ok 16\n";
   }
   else {
      print "not ok 16 # servername = $servername2\n";
   }
}
else {
   print "not ok 16 # " . $testc->{ErrInfo}{Messages}[0]{'text'} . "\n";
}
$testc->disconnect;

# Network Library. We don't test this, because we cannot easily determine
# which protocols the server is running. (xp_regread would do it, but we
# are not being backwards for this.
if (1 == 0) {
   $testc = setup_testc;
   $testc->setloginproperty('NetLib', 'DBNMPNTW');
   $testc->connect;
   my $netlib = $testc->sql_one(<<'SQLEND', SCALAR);
   SELECT net_library FROM master.dbo.sysprocesses WHERE spid = @@spid
SQLEND
   warn "$netlib\n";
}

# Packet size. Only testable on SQL 2005.
if ($monitorsqlver >= 9) {
   $testc = setup_testc;
   $testc->setloginproperty('PacketSize', 1280);
   $testc->connect;
   my $pktsize = $testc->sql_one(<<'SQLEND', SCALAR);
   SELECT net_packet_size FROM sys.dm_exec_connections WHERE session_id = @@spid
SQLEND
   if ($pktsize == 1280) {
      print "ok 17\n";
   }
   else {
      print "not ok 17 # $pktsize\n";
   }
}
else {
   print "ok 17 # skip\n";
}

# Hostname. First test default, then to set name explicitly.
$testc = setup_testc;
$testc->{AutoConnect} = 1;
$name = $testc->sql_one('SELECT host_name()', SCALAR);
if ($name eq Win32::NodeName) {
   print "ok 18\n";
}
else {
   print "not ok 18 # $name\n";
}

# And set explicit.
$testc->setloginproperty('hOsTnAmE', 'Nyckelpiga');
$name = $testc->sql_one('SELECT host_name()', SCALAR);
if ($name eq 'Nyckelpiga') {
   print "ok 19\n";
}
else {
   print "not ok 19 # $name\n";
}

# Test connection string. If this attribute changeses, all other defaults 
# should be lost.
$testc = setup_testc;
my $connectstring = 'Database=OlleDB test;';
$connectstring .= "Server=$mainserver;" if $mainserver;
if ($mainuser) {
    $connectstring .= "UID=$mainuser;";
}
if ($mainpw) {
    $connectstring .= "PWD=$mainpw;"
}
if (not ($mainuser or $mainpw)) {
   $connectstring .= "Trusted_connection=Yes;";
}
$connectstring =~ s/;$//;
my $nothostname = (Win32::NodeName ne 'Sture' ? 'Sture' : 'Sten');
$testc->setloginproperty('Hostname', $nothostname);
$testc->setloginproperty('ConnectionString', $connectstring);
$testc->connect;
$name = $testc->sql_one('SELECT host_name()', SCALAR);
if ($name ne $nothostname) {
   print "ok 20\n";
}
else {
   print "not ok 20 # $name\n";
}
$name = $testc->sql_one('SELECT app_name()', SCALAR);
if ($name !~ /^9_login/) {
   print "ok 21\n";
}
else {
   print "not ok 21 # $name\n";
}
# Check that AutoTranslate is still off.
$testc->{BinaryAsStr} = 'x';
my $binary = $testc->sql_one('SELECT convert(varbinary, ?)', 
                             [['varchar(3)', "\x{03B1}\x{03B2}\x{03B3}"]], 
                             SCALAR);
if ($binary eq '0xE1E2E3') {
   print "ok 22\n";
}
else {
   print "not ok 22 # $binary\n";
}
$testc->disconnect;

# We can drop the database now.
$monitor->{ErrInfo}{PrintText} = 1;
$monitor->sql(<<SQLEND);
ALTER DATABASE [OlleDB test] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [OlleDB test]
SQLEND
$monitor->{ErrInfo}{PrintText} = 0;



# Test old password. This requires SQL 2005, SQL Native Client and SQL
# authentication.
if ($monitor->{Provider} >= PROVIDER_SQLNCLI and $monitorsqlver >= 9 and
    $loginconfig{'config_value'} !~ /^Windows/) {
   my $testuser = 'Olle' . rand;
   my $pw1 = 'pw1' . rand;
   my $pw2 = 'pw2' . rand;
   $monitor->sql("CREATE LOGIN [$testuser] WITH password = '$pw1' ," .
                 "CHECK_POLICY = OFF");

   # Test password change. We run without pooling, to make it possible to
   # drop login at end.
   $testc = setup_testc;
   $testc->setloginproperty('Username', $testuser);
   $testc->setloginproperty('Password', $pw2);
   $testc->setloginproperty('OldPassword', $pw1);
   $testc->setloginproperty('Pooling', 0);
   $testc->connect;
   if (not $testc->{ErrInfo}{Messages}) {
       print "ok 23\n";
   }
   else {
       print "not ok 23 # " . $testc->{ErrInfo}{Messages}[0]{'text'} . "\n";
   }
   $testc->disconnect();

   # And test that password really changed.
   $testc = setup_testc;
   $testc->setloginproperty('Username', $testuser);
   $testc->setloginproperty('Password', $pw2);
   $testc->setloginproperty('Pooling', 0);
   $testc->connect;
   if (not $testc->{ErrInfo}{Messages}) {
       print "ok 24\n";
   }
   else {
       print "not ok 24 # " . $testc->{ErrInfo}{Messages}[0]{'text'} . "\n";
   }
   $testc->disconnect();

   # Clean up
   $monitor->sql("DROP LOGIN [$testuser]");
}
else {
   print "ok 23 # skip\n";
   print "ok 24 # skip\n";
}

# Test is_connected
$testc = setup_testc;
if (not $testc->isconnected()) {
   print "ok 25\n";
}
else {
   print "not ok 25\n";
}

$testc->connect();
if ($testc->isconnected()) {
   print "ok 26\n";
}
else {
   print "not ok 26\n";
}

$testc->cancelbatch();
if ($testc->isconnected()) {
   print "ok 27\n";
}
else {
   print "not ok 27\n";
}

$testc->disconnect();
if (not $testc->isconnected()) {
   print "ok 28\n";
}
else {
   print "not ok 28\n";
}

# Don't pool this command, SQL 7 has problem with reusing connection
$testc->setloginproperty('Pooling', 0);
$testc->connect();
$testc->{ErrInfo}{MaxSeverity} = 25;
$testc->{ErrInfo}{PrintLines} = 25;
$testc->{ErrInfo}{PrintMsg} = 25;
$testc->{ErrInfo}{PrintText} = 25;
$testc->{ErrInfo}{CarpLevel} = 25;
$testc->sql("RAISERROR('Testing Win32::SqlServer', 20, 1) WITH LOG");
if (not $testc->isconnected()) {
   print "ok 29\n";
}
else {
   print "not ok 29\n";
}

# Test DisconnectOn in ErrInfo.
$testc->setloginproperty('Pooling', 1);
$testc->connect();
$testc->sql("SELECT * FROM #nosuchtable");
if ($testc->isconnected()) {
   print "ok 30\n";
}
else {
   print "not ok 30\n";
}

$testc->{CommandTimeout} = 1;
$testc->sql("WAITFOR DELAY '00:00:05'");
if ($testc->isconnected()) {
   print "ok 31\n";
}
else {
   print "not ok 31\n";
}


$testc->{ErrInfo}{DisconnectOn}{'208'}++;
$testc->sql("SELECT * FROM #nosuchtable");
if (not $testc->isconnected()) {
   print "ok 32\n";
}
else {
   print "not ok 32\n";
}

$testc->connect();
$testc->{CommandTimeout} = 1;
$testc->{ErrInfo}{DisconnectOn}{'HYT00'}++;
$testc->sql("WAITFOR DELAY '00:00:05'");
if (not $testc->isconnected()) {
   print "ok 33\n";
}
else {
   print "not ok 33\n";
}

# This test may seem out of place, but the code will try to access the
# SQL version while a batch is running.
undef $testc;
$testc = setup_testc;
$testc->{AutoConnect} = 1;
$testc->sql('SELECT getdate()', COLINFO_FULL);
if (not $testc->{ErrInfo}{Messages}) {
    print "ok 34\n";
}
else {
    print "not ok 34 # " . $testc->{ErrInfo}{Messages}[0]{'text'} . "\n";
}

undef $testc;
$testc = setup_testc;
$testc->connect();
$testc->sql('SELECT getdate()', COLINFO_FULL);
if (not $testc->{ErrInfo}{Messages}) {
    print "ok 35\n";
}
else {
    print "not ok 35 # " . $testc->{ErrInfo}{Messages}[0]{'text'} . "\n";
}

# Testing sql_init in its various forms.
undef $testc;
$testc = Win32::SqlServer::sql_init($mainserver, $mainuser, $mainpw, undef, $provider);
my $sqluser = $testc->sql_one('SELECT SYSTEM_USER', Win32::SqlServer::SCALAR);
if (defined $mainuser and $sqluser eq $mainuser or $sqluser =~ /\\/) {
   print "ok 36\n";
}
else {
   print "not ok 36\n";
}
$testc->disconnect();


undef $testc;
$testc = Win32::SqlServer->sql_init($mainserver, $mainuser, $mainpw, undef, $provider);
$sqluser = $testc->sql_one('SELECT SYSTEM_USER', Win32::SqlServer::SCALAR);
if (defined $mainuser and $sqluser eq $mainuser or $sqluser =~ /\\/) {
   print "ok 37\n";
}
else {
   print "not ok 37\n";
}
$testc->disconnect();

# Testing the ApplicationIntent property. We test this for all providers,
# since the behaviour should be the same in all cases. (We have no
# possibility to test that the stated intent is respected, as we can't
# creaste Availability Groups easily.
$testc = setup_testc;
$testc->setloginproperty('ApplicationIntent', 'READWRITE');
$testc->connect();
if ($testc->isconnected()) {
   print "ok 38\n";
}
else {
   print "not ok 38\n";
}

$testc = setup_testc;
$testc->setloginproperty('ApplicationIntent', 'readOnly');
$testc->connect();
if ($testc->isconnected()) {
   print "ok 39\n";
}
else {
   print "not ok 39\n";
}

$testc = setup_testc;
my $crap = Win32::NodeName();
eval(q!$testc->setloginproperty('ApplicationIntent', $crap)!);
if ($@ =~ /Illegal.*\'\Q$crap\E\'/) { 
   print "ok 40\n";
}
else {
   print "not ok 40\n";
}

# Now we will test changing providers. We cannot do this if the 
# provider already is SQLOLEDB, because that's what we're changing to.
# Also, we need to use DMVs in SQL 2005 and later.
if ($monitor->{Provider} != PROVIDER_SQLOLEDB and
    $monitorsqlver >= 9) {
   $testc = setup_testc;
   $testc->setloginproperty('appname', 'Lantluft');
   $testc->setloginproperty('HOSTNAME', 'Nettocourtage');
   $testc->connect();
   my $query = <<'SQLEND';
      SELECT app_name(), host_name(), client_version
      FROM   sys.dm_exec_sessions
      WHERE  session_id = @@spid
SQLEND
   my ($app, $host, $oledbver_save) = $testc->sql_one($query, LIST);
   if ($app eq 'Lantluft' and $host eq 'Nettocourtage') {
      print "ok 41\n";
   }
   else {
      print "not ok 41  # <$app> <$host>\n";
   }

   $testc->disconnect();
   $testc->{Provider} = PROVIDER_SQLOLEDB;
   $testc->connect();
   my $this_oledbver;
   ($app, $host, $this_oledbver) = $testc->sql_one($query, LIST);
   if ($app eq 'Lantluft' and $host eq 'Nettocourtage') {
      print "ok 42\n";
   }
   else {
      print "not ok 42  # <$app> <$host>\n";
   }
   
   if ($this_oledbver == 4) {
      print "ok 43\n";
   }
   else {
      print "not ok 43  # OLEDB ver = $this_oledbver\n";
   }

   $testc->disconnect();
   $testc->{Provider} = $monitor->{Provider};
   $testc->connect();
   ($app, $host, $this_oledbver) = $testc->sql_one($query, LIST);
   if ($app eq 'Lantluft' and $host eq 'Nettocourtage') {
      print "ok 44\n";
   }
   else {
      print "not ok 44  # <$app> <$host>\n";
   }
   
   if ($this_oledbver == $oledbver_save) {
      print "ok 45\n";
   }
   else {
      print "not ok 45 # OLEDB ver = $this_oledbver\n";
   }
}
else {
   print "ok 41 # skip\n";
   print "ok 42 # skip\n";
   print "ok 43 # skip\n";
   print "ok 44 # skip\n";
   print "ok 45 # skip\n";
}
