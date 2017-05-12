#!./perl
# $Id: 2_ct_cursor.t,v 1.3 2004/04/13 20:03:05 mpeppler Exp $
#
# From
#	@(#)cursor.t	1.5	05/20/97

######################### We start with some black magic to print on failure.


BEGIN {print "1..22\n";}
END {print "not ok 1\n" unless $loaded;}
use Sybase::CTlib;
$loaded = 1;
print "ok 1\n";

require 'ctutil.pl';

######################### End of black magic.

use lib 't';
use _test;

use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

($d = new Sybase::CTlib $Uid, $Pwd, $Srv)
    and print "ok 2\n"
    or die "not ok 2
-- The user id/password combination may be invalid.\n";

# Cursors are not avialable on 4.x servers:
@version = $d->ct_sql("select \@\@version");
@in = split(/\//, ${$version[0]}[0]);
($ver, @in) = split(/\./, $in[1], 2);
if($ver < 10.0) {
    my $i;
    print STDERR "Cursors are not available on this SQL Server.\n";
    for($i = 3; $i <= 22; ++$i){
	print "ok $i\n";
    }
    exit(0);
}

($d2 = $d->ct_cmd_alloc)
    and print "ok 3\n"
    or print "not ok 3\n";

($d->ct_cursor(CS_CURSOR_DECLARE, 'first_cursor',
	       'select * from master.dbo.sysprocesses',
	       CS_READ_ONLY) == CS_SUCCEED)
    and print "ok 4\n"
    or print "not ok 4\n";
($d->ct_cursor(CS_CURSOR_ROWS, undef, undef, 5) == CS_SUCCEED)
    and print "ok 5\n"
    or print "not ok 5\n";
($d->ct_send == CS_SUCCEED)
    and print "ok 6\n"
    or print "not ok 6\n";

$restype = 0;
while($d->ct_results($restype) == CS_SUCCEED) {}
($d2->ct_cursor(CS_CURSOR_DECLARE, "second_cursor",
		'select * from sysusers',
		CS_READ_ONLY) == CS_SUCCEED)
    and print "ok 7\n"
    or print "not ok 7\n";
($d2->ct_cursor(CS_CURSOR_ROWS, undef, undef, 2) == CS_SUCCEED)
    and print "ok 8\n"
    or print "not ok 8\n";
($d2->ct_send == CS_SUCCEED)
    and print "ok 9\n"
    or print "not ok 9\n";
while($d2->ct_results($restype) == CS_SUCCEED) {}

($d->ct_cursor(CS_CURSOR_OPEN, undef, undef, CS_UNUSED) == CS_SUCCEED)
    and print "ok 10\n"
    or print "not ok 10\n";
($d->ct_send == CS_SUCCEED)
    and print "ok 11\n"
    or print "not ok 11\n";
($d->ct_results($restype) == CS_SUCCEED)
    and print "ok 12\n"
    or print "not ok 12\n";
($restype == CS_CURSOR_RESULT)
    and print "ok 13\n"
    or print "not ok 13\n";

($d2->ct_cursor(CS_CURSOR_OPEN, undef, undef, CS_UNUSED) == CS_SUCCEED)
    and print "ok 14\n"
    or print "not ok 14\n";
($d2->ct_send == CS_SUCCEED)
    and print "ok 15\n"
    or print "not ok 15\n";
($d2->ct_results($restype) == CS_SUCCEED)
    and print "ok 16\n"
    or print "not ok 16\n";
($restype == CS_CURSOR_RESULT)
    and print "ok 17\n"
    or print "not ok 17\n";

$last = 1;
while(@dat = $d->ct_fetch()) {
    if($last) {
	if(!(@dat2 = $d2->ct_fetch())) {
	    $last = 0;
	}
	print "$dat[0] - $dat2[0]\n" if $last;
    }
}
if($last) {
    while(@dat2 = $d2->ct_fetch()) {
	print "$dat2[0]\n";
    }
}
print "ok 18\n";

while($d->ct_results($restype)==CS_SUCCEED){ print "1\n";}
while($d2->ct_results($restype)==CS_SUCCEED){ print "2\n";}

($d->ct_cursor(CS_CURSOR_CLOSE, undef, undef, CS_DEALLOC) == CS_SUCCEED)
    and print "ok 19\n"
    or print "not ok 19\n";
($d->ct_send == CS_SUCCEED)
    and print "ok 20\n"
    or print "not ok 20\n";
while($d->ct_results($restype) == CS_SUCCEED) {}

($d2->ct_cursor(CS_CURSOR_CLOSE, undef, undef, CS_DEALLOC) == CS_SUCCEED)
    and print "ok 21\n"
    or print "not ok 21\n";
($d2->ct_send == CS_SUCCEED)
    and print "ok 22\n"
    or print "not ok 22\n";
while($d2->ct_results($restype) == CS_SUCCEED) {}
