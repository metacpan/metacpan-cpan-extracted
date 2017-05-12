#!./perl
# $Id: 3_bcp.t,v 1.3 2005/03/20 19:50:59 mpeppler Exp $
#
# From:
#	@(#)bcp.t	1.2	03/22/96

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..9\n";}
END {print "not ok 1\n" unless $loaded;}
use Sybase::BCP;
$loaded = 1;
print "ok 1\n";

require 'sybutil.pl';

######################### End of black magic.

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

($X = new Sybase::BCP $Uid, $Pwd, $Srv)
    and print "ok 2\n"
    or print "not ok 2
-- The supplied login id/password combination may be invalid\n";

$X->sql("select \@\@version", sub { $version = $_[0]; });
$version =~ s|[^/]+/([\d.]+)[^/]+/.*|$1|;
print "$version\n";
if($version gt '11.9') {
    $lock = "lock allpages";
} else {
    $lock = '';
}

($X->sql("if object_id('$Db..bcp') != NULL drop table $Db..bcp"));
($X->sql("create table $Db..bcp(f1 char(5), f2 int, f3 text) $lock"))
    and print "ok 3\n"
    or print "not ok 3\n";
($X->config(INPUT => 't/bcp.dat',
	    OUTPUT => "$Db..bcp",
	    REORDER => {1 => 'f2',
			2 => 'f3',
			3 => 'f1'}))
    and print "ok 4\n"
    or print "not ok 4\n";
($X->run)
    and print "ok 5\n"
    or print "not ok 5\n";

(@rows = $X->sql("select * from $Db..bcp"))
    and print "ok 6\n"
    or print "not ok 6\n";
(scalar(@rows) == 4)
    and print "ok 7\n"
    or print "not ok 7\n";
(${$rows[3]}[1] == 12)
    and print "ok 8\n"
    or print "not ok 8 (${$rows[3]}[1]\n";
(${$rows[2]}[2] =~ /\r/)
    and print "ok 9\n"
    or print "not ok 9 (${$rows[2]}[2]\n";

($X->sql("if object_id('$Db..bcp') != NULL drop table $Db..bcp"));
