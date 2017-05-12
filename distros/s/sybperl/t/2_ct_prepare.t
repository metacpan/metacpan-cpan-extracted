# -*-Perl-*-
# $Id: 2_ct_prepare.t,v 1.2 2004/04/13 20:03:06 mpeppler Exp $
#
#
# Small test script for Sybase::CTlib dynamic SQL

BEGIN {print "1..15\n";}
END {print "not ok 1\n" unless $loaded;}
use Sybase::CTlib qw(2.13);
$loaded = 1;
print "ok 1\n";

$Version = $Sybase::CTlib::Version;

print "Sybperl Version $Version\n";

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

( $X = Sybase::CTlib->ct_connect($Uid, $Pwd, $Srv) )
    and print("ok 2\n")
    or print "not ok 2
-- The supplied login id/password combination may be invalid\n";


(($rc = $X->ct_execute(<<CREATE_TABLE)) == CS_SUCCEED)
    create table #ttt
	(
	    aaa int,
	    bbb float,
	    ccc char(3),
            ddd money,
            eee numeric(6,2)
	)
CREATE_TABLE
    and print "ok 3\n"
    or print "not ok 3\n";

$res_type = 0;
while(($rc = $X->ct_results($res_type)) == CS_SUCCEED)
{
    print "$res_type\n";
}

($X->ct_dyn_prepare(<<INSERT) == CS_SUCCEED)
	insert into #ttt values (?,?,?,?,?)
INSERT
    and print("ok 4\n")
    or print "not ok 4\n";

($X->ct_dyn_execute([1, 2.33, "testing", 23.4, 234.55]) == CS_SUCCEED)
    and print "ok 5\n"
    or print "not ok 5\n";
while($X->ct_results($restype) == CS_SUCCEED) {
    print "$restype\n";
}

($X->ct_dyn_execute([2, 2.55, "testing 2", 23.4, 234.556]) == CS_SUCCEED)
    and print "ok 6\n"
    or print "not ok 6\n";

while($X->ct_results($res_type) == CS_SUCCEED) {
    print "$res_type\n";
}

($X->ct_dyn_dealloc() == CS_SUCCEED)
    and print "ok 7\n"
    or print "not ok 7\n";

($X->ct_dyn_prepare(<<UPDATE) == CS_SUCCEED)
    update #ttt set bbb=?, ccc=? where aaa=?
UPDATE
    and print "ok 8\n"
    or print "not ok 8\n";


($X->ct_dyn_execute([567.89, "ABC", 1]) == CS_SUCCEED)
    and print("ok 9\n")
    or print "not ok 9\n";

while(($rc = $X->ct_results($res_type)) == CS_SUCCEED)
{
    print "$res_type\n";
}

($X->ct_dyn_execute([987.65, "XYZ", 2]) == CS_SUCCEED)
    and print("ok 10\n")
    or print "not ok 10\n";

while(($rc = $X->ct_results($res_type)) == CS_SUCCEED)
{
    print "$res_type\n";
}

($X->ct_execute("select * from #ttt") == CS_SUCCEED)
    and print("ok 11\n")
    or print "not ok 11\n";

$X->ct_results($res_type);
print "$res_type\n";

while(@dat = $X->ct_fetch) {
    foreach (@dat) {
	if(defined($_))	{
	    print "$_ ";
	} else {
	    print "NULL ";
	}
    }
    print "\n";
    if($dat[0] == 2) {
	$dat[2] eq "XYZ"
	    and print("ok 12\n")
		or print "not ok 12\n";
    }
}

($X->ct_results($res_type) == CS_SUCCEED)
    and print("ok 13\n")
    or print "not ok 13\n";
($res_type == CS_CMD_DONE)
    and print("ok 14\n")
    or print "not ok 14\n";
($X->ct_results($res_type) == CS_END_RESULTS)
    and print("ok 15\n")
    or print "not ok 15\n";
