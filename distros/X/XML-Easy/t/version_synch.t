use warnings;
use strict;

use Test::More tests => 14;

BEGIN { require_ok "XML::Easy"; }
my $main_ver = $XML::Easy::VERSION;
ok defined($main_ver), "have main version number";

foreach my $submod (qw(Classify Content Element NodeBasics Syntax Text)) {
	my $mod = "XML::Easy::$submod";
	require_ok $mod;
	no strict "refs";
	is ${"${mod}::VERSION"}, $main_ver, "$mod version number matches";
}

1;
