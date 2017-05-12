#!/usr/local/bin/perl
#
#	@(#)bcp.pl	1.1	9/20/95

use Sybase::DBlib;

#require 'sybutil.pl';

&BCP_SETL(&Sybase::DBlib::TRUE);

$X = Sybase::DBlib->dblogin;
$X->dbuse('mp_test');
#$X->dbcmd("create table test_table(one char(10), two char(10))\n");
#$X->dbsqlexec;
#$X->dbresults;

$X->bcp_init("test_table", undef, "bcp.err", DB_IN);
$X->bcp_meminit(2);
open(FILE, "bcp.dat") || die "Can't open bcp.dat: $!\n";

while(<FILE>)
{
    chop;
    @dat = split(' ');

    print "@dat\n";
    
    die "bcp_sendrow failed!\n" if($X->bcp_sendrow(@dat) == FAIL);

    ++$count;

    if(($count % 10) == 0)
    {
	$ret = $X->bcp_batch;
	print "Sent $ret rows to the server\n";
    }
}

$ret = $X->bcp_done;
print "$ret rows returned by &bcp_done\n";
