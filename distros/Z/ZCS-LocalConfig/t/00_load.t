
use strict;
use warnings;
use Test::More tests => 1;

my $pkg;

BEGIN {
    $pkg = "ZCS::LocalConfig";
    use_ok($pkg) or exit;
}

diag( "Testing $pkg ", $pkg->VERSION );
