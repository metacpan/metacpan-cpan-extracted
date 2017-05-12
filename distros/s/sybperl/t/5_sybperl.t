#!./perl

#	@(#)sybperl.t	1.13	06/27/97

print "1..28\n";

require 'sybperl.pl';

# This test file is still under construction...

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

# A couple of things to silence some warnings...
$dummy = $NO_MORE_ROWS;
$dummy = $NO_MORE_RESULTS;
$dummy = $dbNullIsUndef;
$Sybase::DBlib::Version = $Sybase::DBlib::Version;

( ($dbproc = &dblogin($Uid, $Pwd, $Srv)) != -1 )
    and print("ok 1\n")
    or die "not ok 1
-- You may need to edit t/sybperl.t to add login names and passwords\n";
#print "$dbproc\n";

( &dbuse($dbproc, 'master') == $SUCCEED )
    and print("ok 2\n")
    or print "not ok 2\n";

(&dbcmd($dbproc, "select count(*) from systypes") == $SUCCEED)
    and print("ok 3\n")
    or print "not ok 3\n";
(&dbsqlexec($dbproc) == $SUCCEED)
    and print("ok 4\n")
    or print "not ok 4\n";
(&dbresults($dbproc) == $SUCCEED)
    and print("ok 5\n")
    or print "not ok 5\n";
($count) = &dbnextrow($dbproc);
($DBstatus == $REG_ROW)
    and print "ok 6\n"
    or print "not ok 6\n";
&dbnextrow($dbproc);
($DBstatus == $NO_MORE_ROWS)
    and print "ok 7\n"
    or print "not ok 7\n";
(&dbresults($dbproc) == $NO_MORE_RESULTS)
    and print("ok 8\n")
    or print "not ok 8\n";

(&dbcmd($dbproc, "select * from systypes") == $SUCCEED)
    and print("ok 9\n")
    or print "not ok 9\n";
(&dbsqlexec($dbproc) == $SUCCEED)
    and print("ok 10\n")
    or print "not ok 10\n";
(&dbresults($dbproc) == $SUCCEED)
    and print("ok 11\n")
    or print "not ok 11\n";
$err = 0;
while(&dbnextrow($dbproc))
{
    $rows++;
    ++$err if($DBstatus != $REG_ROW);
}

($err == 0)
    and print("ok 12\n")
    or print "not ok 12\n";

($count == $rows)
    and print "ok 13\n"
    or print "not ok 13\n";

# Now we make a syntax error, to test the callbacks:

$old = &dbmsghandle ("msg_handler");
#print "$old\n";

(&dbcmd($dbproc, "select * from systypes\nwhere") == $SUCCEED)
    and print("ok 14\n")
    or print "not ok 14\n";
(&dbsqlexec($dbproc) == &FAIL)
    and print("ok 16\n")
    or print "not ok 16\n";

&dbmsghandle ($old);

# Test for the use of a default dbproc:

( ($dbproc2 = &dblogin($Uid, $Pwd, $Srv)) != -1 )
    and print("ok 17\n")
    or print "not ok 17";

( &dbuse($dbproc2, 'tempdb') == $SUCCEED )
    and print("ok 18\n")
    or print "not ok 18\n";

# use the default (first opened) dbproc)
(&dbcmd("select count(*) from systypes") == $SUCCEED)
    and print("ok 19\n")
    or print "not ok 19\n";
(&dbsqlexec() == $SUCCEED)
    and print("ok 20\n")
    or print "not ok 20\n";
(&dbresults() == $SUCCEED)
    and print("ok 21\n")
    or print "not ok 21\n";
($rows) = &dbnextrow();

($count == $rows)
    and print "ok 22\n"
    or print "not ok 22\n";

# Test to see if $dbNullIsUndef works as advertised
# Default is TRUE (ie Null -> undef)
(&dbcmd("select uid, printfmt from systypes where printfmt is null\n") == $SUCCEED)
    and print("ok 23\n")
    or print "not ok 23\n";
(&dbsqlexec() == $SUCCEED && &dbresults() == $SUCCEED)
    and print("ok 24\n")
    or print "not ok 24\n";
$err = 0;
while(($uid, $printfmt) = &dbnextrow())
{
    ++$err if (defined($printfmt));
}
($err == 0)
    and print("ok 25\n")
    or print "not ok 25\n";

$dbNullIsUndef = 0;
(&dbcmd("select uid, printfmt from systypes where printfmt is null\n") == $SUCCEED)
    and print("ok 26\n")
    or print "not ok 26\n";
(&dbsqlexec() == $SUCCEED && &dbresults() == $SUCCEED)
    and print("ok 27\n")
    or print "not ok 27\n";
$err = 0;
while(($uid, $printfmt) = &dbnextrow())
{
    ++$err if($printfmt !~ /NULL/);
}
($err == 0)
    and print("ok 28\n")
    or print "not ok 28\n";

&dbexit();

sub msg_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
	= @_;

    if ($severity > 0)
    {
	($message == 102 || $message == 170) # MS-SQL server returns 170
	    and print("ok 15\n")
		or print("not ok 15\n");
    }
    0;
}
