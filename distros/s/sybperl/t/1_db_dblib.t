#!./perl
# $Id: 1_db_dblib.t,v 1.2 2004/04/13 20:03:05 mpeppler Exp $
#
# from
#	@(#)dblib.t	1.20	11/23/98

print "1..22\n";

use Sybase::DBlib qw(2.04);

use lib 't';
use _test;

$Version = $SybperlVer;
$Version = $Sybase::DBlib::Version;
$Sybase::DBlib::Att{UseDateTime} = TRUE;

print "Sybperl Version $Version\n";

dbmsghandle ("message_handler"); # Some user defined error handlers
dberrhandle ("error_handler");

use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

( $X = Sybase::DBlib->dblogin($Uid, $Pwd, $Srv) )
    and print("ok 1\n")
    or die "not ok 1
-- The supplied login id/password combination may be invalid\n";

( $X->dbuse('master') == &SUCCEED )
    and print("ok 2\n")
    or die "not ok 2\n";

($X->dbcmd("select count(*) from systypes") == &SUCCEED)
    and print("ok 3\n")
    or die "not ok 3\n";
($X->dbsqlexec == &SUCCEED)
    and print("ok 4\n")
    or die "not ok 4\n";
($X->dbresults == &SUCCEED)
    and print("ok 5\n")
    or die "not ok 5\n";
($count) = $X->dbnextrow;
($X->{DBstatus} == &REG_ROW)
    and print "ok 6\n"
    or die "not ok 6\n";
$X->dbnextrow;
($X->{DBstatus} == &NO_MORE_ROWS)
    and print "ok 7\n"
    or die "not ok 7\n";
($X->dbresults == &NO_MORE_RESULTS)
    and print("ok 8\n")
    or die "not ok 8\n";

($X->dbcmd("select * from systypes") == &SUCCEED)
    and print("ok 9\n")
    or die "not ok 9\n";
($X->dbsqlexec == &SUCCEED)
    and print("ok 10\n")
    or die "not ok 10\n";
($X->dbresults == &SUCCEED)
    and print("ok 11\n")
    or die "not ok 11\n";
$err = 0;
while(@row = $X->dbnextrow)
{
    $rows++;
    ++$err if($X->{DBstatus} != &REG_ROW);
}
($err == 0)
    and print("ok 12\n")
    or die "not ok 12\n";
($count == $rows)
    and print "ok 13\n"
    or die "not ok 13\n";

# Now we make a syntax error, to test the callbacks:

dbmsghandle (\&msg_handler); # different handler to check callbacks

($X->dbcmd("select * from systypes\nwhere") == &SUCCEED)
    and print("ok 14\n")
    or die "not ok 14\n";
($X->dbsqlexec == &FAIL)
    and print("ok 16\n")
    or die "not ok 16\n";

dbmsghandle ("message_handler"); # Some user defined error handlers

$date1 = $X->newdate('Jan 1 1995');
$date2 = $X->newdate('Jan 3 1995');

($date1 < $date2)
    and print "ok 17\n"
    or print "not ok 17\n";
($days, $msecs) = $date1->diff($date2);
($days == 2 && $msecs == 0)
    and print "ok 18\n"
    or print "not ok 18\n";
$ref = $X->sql("select getdate()");
(ref(${$$ref[0]}[0]) eq 'Sybase::DBlib::DateTime')
    and print "ok 19\n"
    or print "not ok 19\n";

$X->dbcmd("select * from master..sysprocesses");
$X->dbsqlsend;
my $count = 0;
my ($x, $reason);

do {
    ($x, $reason) = Sybase::DBlib->dbpoll(-1);
    ++$count;
    print "dbpoll: reason = $reason\n";
} while($count < 20 && $reason != DBRESULT);

exit if $reason != DBRESULT;

(ref($x) eq 'Sybase::DBlib') 
    and print "ok 20\n"
    or print "not ok 20\n";

($reason == DBRESULT)
    and print "ok 21\n"
    or print "not ok 21\n";
    
($x->dbsqlok == SUCCEED)
    and print "ok 22\n"
    or print "not ok 22\n";

while($x->dbresults != NO_MORE_RESULTS) {
    while(@dat = $x->dbnextrow) {
	foreach (@dat) {
	    $_ = '' unless $_;
	}
	print "@dat\n";
    }
}
					 

sub message_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
	= @_;

    if ($severity > 0)
    {
	print STDERR ("Sybase message ", $message, ", Severity ", $severity,
	       ", state ", $state);
	print STDERR ("\nServer `", $server, "'") if defined ($server);
	print STDERR ("\nProcedure `", $procedure, "'") if defined ($procedure);
	print STDERR ("\nLine ", $line) if defined ($line);
	print STDERR ("\n    ", $text, "\n\n");

# &dbstrcpy returns the command buffer.

	if(defined($db))
	{
	    my ($lineno, $cmdbuff) = (1, undef);

	    $cmdbuff = &Sybase::DBlib::dbstrcpy($db);
	       
	    foreach $row (split (/\n/, $cmdbuff))
	    {
		print STDERR (sprintf ("%5d", $lineno ++), "> ", $row, "\n");
	    }
	}
    }
    elsif ($message == 0)
    {
	print STDERR ($text, "\n");
    }
    
    0;
}

sub error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg)
	= @_;
    # Check the error code to see if we should report this.
    if ($error != SYBESMSG) {
	print STDERR ("Sybase error: ", $error_msg, "\n");
	print STDERR ("OS Error: ", $os_error_msg, "\n") if defined ($os_error_msg);
    }

    INT_CANCEL;
}

sub msg_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
	= @_;

    if ($severity > 0)
    {
	($message == 102 || $message == 170) # MS-SQL server returns 170...
	    and print("ok 15\n")
		or print("not ok 15\n");
    }
    0;
}



