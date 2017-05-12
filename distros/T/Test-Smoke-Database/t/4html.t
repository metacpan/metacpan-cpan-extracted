use Test::More;
use Test::Smoke::Database;

use strict;
plan tests => 4;

my $n = new Test::Smoke::Database({ no_dbconnect => 1});
my $h = $n->HTML->header_html;
ok($h, "Call of header_html return something");

my ($r1,$r2,$r3)=$n->HTML->display;
ok(defined($r1) && ref($r1), 
	"Test::Smoke::Database->display return reference");
ok(defined($r2) && ref($r2), 
	"Test::Smoke::Database->display return reference");
ok(defined($r3) && ref($r3), 
	"Test::Smoke::Database->display return reference");