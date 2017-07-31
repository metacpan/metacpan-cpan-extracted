use warnings;
use strict;

use Test::More tests => 4;

BEGIN { require_ok "Time::UTC"; }
my $main_ver = $Time::UTC::VERSION;
ok defined($main_ver), "have main version number";

foreach my $submod (qw(Segment)) {
	my $mod = "Time::UTC::$submod";
	require_ok $mod;
	no strict "refs";
	is ${"${mod}::VERSION"}, $main_ver, "$mod version number matches";
}

1;
