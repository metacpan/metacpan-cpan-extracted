#!/usr/local/bin/perl

#	@(#)dbcc.pl	1.1	12/30/97
#

use Sybase::CTlib;
require 'getopts.pl';
require 'ctutil.pl';

# options: -d database -P sa_password -S server -m mail-to
&Getopts('d:S:P:m:');

$opt_m = 'sybase' unless($opt_m); # send mail to 'sybase' if no other specified


$dbh = new Sybase::CTlib 'sa', $opt_P, $opt_S;

ct_callback(CS_SERVERMSG_CB, \&msg_hdl); 

die "$0: -d database_name not specified!\n" if(!defined($opt_d));
$db = $opt_d;
$logfile = "/var/tmp/$db.dbcc";
$tmpfile = "/tmp/dbcc$$";

open(LOG, ">$logfile") || die "Can't open log file $logfile: $!\n";
open(TMP, ">$tmpfile") || die "Can't open file $tmpfile: $!\n";

&dolog("dbcc.pl for $db started at ", scalar(localtime), "\n");
&dolog("***** checkdb($db) *****\n");
&dbexec("dbcc checkdb('$db')\n");
&dolog("***** checkalloc($db) *****\n");
&dbexec("dbcc checkalloc('$db')\n");
&dolog("***** checkcatalog($db) *****\n");
&dbexec("dbcc checkcatalog('$db')\n");
&dolog("dbcc.pl for $db done at ", scalar(localtime), "\n");

close(LOG);
close(TMP);

system("/usr/ucb/Mail -s 'DBCC $db' $opt_m <$tmpfile");


sub dbexec {
    my($cmd) = @_;
    my(@dat, $ret);

    $dbh->ct_execute($cmd);
    $dbh->ct_results($ret);
#    $dbh->ct_cmd_realloc;
    while($dbh->ct_results($ret) == CS_SUCCEED) {
	next unless $dbh->ct_fetchable($ret);
	while(@dat = $dbh->ct_fetch) {
	    print "@dat\n";
	}
    }
}

sub dolog {
    my(@strings) =@_;

    print LOG @strings;
    print TMP @strings;
}

sub msg_hdl
{
    my($cmd, $number, $severity, $state, $line, $server, $proc, $text)
	= @_;

    if ($severity > 10)
    {
	print TMP ("Sybase message ", $number, ", Severity ", $severity,
	       ", state ", $state);
	print TMP ("\nServer `", $server, "'") if defined ($server);
	print TMP ("\n    ", $text, "\n\n");
    }
    elsif ($number == 0)
    {
	print STDERR ($text, "\n");
    }
    
    printf LOG ("%4d %d %d $text", $number, $state, $severity)
	if($number != 0);
    
    &CS_SUCCEED;
}
