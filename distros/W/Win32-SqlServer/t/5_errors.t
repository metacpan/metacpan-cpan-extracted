#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/5_errors.t 33    22-05-08 23:27 Sommar $
#
# Tests sql_message_handler and errors raised by OlleDB itself.
#
# $History: 5_errors.t $
# 
# *****************  Version 33  *****************
# User: Sommar       Date: 22-05-08   Time: 23:27
# Updated in $/Perl/OlleDB/t
# New OLE DB provider MSOLEDBSQL19.
# 
# *****************  Version 32  *****************
# User: Sommar       Date: 18-04-11   Time: 21:08
# Updated in $/Perl/OlleDB/t
# Support for the new provider MSOLEDBSQL.
# 
# *****************  Version 31  *****************
# User: Sommar       Date: 17-07-28   Time: 17:44
# Updated in $/Perl/OlleDB/t
# Adjustments for SQL 2017.
# 
# *****************  Version 30  *****************
# User: Sommar       Date: 15-05-24   Time: 22:27
# Updated in $/Perl/OlleDB/t
# Ripped out code specific for SQL 6.5.
# 
# *****************  Version 29  *****************
# User: Sommar       Date: 12-08-08   Time: 23:14
# Updated in $/Perl/OlleDB/t
# Some more testing about incorrect data types. Error messages have been
# changed.
# 
# *****************  Version 28  *****************
# User: Sommar       Date: 12-07-26   Time: 18:05
# Updated in $/Perl/OlleDB/t
# Added test that raise an error for typeinfo elements for data types to
# which typeinfo does not apply.
# 
# *****************  Version 27  *****************
# User: Sommar       Date: 12-07-21   Time: 0:09
# Updated in $/Perl/OlleDB/t
# Add support for SQLNCLI11.
# 
# *****************  Version 26  *****************
# User: Sommar       Date: 12-07-19   Time: 0:20
# Updated in $/Perl/OlleDB/t
# Removed superfluous \E, which Perl 5.16 compains about.
# 
# *****************  Version 25  *****************
# User: Sommar       Date: 08-08-17   Time: 23:30
# Updated in $/Perl/OlleDB/t
# Changes in error message from SQLNCLI10.
#
# *****************  Version 24  *****************
# User: Sommar       Date: 08-05-04   Time: 22:51
# Updated in $/Perl/OlleDB/t
# Still not right for SQL 6.5.
#
# *****************  Version 23  *****************
# User: Sommar       Date: 08-05-04   Time: 21:35
# Updated in $/Perl/OlleDB/t
# Small data-type goof forSQL 6.5.
#
# *****************  Version 22  *****************
# User: Sommar       Date: 08-05-04   Time: 19:06
# Updated in $/Perl/OlleDB/t
# We can only test OpenSqlFilestream with SQLNCLI10 after all.
#
# *****************  Version 21  *****************
# User: Sommar       Date: 08-03-23   Time: 19:33
# Updated in $/Perl/OlleDB/t
# Added tests for table valued-parameters.
#
# *****************  Version 20  *****************
# User: Sommar       Date: 08-02-24   Time: 21:58
# Updated in $/Perl/OlleDB/t
# Changed the test for no data types since the behaviour now is a little
# different.
#
# *****************  Version 19  *****************
# User: Sommar       Date: 08-01-06   Time: 23:34
# Updated in $/Perl/OlleDB/t
# Adjusted checks for error message on conversion of input value to
# include that it is a parameter (and not a column).
#
# *****************  Version 18  *****************
# User: Sommar       Date: 07-12-01   Time: 23:36
# Updated in $/Perl/OlleDB/t
# Added check of error handling with OpenSqlFilestream.
#
# *****************  Version 17  *****************
# User: Sommar       Date: 07-11-12   Time: 23:03
# Updated in $/Perl/OlleDB/t
# One more incorrect date format to test.
#
# *****************  Version 16  *****************
# User: Sommar       Date: 07-11-11   Time: 19:17
# Updated in $/Perl/OlleDB/t
# Test numbering was messed up.
#
# *****************  Version 15  *****************
# User: Sommar       Date: 07-11-11   Time: 17:33
# Updated in $/Perl/OlleDB/t
# Added checks for date/time values.
#
# *****************  Version 14  *****************
# User: Sommar       Date: 07-09-09   Time: 0:10
# Updated in $/Perl/OlleDB/t
# Handle the provider name more cleanly.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 05-11-13   Time: 21:46
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 11  *****************
# User: Sommar       Date: 05-08-17   Time: 0:37
# Updated in $/Perl/OlleDB/t
# Keys in Messages entries is now in uppercase.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 05-08-14   Time: 19:55
# Updated in $/Perl/OlleDB/t
# Added tests for SQLstate.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 05-08-09   Time: 21:21
# Updated in $/Perl/OlleDB/t
# Msg_handler is now MsgHandler.
#
# *****************  Version 8  *****************
# User: Sommar       Date: 05-07-25   Time: 0:40
# Updated in $/Perl/OlleDB/t
# Added  tests for errors with UDT and XML.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-06-27   Time: 21:41
# Updated in $/Perl/OlleDB/t
# Do prepend output file with directory name; testsqllogin.pl will chdir
# to the test directory.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-06-26   Time: 22:36
# Updated in $/Perl/OlleDB/t
# Adapted to some changes in parameter handling.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-03-28   Time: 18:42
# Updated in $/Perl/OlleDB/t
# Added test for too many parameters for a procedure.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-02-27   Time: 22:54
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-02-27   Time: 21:54
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-02-27   Time: 17:44
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-02-20   Time: 23:12
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);

use FileHandle;
use IO::Handle;
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

my($sql, $sql_call, $sp_call, $sql_callback, $msg_part, $sp_sql,
   $msgtext, $linestart, $expect_print, $expect_msgs, $errno, $state);

sub setup_a_test {
   # Sets up a test with an SQL command, an SP call and some stuff to be expected.
   my($sev) = @_;
   $errno     = 50000;
   $state     = 12;
   $msgtext   = "Er geht an die Ecke.";
   $sql       = qq!RAISERROR('$msgtext', $sev, $state)!;
   $sql_call  = "sql(q!$sql!, NORESULT)";
   $sp_call   = "sql_sp('#nisse_sp', ['$msgtext', $sev])";
   $msg_part  = "SQL Server message $errno, Severity $sev, State $state(, Server .+)?";
   $linestart = ' {3,5}1> ';
   $sp_sql    = "EXEC #nisse_sp (\\\@msgtext = '$msgtext', \\\@sev = $sev)";
}

$^W = 1;
$| = 1;

print "1..237\n";

my $X = testsqllogin();
my $sqlver = (split(/\./, $X->{SQL_version}))[0];
$X->{ErrInfo}{CheckRetStat} = 0;

# Set the provider name to use when testing provider messages.
my $PROVIDERNAME;
if ($X->{Provider} == Win32::SqlServer::PROVIDER_SQLOLEDB) {
   $PROVIDERNAME = 'Microsoft OLE DB Provider for SQL Server';
}
elsif ($X->{Provider} == Win32::SqlServer::PROVIDER_SQLNCLI) {
   $PROVIDERNAME = 'Microsoft SQL Native Client';
}
elsif ($X->{Provider} == Win32::SqlServer::PROVIDER_SQLNCLI10) {
   $PROVIDERNAME = 'Microsoft SQL Server Native Client 10.0';
}
elsif ($X->{Provider} == Win32::SqlServer::PROVIDER_SQLNCLI11) {
   $PROVIDERNAME = 'Microsoft SQL Server Native Client 11.0';
}
elsif ($X->{Provider} == Win32::SqlServer::PROVIDER_MSOLEDBSQL) {
   $PROVIDERNAME = 'Microsoft OLE DB Driver for SQL Server'
}
else {
   $PROVIDERNAME = 'Microsoft OLE DB Driver 19 for SQL Server'
}


$X->sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_sp @msgtext varchar(25), @sev int AS
   RAISERROR(@msgtext, @sev, 12)
SQLEND

# Default setting for error. Should die and print it all.
setup_a_test(11);
$expect_print = ["=~ /^$msg_part\\n/i",
                 "=~ /Procedure\\s+#nisse_sp[_0-9A-F]*,\\s+Line 2/",
                 "eq '$msgtext\n'",
                 "=~ /$linestart$sp_sql\n/"];
do_test($sp_call, 1, 1, $expect_print);

# Default setting for warning message. Should print message details but not
# lines, and not die.
setup_a_test(9);
$expect_print = ["=~ /^$msg_part\\n/i",
                 "=~ /Procedure\\s+#nisse_sp[_0-9A-F]*,\\s+Line 2/",
                 "eq '$msgtext\n'"];
do_test($sp_call, 4, 0, $expect_print);

# Default setting for print message. Should print only message, and not die.
setup_a_test(0);
$expect_print = ["eq '$msgtext\n'"];
do_test($sp_call, 7, 0, $expect_print);

# This should be completely silent.
do_test("sql('USE master')", 10, 0, []);

# But this should print the message.
delete $X->{ErrInfo}{NeverPrint}{5701};
do_test("sql('USE tempdb')", 13, 0, ["=~ /Changed database context/i"]);

# Again an error, but should not print lines, and not abort. But there should
# be a Perl warning.
setup_a_test(11);
$X->{errInfo}{neverStopOn}{$errno}++;
$X->{errInfo}{printLines} = 12;
$expect_print = ["=~ /^$msg_part\n/i",
                 "eq 'Line 1\n'",
                 "eq '$msgtext\n'",
                 "=~ /Message from SQL Server at/"];
do_test($sql_call, 16, 0, $expect_print);

# Should print full text. Should not abort. Should return messages.
setup_a_test(7);
$X->{errInfo}{neverStopOn}{$errno} = 0;
$X->{errInfo}{maxSeverity} = 7;
$X->{errInfo}{alwaysPrint}{$errno}++;
$X->{errInfo}{saveMessages}++;
$expect_print = ["=~ /^$msg_part\n/i",
                 "eq 'Line 1\n'",
                 "eq '$msgtext\n'",
                 "=~ /$linestart\Q$sql\E\n/",
                 "=~ /Message from SQL Server at/"];
$expect_msgs = [{State    => "== $state",
                 Errno    => "== $errno",
                 Severity => "== 7",
                 Text     => "eq '$msgtext'",
                 Line     => "== 1",
                 Server   => 'or 1',
                 SQLstate => '=~ /^\w{5,5}$/'}];
do_test($sql_call, 19, 0, $expect_print, $expect_msgs);

# Should abort. Should not print. Should not return new messages, but keep old.
setup_a_test(9);
$X->{errInfo}{alwaysStopOn}{$errno}++;
$X->{errInfo}{alwaysPrint} = 0;
$X->{errInfo}{neverPrint}{$errno}++;
$X->{errInfo}{saveMessages} = 0;
do_test($sp_call, 22, 1, [], $expect_msgs);

# Should abort. Should only print the text. Should not return messages.
delete $X->{errInfo}{alwaysPrint};
delete $X->{errInfo}{neverPrint};
delete $X->{errInfo}{messages};
$X->{errInfo}{printMsg} = 10;
$X->{errInfo}{CarpLevel} = 9;
$expect_print = ["eq '$msgtext\n'"];
do_test($sp_call, 25, 1, $expect_print);

# Should not abort. Should print the text and a Perl warning.
$X->{errInfo}{MaxSeverity} = 11;
delete $X->{errInfo}{alwaysStopOn}{$errno};
$X->{errInfo}{CarpLevel} = 9;
$expect_print = ["eq '$msgtext\n'",
                 "=~ /Message from SQL Server at/"];
do_test($sp_call, 28, 0, $expect_print);

# We now test the default XS handler.
setup_a_test(11);
$X->{MsgHandler} = undef;
$expect_print = [q!=~ /^(Server .+, )?Msg 50000, Level 11, State 12, Procedure '#nisse_sp[_0-9a-fA-F]*', Line 2/!,
                 "=~ /\\s+$msgtext\\n/"];
do_test($sp_call, 31, 0, $expect_print);

# And for informational message.
setup_a_test(9);
$X->{MsgHandler} = undef;
$expect_print = ["=~ /^$msgtext/"];
do_test($sp_call, 34, 0, $expect_print);

# Now we test to use a customer msg handler.
sub custom_MsgHandler {
   my ($X, $errno, $state, $sev, $text) = @_;
   print STDERR "This is the message: '$text'\n";
   return ($sev <= 10);
}
$X->{MsgHandler} = \&custom_MsgHandler;
$expect_print = [qq!eq "This is the message: '$msgtext'\n"!];
do_test($sp_call, 37, 0, $expect_print);

# Now it should abort
setup_a_test(11);
do_test($sp_call, 40, 1, $expect_print);

# Restore defaults by dropping $X and recreate.
undef $X;
$X = testsqllogin();

# We will now test settings for SQL state. First default.
$sql_call = q!$X->sql("WAITFOR DELAY '00:00:05'", NORESULT)!;
$X->{CommandTimeout} = 1;
$expect_print =
    ["=~ /Message HYT00 .*$PROVIDERNAME/",
     qq!=~ /[Tt]imeout expired\n/!,
     "=~ / 1> WAITFOR DELAY '00:00:05'/"];
do_test($sql_call, 43, 1, $expect_print);

# Suppress message.
$X->{ErrInfo}{NeverPrint}{'HYT00'}++;
do_test($sql_call, 46, 1, []);

# And don't die.
$X->{ErrInfo}{NeverStopOn}{'HYT00'}++;
do_test($sql_call, 49, 0, []);

# Remove this, but raise level for when to print and severity.
delete  $X->{ErrInfo}{NeverStopOn}{'HYT00'};
delete  $X->{ErrInfo}{NeverPrint}{'HYT00'};
$X->{ErrInfo}{MaxSeverity} = 17;
$X->{ErrInfo}{PrintLines} = 17;
$expect_print =
    ["=~ /Message HYT00 .*$PROVIDERNAME/",,
     qq!=~ /[Tt]imeout expired\n/!,
     "=~ /Message from $PROVIDERNAME at/"];
do_test($sql_call, 52, 0, $expect_print);

# Test AlwaysStopOn and AlwaysPrint.
$X->{ErrInfo}{AlwaysPrint}{'HYT00'}++;
$X->{ErrInfo}{AlwaysStopOn}{'HYT00'}++;
$expect_print =
    ["=~ /Message HYT00 .*$PROVIDERNAME/",,
     qq!=~ /[Tt]imeout expired\n/!,
     "=~ / 1> WAITFOR DELAY '00:00:05'/"];
do_test($sql_call, 55, 1, $expect_print);

# Once more restore defaults by dropping $X and recreate.
undef $X;
$X = testsqllogin();

# Now we test that if there are multiple errors that we get them all.
$X->{ErrInfo}{SaveMessages} = 1;
$sql = <<SQLEND;
CREATE TABLE #abc(a int NOT NULL)
DECLARE \@x int
INSERT #abc(a) VALUES (\@x)
SQLEND
$sql_call  = "\$X->sql(q!$sql!, NORESULT)";
my $nulltext = 'Cannot insert.+NULL';
my $termintext = 'The statement has been terminated';
$expect_print =
    ['=~ /SQL Server message 515, Severity 1[1-6], State \d+(, Server .+)?/',
     qq!eq "Line 3\n"!,
     "=~ /$nulltext/",
     '=~ / 1> CREATE TABLE #abc/',
     '=~ / 2> DECLARE \@x int/',
     '=~ / 3> INSERT #abc/',
     "=~ /$termintext/"];
$expect_msgs = [{State    => ">= 1",
                 Errno    => "== 515",
                 Severity => ">= 11",
                 Text     => "=~ /$nulltext/",
                 Line     => "== 3",
                 Server   => 'or 1',
                 SQLstate => '=~ /^\w{5,5}$/'},
                {State    => ">= 1",
                 Errno    => "== 3621",
                 Severity => "== 0",
                 Text     => "=~ /$termintext/",
                 Server   => 'or 1',
                 Line     => "== 3",
                 SQLstate => 'eq "01000"'}];
do_test($sql_call, 58, 1, $expect_print, $expect_msgs);

# And the same test for Perl warnings.
$X->{ErrInfo}{MaxSeverity} = 17;
$X->{ErrInfo}{SaveMessages} = 0;
delete $X->{ErrInfo}{Messages};
$sql_call = "\$X->sql(q!INSERT #abc(a) VALUES (NULL)!, NORESULT)";
$expect_print =
    ['=~ /SQL Server message 515, Severity 1[1-6], State \d+(, Server .+)?/',
     qq!eq "Line 1\n"!,
     '=~ /$nulltext/',
     '=~ / 1> INSERT #abc/',
     "=~ /$termintext/",
     "=~ /Message from SQL Server at/"];
do_test($sql_call, 61, 0, $expect_print);

# Next we will text the LinesWindow feature.
$X->{ErrInfo}{MaxSeverity} = 10;
$X->{ErrInfo}{SaveMessages} = 0;
delete $X->{ErrInfo}{Messages};
$sql = <<SQLEND;
-- 1st line.
-- 2nd line.
-- 3rd line.
-- 4th line.
RAISERROR('This is where it goes wrong', 11, 1)
-- 6th line.
-- 7th line.
SQLEND
$sql_call  = "\$X->sql(q!$sql!, NORESULT)";
$msg_part  = "SQL Server message 50000, Severity 11, State 1(, Server .+)?";
$expect_print = ["=~ /^$msg_part\\n/i",
                 "eq 'Line 5\n'",
                 "eq 'This is where it goes wrong\n'",
                 '=~ / 1> -- 1st line\.\n$/',
                 '=~ / 2> -- 2nd line\.\n$/',
                 '=~ / 3> -- 3rd line\.\n$/',
                 '=~ / 4> -- 4th line\.\n$/',
                q!=~ / 5> RAISERROR\('This is where it goes wrong', 11, 1\)\n$/!,
                 '=~ / 6> -- 6th line\.\n$/',
                 '=~ / 7> -- 7th line\.\n$/'];
do_test($sql_call, 64, 1, $expect_print);

$X->{ErrInfo}{LinesWindow} = 0;
$expect_print = ["=~ /^$msg_part\\n/i",
                 "eq 'Line 5\n'",
                 "eq 'This is where it goes wrong\n'",
         q!=~ / 5> RAISERROR\('This is where it goes wrong', 11, 1\)\n$/!];
do_test($sql_call, 67, 1, $expect_print);

$X->{ErrInfo}{LinesWindow} = 1;
$expect_print = ["=~ /^$msg_part\\n/i",
                 "eq 'Line 5\n'",
                 "eq 'This is where it goes wrong\n'",
                 '=~ /^ {3,5}4> -- 4th line\.\n$/',
         q!=~ / 5> RAISERROR\('This is where it goes wrong', 11, 1\)\n$/!,
                 '=~ /^ {3,5}6> -- 6th line\.\n$/'];
do_test($sql_call, 70, 1, $expect_print);

$X->{ErrInfo}{LinesWindow} = 3;
$expect_print = ["=~ /^$msg_part\\n/i",
                 "eq 'Line 5\n'",
                 "eq 'This is where it goes wrong\n'",
                 '=~ / 2> -- 2nd line\.\n$/',
                 '=~ / 3> -- 3rd line\.\n$/',
                 '=~ / 4> -- 4th line\.\n$/',
                q!=~ / 5> RAISERROR\('This is where it goes wrong', 11, 1\)\n$/!,
                 '=~ / 6> -- 6th line\.\n$/',
                 '=~ / 7> -- 7th line\.\n$/'];
do_test($sql_call, 73, 1, $expect_print);

# Now we test messages from the OLE DB provider. First one of these obscure
# message we can't really tell what they are due to.
$X->{ErrInfo}{SaveMessages} = 1;
$sql_call = <<'PERLEND';
$X->initbatch("SELECT ?");
$X->executebatch;
$X->cancelbatch;
PERLEND
$expect_print =
    ["=~ /^Message [0-9A-F]{8}.*$PROVIDERNAME.*Severity:? 16/i",
     '=~ /Win32::SqlServer call/',
     '=~ /No value given/',
     '=~ / 1> SELECT \?/'];
$expect_msgs = [{State    => "== 127",
                 Errno    => "<= -1",
                 Severity => "== 16",
                 Text     => "=~ /No value given/",
                 Line     => "== 0",
                 Proc     => "eq 'cmdtext_ptr->Execute'",
                 SQLstate => "=~ /[0-9A-F]{8}/i",
                 Source   => "=~ /$PROVIDERNAME/"}];
do_test($sql_call, 76, 1, $expect_print, $expect_msgs);

# This one generates a provider message.
$X->sql(<<'SQLEND');
   CREATE PROCEDURE #date_sp @d smalldatetime,
                             @e datetime = '19870101' AS
   SELECT @d = @d
SQLEND
$sql_call = '$X->sql_sp("#date_sp", ["2079-12-01"])';
$expect_print =
    ["=~ /^Message \\w{5}.*$PROVIDERNAME.*Severity:? 16/i",
     ($X->{Provider} <= PROVIDER_SQLNCLI ?
          "=~ /Invalid.*cast specification/" :
          "=~ /Invalid date format/"),
     q!=~ / {3,5}1> EXEC #date_sp\s+\@d\s*=\s*'2079-12-01'/!];
push(@$expect_msgs, {State    => '>= 1',
                     Errno    => '== 0',
                     Severity => '== 16',
                     Text     => ($X->{Provider} <= PROVIDER_SQLNCLI ?
                                     "=~ /Invalid.*cast specification/" :
                                     "=~ /Invalid date format/"),
                     Line     => '== 0',
                     SQLstate => '=~ /\w{5}/',
                     Source   => "=~ /$PROVIDERNAME/"});
do_test($sql_call, 79, 1, $expect_print, $expect_msgs);

# Now we move on to test OlleDB's own messages. First errors with datetime
# hashes.
delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#date_sp", [{Year => 1991, Day => 17}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Mandatory part 'Month' missing/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #date_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Mandatory part 'Month' missing/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 82, 1, $expect_print, $expect_msgs);

# An error with an illegal value. We also test what happens if MaxSeverity
# permits continued execution.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = '$X->sql_sp("#date_sp", [{Year => 1991, Month => 13, Day => 17}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Month' .+ illegal value 13/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #date_sp\s+\@d\s*=\s*'HASH\(/!,
     "=~ /Message from Win32::SqlServer at/"];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Month' .+ illegal value 13/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 85, 0, $expect_print, $expect_msgs);

# Unknown data type and an illegal decimal value.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{MaxSeverity} = 10;
$sql_call = <<'PERLEND';
$X->sql('SELECT ?, ?', [['bludder', 12],
                        ['decimal(5,2)', 12345]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Unknown .+ 'bludder' .+ parameter '\@P1'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value .+12345.+ decimal.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC sp_executesql\s+N'SELECT \@P1, \@P2'/!,
     q!=~ / 2> \s+N'\@P1 bludder,\s+\@P2 decimal\(5,\s*2\)',/!,
     q!=~ / 3> \s+\@P1\s*=\s*12,\s+\@P2\s*=\s*12345\s/!];

$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Unknown .+ 'bludder' .+ parameter '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value .+12345.+ decimal.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 88, 1, $expect_print, $expect_msgs);

# Malformed data types
delete $X->{ErrInfo}{Messages};
$sql_call = <<'PERLEND';
$X->sql('SELECT ?, ?, ?', [['float(53)', 12],
                           ['binary(5,2)', 12345],
                           ['nosuchtype', undef]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Unknown .+ 'float\(53\)' .+ parameter '\@P1'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Unknown .+ 'binary\(5,2\)' .+ parameter '\@P2'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Unknown .+ 'nosuchtype' .+ parameter '\@P3'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC sp_executesql\s+N'SELECT \@P1, \@P2, \@P3'/!,
     q!=~ / 2> \s+N'\@P1 float\(53\), \@P2 binary\(5,2\), \@P3 nosuchtype'/!,
     q!=~ / 3> \s+\@P1 = 12, \@P2 = 12345, \@P3 = NULL\s/!];

$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Unknown .+ 'float\(53\)' .+ parameter '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Unknown .+ 'binary\(5,2\)' .+ parameter '\@P2'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Unknown .+ 'nosuchtype' .+ parameter '\@P3'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 91, 1, $expect_print, $expect_msgs);


# Testing call to non-existing stored procedure
delete $X->{ErrInfo}{Messages};
$sql_call = q!$X->sql_sp('#notthere')!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /procedure '#notthere'/"];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /procedure '#notthere'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 94, 1, $expect_print, $expect_msgs);

# Test calling procedure with non-existing parameter.
delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#date_sp", {notpar => "2103-01-01", hugo => 12})';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Procedure '#date_sp' .+ parameter.+'\@(notpar|hugo)'/!,
     "=~ /Message from Win32::SqlServer at/",
     q'=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Procedure '#date_sp' .+ parameter.+'\@(notpar|hugo)'/!,
     "=~ /Message from Win32::SqlServer at/",
     q'=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     q!=~ /2 unknown.+Cannot execute/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Procedure '#date_sp' .+ parameter.+'\@(notpar|hugo)'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Procedure '#date_sp' .+ parameter.+'\@(notpar|hugo)'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /2 unknown.+Cannot execute/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 97, 1, $expect_print, $expect_msgs);

# Test calling procedure with too many parameters.
delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#date_sp", ["2103-01-01", "2103-01-01", 12])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     q!=~ /3 parameters passed .+ '#date_sp' .+ only .*(two|2) parameters\b/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /3 parameters passed .+ '#date_sp' .+ only .*(two|2) parameters\b/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 100, 1, $expect_print, $expect_msgs);


# Named/unnamed mixup, and OUTPUT is not reference. This includes a PRINT
# messages to see that the correct value of @sev is used.
$X->sql(<<'SQLEND');
   CREATE PROCEDURE #partest_sp @msgtext varchar(25) OUTPUT,
                                @sev int, @r int = 9 OUTPUT AS
   RAISERROR(@msgtext, @sev, 12)
SQLEND
delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#partest_sp", ["Plain vanilla", 0, \$state], {sev => 17})';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /arameter '\@sev' .+ position 2 .+ unnamed .+ named/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Output parameter '\@msgtext' .+ not .+ reference/!,
     "=~ /Message from Win32::SqlServer at/",
     'eq "Plain vanilla\n"'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /arameter '\@sev' .+ position 2 .+ unnamed .+ named/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Output parameter '\@msgtext' .+ not .+ reference/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '== 12',
                 Errno    => '== 50000',
                 Severity => '== 0',
                 Text     => 'eq "Plain vanilla"',
                 SQLstate => 'eq "01000"',
                 Server   => 'or 1',
                 Line     => '== 3',
                 Proc     => '=~ /^#partest_sp[_[0-9A-F]*/'}];
do_test($sql_call, 103, 0, $expect_print, $expect_msgs);


# Same parameter with and without the @. And test NoWhine. No warning about
# @msgtext here.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{NoWhine}++;
$sql_call = q!$X->sql_sp("#partest_sp", ["Plain vanilla"], {sev => 17, '@sev' => 0})!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /hash parameters .+ key 'sev' .+ '\@sev'/!,
     "=~ /Message from Win32::SqlServer at/",
     'eq "Plain vanilla\n"'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /hash parameters .+ 'sev' .+ '\@sev'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '== 12',
                 Errno    => '== 50000',
                 Severity => '== 0',
                 Text     => 'eq "Plain vanilla"',
                 SQLstate => 'eq "01000"',
                 Server   => 'or 1',
                 Line     => '== 3',
                 Proc     => '=~ /^#partest_sp[_[0-9A-F]*/'}];
do_test($sql_call, 106, 0, $expect_print, $expect_msgs);


# sql_insert with non-existing table.
delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_insert("#notthere", {sev => 17})';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /Table '#notthere'/"];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Table '#notthere'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 109, 1, $expect_print, $expect_msgs);

# Parameter clash with sql.
delete $X->{ErrInfo}{Messages};
$sql_call = <<'PERLEND';
   $X->sql('RAISERROR(?, ?, ?)', [['varchar', 'This is jazz'],
                                  ['smallint', 14],
                                  ['smallint', 17]],
                                 {'@P2' => ['smallint', 10]});
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /named parameter '\@P2', .+ 3.+unnamed/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /SQL Server message 50000, Severity 14, State 17(, Server .+)?/',
     qq!eq "Line 1\n"!,
     'eq "This is jazz\n"',
     q!=~ / 1> EXEC sp_executesql\s+N'RAISERROR\(\@P1, \@P2, \@P3\)'/!,
     q!=~ / 2> \s+N'\@P1 varchar\(\d+\),\s+\@P2 smallint,\s*\@P3 smallint',/!,
     q!=~ / 3> \s+\@P1 = 'This is jazz', \@P2 = 14, \@P3 = 17/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /named parameter '\@P2', .+ 3.+unnamed/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '== 17',
                 Errno    => '== 50000',
                 Severity => '== 14',
                 Text     => 'eq "This is jazz"',
                 Line     => '== 1',
                 Server   => 'or 1',
                 SQLstate => 'eq "42000"'}];
do_test($sql_call, 112, 1, $expect_print, $expect_msgs);

# No data type specified.
delete $X->{ErrInfo}{Messages};
$sql_call = <<'PERLEND';
   $X->sql('RAISERROR(?, 12, 17)', ['This is jazz', undef]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /no datatype .+ parameter '\@P1', value 'This is jazz'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /SQL Server message 50000, Severity 12, State 17(, Server .+)?/',
     qq!eq "Line 1\n"!,
     'eq "This is jazz\n"',
     q!=~ / 1> EXEC sp_executesql\s+N'RAISERROR\(\@P1, 12, 17\)'/!,
     q!=~ / 2> \s+N'\@P1 varchar\(8000\),\s+\@P2 varchar\(8000\)'/!,
     q!=~ / 3> \s+\@P1 = 'This is jazz', \@P2 = NULL/!];

$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /no datatype .+ parameter '\@P1', value 'This is jazz'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '== 17',
                 Errno    => '== 50000',
                 Severity => '== 12',
                 Text     => 'eq "This is jazz"',
                 Line     => '== 1',
                 Server   => 'or 1',
                 SQLstate => 'eq "42000"'}];
do_test($sql_call, 115, 1, $expect_print, $expect_msgs);

# Scale/precision missing for decimal.
delete $X->{ErrInfo}{Messages};
$sql = <<'SQLEND';
DECLARE @out varchar(200)
SELECT @out = convert(varchar, ?) + ' -- ' + convert(varchar, ?) + ' -- ' +
              convert(varchar, ?)
PRINT @out
SQLEND
$sql_call = <<PERLEND;
   \$X->sql(q!$sql!, [['decimal', 47.11],
                     ['numeric(9)', 47.11],
                     ['decimal(9,3)', 47.11]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Precision .+ scale missing .+ '\@P1'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /Precision .+ scale missing .+ '\@P2'/!,
     "=~ /Message from Win32::SqlServer at/",
     'eq "47 -- 47 -- 47.110\n"'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Precision .+ scale missing .+ '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Precision .+ scale missing .+ '\@P2'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '== 0',
                 Severity => '== 0',
                 Text     => 'eq "47 -- 47 -- 47.110"',
                 Line     => '== 4',
                 Server   => 'or 1',
                 SQLstate => 'eq "01000"'}];
do_test($sql_call, 118, 0, $expect_print, $expect_msgs);

# Duplicate parameter names.
delete $X->{ErrInfo}{Messages};
$sql_call = <<'PERLEND';
   $X->sql('RAISERROR(@P1, 4, 1)', {P1    => ['varchar', 'This is jazz'],
                                    '@P1' => ['varchar', 'Katzenjammer']});
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     q!=~ /hash parameters .+ key 'P1' .+ '\@P1'/!,
     "=~ /Message from Win32::SqlServer at/",
     '=~ /SQL Server message 50000, Severity 4, State 1(, Server .+)?/',
     qq!eq "Line 1\n"!,
     'eq "Katzenjammer\n"'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /hash parameters .+ key 'P1' .+ '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '== 1',
                 Errno    => '== 50000',
                 Severity => '== 4',
                 Text     => 'eq "Katzenjammer"',
                 Line     => '== 1',
                 Server   => 'or 1',
                 SQLstate => 'eq "01000"'}];
do_test($sql_call, 121, 0, $expect_print, $expect_msgs);

# Using UDT without specifying user-type. (We can do this on all platforms,
# because this is trapped early by OlleDB itself.)
delete $X->{ErrInfo}{Messages};
$sql_call = q!$X->sql('SELECT ?', [['UDT', undef]])!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /No actual user type .+ UDT .+ '\@P1'/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /No actual user type .+ UDT .+ '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 124, 1, $expect_print, $expect_msgs);

# UDT with conflicting specifiers.
delete $X->{ErrInfo}{Messages};
$sql_call = q!$X->sql('SELECT ?', [['UDT(OllePoint)', undef, 'OlleString']])!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Conflicting .+ \('OllePoint' and 'OlleString'\) .+ '\@P1' .+ UDT/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Conflicting .+ \('OllePoint' and 'OlleString'\) .+ '\@P1' .+ UDT/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 127, 1, $expect_print, $expect_msgs);

# XML with conflicting specifiers.
delete $X->{ErrInfo}{Messages};
$sql_call = q!$X->sql('SELECT ?', [['xml(OlleSC)', undef, 'OlleSC2']])!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Conflicting .+ \('OlleSC' and 'OlleSC2'\) .+ '\@P1' .+ xml/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Conflicting .+ \('OlleSC' and 'OlleSC2'\) .+ '\@P1' .+ xml/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 130, 1, $expect_print, $expect_msgs);

# Typeinfo for data types that does not have typeinfo.
delete $X->{ErrInfo}{Messages};
$sql_call = q!$X->sql('SELECT ?', [['varbinary', undef, 5]])!;
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /^The third element in the parameter array/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /^The third element in the parameter array/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 133, 1, $expect_print, $expect_msgs);


# We will now test sql_has_errors. First get a default connection.
undef $X;
$X = testsqllogin();
$X->{ErrInfo}{MaxSeverity} = 17;
$X->{ErrInfo}{NeverPrint}{50000}++;
$X->sql("RAISERROR('Test', 11, 10)", NORESULT);
{
   my (@warns);
   local $SIG{__WARN__} = sub {push(@warns, $_[0])};

   # Since SaveMessages is off we should not get false back
   if (not $X->sql_has_errors) {
      print "ok 136\n";
   }
   else {
      print "not ok 136\n";
   }

   # ...but we should be warned.
   if (@warns) {
      print "ok 137\n";
   }
   else {
      print "not ok 137\n";
   }
}

$X->{ErrInfo}{SaveMessages} = 1;
$X->sql("RAISERROR('Test', 11, 10)", NORESULT);
if ($X->sql_has_errors) {
   print "ok 138\n";
}
else {
   print "not ok 138\n";
}


# The error should still be there.
if (exists $X->{ErrInfo}{Messages}) {
   print "ok 139\n";
}
else {
   print "not ok 139\n";
}

delete $X->{ErrInfo}{Messages};
$X->sql("RAISERROR('Test', 9, 10)", NORESULT);
if (not $X->sql_has_errors(1)) {
   print "ok 140\n";
}
else {
   print "not ok 140\n";
}

# The message should still be there, as we said to sql_has_errors.
if (scalar(@{$X->{ErrInfo}{Messages}}) == 1) {
   print "ok 141\n";
}
else {
   print "not ok 141\n";
}

# But after this.
$X->sql_has_errors();
if (not exists $X->{ErrInfo}{Messages}) {
   print "ok 142\n";
}
else {
   print "not ok 142\n";
}

$X->sql(<<SQLEND, NORESULT);
RAISERROR('Test1', 9, 10)
RAISERROR('Test2', 11, 10)
RAISERROR('Test3', 0, 10)
SQLEND
if ($X->sql_has_errors()) {
   print "ok 143\n";
}
else {
   print "not ok 143\n";
}

if (scalar(@{$X->{ErrInfo}{Messages}}) == 3) {
   print "ok 144\n";
}
else {
   print "not ok 144\n";
}

# Lots of tests around date/time data types. Use a new connection for this.
undef $X;
$X = testsqllogin();
$X->{ErrInfo}{SaveMessages}++;

$X->sql(<<'SQLEND');
   CREATE PROCEDURE #datetime_sp @d datetime,
                                 @sd smalldatetime AS
   SELECT @d = @d
SQLEND
if ($sqlver >= 10) {
   $X->sql(<<'SQLEND');
      CREATE PROCEDURE #time_sp @d time AS
      SELECT @d = @d
SQLEND
   $X->sql(<<'SQLEND');
      CREATE PROCEDURE #date_sp @d date AS
      SELECT @d = @d
SQLEND
   $X->sql(<<'SQLEND');
      CREATE PROCEDURE #dtoffset_sp @d datetimeoffset AS
      SELECT @d = @d
SQLEND
   $X->sql(<<'SQLEND');
      CREATE PROCEDURE #datetime2_sp @d datetime2 AS
      SELECT @d = @d
SQLEND
}

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", [{Year => 1991, Month => 0, Day => 17},
                                          "20010101"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Month' .* illegal value 0/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Month' .* illegal value/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 145, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1750-12-20", "20010101"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Year' .* illegal value 1750/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1750/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Year' .* illegal value 1750/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 148, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", [{Year => 1991, Month => 65537, Day => 17},
                                          "1899-12-31"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Month' .* illegal value 65537/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Year' .* illegal value 1899/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Month' .* illegal value 65537/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Year' .* illegal value 1899/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 151, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", [{Year => -1991, Month => 12, Day => 17},
                                          "1999-12-31 24:00:00"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Year' .* illegal value -1991/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Hour' .* illegal value 24/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Year' .* illegal value -1991/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Hour' .* illegal value 24/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 154, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-02-29", "1999-11-31"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Day' .* illegal value 29/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Day' .* illegal value 31/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Day' .* illegal value 29/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Day' .* illegal value 31/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 157, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-01-31 12:60:60", "1999-03-31 12:59:60"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Minute' .* illegal value 60/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Second' .* illegal value 60/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Minute' .* illegal value 60/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Second' .* illegal value 60/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 160, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-05-31 00:00:00.9999999",
                                         {Year => 1997, Month => 10, Day => 31,
                                         Fraction => -2}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'Fraction' .* illegal value -2/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'Fraction' .* illegal value -2/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 163, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-04-30 14:12:10 +25:00",
                                         {Year => 1997, Month => 12, Day => 1,
                                         Hour => 12, Minute => 12,
                                         TZHour => -2, TZMinute => 15}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'TZHour' .* illegal value 25/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'TZMinute' .* illegal value 15/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'TZHour' .* illegal value 25/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'TZMinute' .* illegal value 15/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 166, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-0829 12:00:00",
                                         {Year => 1997, Month => 12, Day => 1,
                                         Hour => 12, Minute => 12,
                                         TZHour => 2, TZMinute => -15}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Part 'TZMinute' .* illegal value -15/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Part 'TZMinute' .* illegal value -15/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 169, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-08-29 12:00:00.12323 +0200",
                                         {Year => 1997, Month => 12, Day => 1,
                                         Hour => 12, Minute => 12,
                                         TZMinute => 15}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /TZMinute appears in datetime hash/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /TZMinute appears in datetime hash/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 172, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["19970225 12:00.00", "1997"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 175, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-02-25Z12:00", "1997-12-12 12"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ smalldatetime/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 178, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1997-02-25 12:00:", "1997-09-23 12:00:00."])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1997.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1997/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1997.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 181, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime_sp", ["1925-08-07T", "1925-08-07T12"])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1925.+ datetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Could not convert Perl value '1925.+ smalldatetime.+parameter/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime_sp\s+\@d\s*=\s*'1925/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1925.+ datetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Could not convert Perl value '1925.+ smalldatetime.+parameter/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 184, 1, $expect_print, $expect_msgs);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#date_sp", [{Month => 10, Day => 17}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Mandatory part 'Year' missing/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     '=~ /Could not convert Perl value.+ date\b.+parameter/',
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #date_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Mandatory part 'Year' missing/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => '=~ /Could not convert Perl value.+ date\b.+parameter/',
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 187, 1, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#time_sp", [{Hour => 10, Second => 17}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Mandatory part 'Minute' missing/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     '=~ /Could not convert Perl value.+ time\b.+parameter/',
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #time_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Mandatory part 'Minute' missing/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => '=~ /Could not convert Perl value.+ time\b.+parameter/',
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 190, 1, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#datetime2_sp", [{Year => 1078, Month => 10}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Mandatory part 'Day' missing/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     '=~ /Could not convert Perl value.+ datetime2\b.+parameter/',
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #datetime2_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Mandatory part 'Day' missing/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => '=~ /Could not convert Perl value.+ datetime2\b.+parameter/',
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 193, 1, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$sql_call = '$X->sql_sp("#dtoffset_sp", [{Year => 2341, Day => 17,
                                          Hour => 12, Minute => 12, Second => 34,
                                          TZHour => 0, TZMinute => 0}])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     "=~ /Mandatory part 'Month' missing/",
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
     '=~ /Could not convert Perl value.+ datetimeoffset\b.+parameter/',
     "=~ /Message from Win32::SqlServer at/",
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
     q!=~ / 1> EXEC #dtoffset_sp\s+\@d\s*=\s*'HASH\(/!];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => "=~ /Mandatory part 'Month' missing/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => '=~ /Could not convert Perl value.+ datetimeoffset\b.+parameter/',
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 196, 1, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

# A single test with OpenSqlFilestream.
delete $X->{ErrInfo}{Messages};
$X->{BinaryAsStr} = 'x';
$sql_call = '$X->OpenSqlFilestream("Garbage", 0, "0x47114711")';
$expect_print =
    ['=~ /^Message -87.+OpenSqlFilestream.+Severity:? 16/',
     '=~ /The parameter is incorrect/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '== -87',
                 Severity => '== 16',
                 Line     => '== 0',
                 Text     => "=~ /The parameter is incorrect/",
                 Source   => "eq 'OpenSqlFilestream'"}];
do_test($sql_call, 199, 1, $expect_print, $expect_msgs, undef, PROVIDER_SQLNCLI10);

# Let's test table-valued parameters. First some setup.
if ($sqlver >= 10) {
   $X->sql(<<'SQLEND');
IF EXISTS (SELECT * FROM sys.table_types WHERE name = 'olle$tvptest')
   DROP TYPE olle$tvptest

CREATE TYPE olle$tvptest AS TABLE (a int  NULL,
                                   b date NULL,
                                   c int  NULL,
                                   d int  IDENTITY)

CREATE TABLE #target (a int  NULL,
                      b date NULL,
                      c int NULL)
SQLEND
   $X->sql(<<'SQLEND');
CREATE PROCEDURE #tvptest @t olle$tvptest READONLY AS
   INSERT #target (a, b, c) SELECT a, b, c FROM @t
SQLEND
}

# The first test is for what happens # with a legacy provider.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = '$X->sql_sp("#tvptest", [[[1, "1989-01-01", 1]]])';
if ($X->{Provider} <= Win32::SqlServer::PROVIDER_SQLNCLI) {
   $expect_print =
      ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
       '=~ /need SQL( Server)? 2008.*Native Client 10/',
       '=~ /1> EXEC #tvptest \@t = \@t/',
       '=~ /Message from Win32::SqlServer at/'];
   $expect_msgs = [{State    => '== 1',
                    Errno    => '== -1',
                    Severity => '== 16',
                    Line     => '== 0',
                    Source   => 'eq "Win32::SqlServer"',
                    Text     => '=~ /need SQL( Server)? 2008.*Native Client 10/'}];
}
else {
   $expect_print = [];
   $expect_msgs = undef;
}
do_test($sql_call, 202, 0, $expect_print, $expect_msgs, 10);

# Also with paramsql.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = '$X->sql("SELECT * FROM ?", [["table", [[1, "1989-01-01", 1]], "olle\$tvptest"]])';
if ($X->{Provider} <= Win32::SqlServer::PROVIDER_SQLNCLI) {
   $expect_print =
      ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
       '=~ /need SQL( Server)? 2008.*Native Client 10/',
       '=~ /1> +EXEC sp_executesql/',
      q!=~ /2> +N\'\@P1 +olle/!,
       '=~ /3> +\@P1 *= *\@P1/',
       '=~ /Message from Win32::SqlServer at/'];
   $expect_msgs = [{State    => '== 1',
                    Errno    => '== -1',
                    Severity => '== 16',
                    Line     => '== 0',
                    Source   => 'eq "Win32::SqlServer"',
                    Text     => '=~ /need SQL( Server)? 2008.*Native Client 10/'}];
}
else {
   $expect_print = [];
   $expect_msgs = undef;
}
do_test($sql_call, 205, 0, $expect_print, $expect_msgs, 10);

# Now for the real tests with errors with the table type.
delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = '$X->sql("SELECT * FROM ?", [["table", [[1, "1989-01-01", 1]]]])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /No actual user type .+ table .+ '\@P1'/!,
    '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /No actual user type .+ table .+ '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 208, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = '$X->sql("SELECT * FROM ?", [["table(nosuchtype)", [[1, "1989-01-01", 1]]]])';
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Unable to find.*table type 'nosuchtype'/!,
    '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Unable to find.*table type 'nosuchtype'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 211, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql("SELECT * FROM ?", [['table(olle$tvptest)', 12]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /value '12'.*table parameter '\@P1'/!,
     '=~ /1> +EXEC sp_executesql/',
    q!=~ /2> +N\'\@P1 +olle/!,
     '=~ /3> +\@P1 *= *\@P1/',
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /value '12'.*table parameter '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 214, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql_sp('#tvptest', [12]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /value '12'.*table parameter '\@t'/!,
     '=~ /1> +EXEC #tvptest/',
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /value '12'.*table parameter '\@t'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 217, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql("SELECT * FROM ?", [['table(olle$tvptest)', [1, '1989-01-01', 1]]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /value '1' for row.*table parameter '\@P1'/!,
     '=~ /1> +EXEC sp_executesql/',
    q!=~ /2> +N\'\@P1 +olle/!,
     '=~ /3> +\@P1 *= *\@P1/',
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /value '1' for row.*table parameter '\@P1'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 220, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql_sp('#tvptest', [[1, '1989-01-01', 1]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /value '1' for row.*table parameter '\@t'/!,
     '=~ /1> +EXEC #tvptest/',
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /value '1' for row.*table parameter '\@t'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 223, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);


delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql_sp('#tvptest', [{'a' => 1, 'b' => '1989-01-01', 'c' => 23}]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Illegal value 'HASH\(.*'.*table parameter '\@t'/!,
     '=~ /1> +EXEC #tvptest /',
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Illegal value 'HASH\(.*'.*table parameter '\@t'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 226, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql_sp('#tvptest', [[{'a' => 1, 'b' => '1989-01-01', 'c' => 23},
                           {'a' => 1, 'b' => '1989-01-01', 'e' => 23},
                           [1, '1989-01-01', 1, 1, 9]]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /Warning: input hash.*includes key 'e'.*no such column/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /Warning: input array.*5 elements.*only 4 columns/!,
    '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Warning: input hash.*includes key 'e'.*no such column/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Warning: input array.*5 elements.*only 4 columns/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 229, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql_sp('#tvptest', [[{'a' => 1, 'b' => '1989-13-01', 'c' => 23},
                           {'a' => 1, 'b' => '1989-01-01', 'd' => 23},
                           [1, '1989-01-32', 1]]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /Part 'Month'.*illegal value 13/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /convert.*value '1989-13-01'.*type date.*column '\[b\]'/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /Warning: input hash.*includes key 'd'.*usedefault=1.*ignored/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /Part 'Day'.*illegal value 32/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 10/',
    q!=~ /convert.*value '1989-01-32'.*type date.*column '\[b\]'/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
     "=~ /One or more parameters .+ Cannot execute/",
    q!=~ /1> +DECLARE \@t tempdb.\[dbo\].\[olle\$tvptest\]/!,
    q!=~ /2> +INSERT +\@t *\(\[a\], *\[b\], *\[c\]\) +VALUES/!,
    q!=~ /3> +\(1, *'1989-13-01', *23\ *\),/!,
    q!=~ /4> +\(1, *'1989-01-01', *NULL\ *\),/!,
    q!=~ /5> +\(1, *'1989-01-32', *1 *\)/!,
    q!=~ /6> +EXEC #tvptest +\@t *= *\@t/!,
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Part 'Month'.*illegal value 13/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /convert.*value '1989-13-01'.*type date.*column '\[b\]'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Warning: input hash.*includes key 'd'.*usedefault=1.*ignored/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /Part 'Day'.*illegal value 32/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 10',
                 Text     => q!=~ /convert.*value '1989-01-32'.*type date.*column '\[b\]'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => "=~ /One or more parameters .+ Cannot execute/",
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 232, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);

delete $X->{ErrInfo}{Messages};
$X->{ErrInfo}{SaveMessages} = 1;
$X->{ErrInfo}{MaxSeverity} = 17;
$sql_call = <<'PERLEND';
  $X->sql("SELECT * FROM ?",
         [['table(tempdb.dbo.olle$tvptest)',
           [[1, '1989-01-01', 1]]]]);
PERLEND
$expect_print =
    ['=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Type name 'tempdb\.dbo\.olle\$tvptest'.*database.*ad-hoc/!,
     '=~ /Message from Win32::SqlServer at/',
     '=~ /^Message -1.+Win32::SqlServer.+Severity:? 16/',
    q!=~ /Unable to find.*table type 'tempdb\.dbo\.olle\$tvptest'/!,
     '=~ /Message from Win32::SqlServer at/'];
$expect_msgs = [{State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Type name 'tempdb\.dbo\.olle\$tvptest'.*database.*ad-hoc/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"},
                {State    => '>= 1',
                 Errno    => '<= -1',
                 Severity => '== 16',
                 Text     => q!=~ /Unable to find.*table type 'tempdb\.dbo\.olle\$tvptest'/!,
                 Line     => "== 0",
                 Source   => "eq 'Win32::SqlServer'"}];
do_test($sql_call, 235, 0, $expect_print, $expect_msgs, 10, PROVIDER_SQLNCLI10);


# That's enough!
exit;


sub do_test{
   my($test, $test_no, $expect_die, $expect_print, $expect_msgs,
      $minsqlversion, $minprovider) = @_;

   my($savestderr, $errfile, $fh, $evalout, @carpmsgs);

   # If the test only runs on a certain version of SQL Server or provider, skip.
   if (defined $minsqlversion and $sqlver < $minsqlversion or
       defined $minprovider and $X->{Provider} < $minprovider) {
      print "ok " . $test_no++ . " # skip\n";
      print "ok " . $test_no++ . " # skip\n";
      print "ok " . $test_no++ . " # skip\n";
      return;
   }

   # Get file name.
   $errfile = "error.$test_no";

   # To start with, we alter between writing to STDERR and using a ErrFileHandle.
   # Later we give up on ErrFileHandle, to know where the Perl warnings will
   # appear.
   if ($test_no % 2 == 0 or $test_no > 21) {
      delete $X->{errInfo}{errFileHandle};

      # Save STDERR so we can reopen.
      $savestderr = FileHandle->new_from_fd(*main::STDERR, "w") or die "Can't dup STDERR: $!\n";

      # Redirect STDERR to a file.
      open(STDERR, ">$errfile") or die "Can't redriect STDERR to '$errfile': $!\n";
      STDERR->autoflush;

      # Run the test. Must eval, it may die.
      eval($test);
      $evalout = $@;

      # Put STDERR back to were it was.
      open(STDERR, ">&" . $savestderr->fileno) or (print "Can't reopen STDERR: $!\n" and die);
      STDERR->autoflush;
   }
   else {
      # Test errFileHandle
      $fh = new FileHandle;
      $fh->open($errfile, "w") or die "Can't write to '$errfile': $!\n";
      $X->{errInfo}{errFileHandle} = $fh;

      # Must set up a handler to catch warnings.
      local $SIG{__WARN__} = sub{push(@carpmsgs, $_[0])};

      # Run the test. Must eval, it may die.
      eval($test);
      $evalout = $@;

      $fh->close;
   }

   # Now, read the error file.
   $fh = new FileHandle;
   $fh->open($errfile, "r") or die "Cannot read $errfile: $!\n";
   my @errfile = <$fh>;
   $fh->close;

   # Add the warnings to the error file (they are already there if we did use
   # the ErrFileHandle.
   push(@errfile, @carpmsgs);

   # Did the execution terminate by croak? And should it have?
   if ($expect_die) {
      if ($evalout and $evalout =~ /^Terminating.*fatal/i) {
         print "ok $test_no\n"
      }
      else {
         print "# evalout = '$evalout'\n" if defined $evalout;
         print "not ok $test_no\n";
      }
   }
   else {
      if (not $evalout) {
         print "ok $test_no\n"
      }
      else {
         print "# evalout = '$evalout'\n";
         print "not ok $test_no\n";
      }
   }
   $test_no++;

   # Compare output.
   if (compare(\@errfile, $expect_print)) {
      print "ok $test_no\n"
   }
   else {
      print "not ok $test_no\n";
   }
   $test_no++;

   # Then the messages.
   if (compare($X->{errInfo}{'messages'}, $expect_msgs)) {
      print "ok $test_no\n"
   }
   else {
      print "not ok $test_no\n";
   }
   $test_no++;
}



sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         $result = eval("q!$x! $y");
         warn "no match: <$x> <$y>" if not $result;
         return $result;
      }
      else {
         $result = (not defined $x and not defined $y);
         warn  'Left is ' . (defined $x ? "'$x'" : 'undefined') .
               ' and right is ' . (defined $y ? "'$y'" : 'undefined')
               if not $result;
         return $result
      }
   }
   elsif ($refx ne $refy) {
       warn "Left is '$refx' reference. Right is '$refy' reference";
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         warn  "Left has upper index $#$x and right has upper index $#$y.";
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      my $nokeys_x = scalar(keys %$x);
      my $nokeys_y = scalar(keys %$y);
      if ($nokeys_x == $nokeys_y and $nokeys_x == 0) {
         return 1;
      }
      if ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key} and defined $$x{$key}) {
                warn "Left has key '$key' which is missing from right.";
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
      }
      return 0 if not $result;
      foreach $key (keys %$y) {
         if (not exists $$x{$key} and defined $$y{$key}) {
             warn "Right has key '$key' which is missing from left.";
             return 0;
         }
      }
      return $result;
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      $result = ($x eq $y);
      warn "no match: <$x> <$y>" if not $result;
      return $result;
   }
}
