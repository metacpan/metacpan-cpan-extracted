#!/pro/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
use Test::More tests => 31;
use Test::NoWarnings;

BEGIN {
    use_ok ("VCS::SCCS");
    }

like (VCS::SCCS->version (), qr{^\d+\.\d+$},	"Module version");

my $sccs;

my $testfile = "files/SCCS/s.tran.dta";

ok (1, "Parsing");
ok ($sccs = VCS::SCCS->new ($testfile), "Read and parse large SCCS file");

is (length ($sccs->body ()),		41,	"body ()      scalar");
is (length ($sccs->body (0)),		41,	"body (0)     scalar");
is (length ($sccs->body ("")),		41,	"body ('')    scalar");
is (length ($sccs->body (2)),		41,	"body (2)     scalar");
is (length ($sccs->body ("1.1")),	25,	"body ('1.1') scalar");

my @body;
ok (@body = $sccs->body (),			"body ()      list");
is (scalar @body,			2,	".. 2 lines");
ok (@body = $sccs->body ("1.1"),		"body ('1.1') list");
is (scalar @body,			1,	".. 1 line");

is ($sccs->translate (2, "%E%"), "%E%", "translate '' %E% 2");
is ($sccs->translate (2, "%U%"), "%U%", "translate '' %U% 2");
is ($sccs->translate (1, "%U%"), "%U%", "translate '' %U% 1");
is ($sccs->translate (1, "%U%R%E%"), "%U%R%E%", "translate '' %U%R%E% 1");

$sccs->set_translate ("****");
is ($sccs->translate (2, "%E%"), "%E%", "translate '****' %E% 2");
is ($sccs->translate (2, "%U%"), "%U%", "translate '****' %U% 2");
is ($sccs->translate (1, "%U%"), "%U%", "translate '****' %U% 1");
is ($sccs->translate (1, "%U%R%E%"), "%U%R%E%", "translate '****' %U%R%E% 1");

$sccs->set_translate ("SCCS");
is ($sccs->translate (2, "%E%"), "07/12/01", "translate SCCS %E% 2");
is ($sccs->translate (2, "%U%"), "02:02:02", "translate SCCS %U% 2");
is ($sccs->translate (1, "%U%"), "01:01:01", "translate SCCS %U% 1");
is ($sccs->translate (2, "%E%R%U%"),
			 "07/12/01R02:02:02", "translate SCCS %U%R%E% 2");
is (length ($sccs->body (2)),		59,	"body (2)     scalar");

$sccs->set_translate ("RCS");
#is ($sccs->translate (2, "%E%"), "%E%", "translate 'RCS' %E% 2");
#is ($sccs->translate (2, "%U%"), "%U%", "translate 'RCS' %U% 2");
#is ($sccs->translate (1, "%U%"), "%U%", "translate 'RCS' %U% 1");
#is ($sccs->translate (1, "%U%R%E%"), "%U%R%E%", "translate 'RCS' %U%R%E% 1");

my %tr = map { ( "%".$_."%" => "+$_+" ) } "E", "U", "W";
$sccs->set_translate (\%tr);
is ($sccs->translate (2, "%E%"), "+E+", "translate {} %E% 2");
is ($sccs->translate (2, "%U%"), "+U+", "translate {} %U% 2");
is ($sccs->translate (1, "%U%"), "+U+", "translate {} %U% 1");
is ($sccs->translate (1, "%U%R%E%"), "+U+R+E+", "translate {} %U%R%E% 1");
