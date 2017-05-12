no warnings;
use Test::Synopsis;
use Test::More tests => 2;

synopsis_ok("lib/Test/Synopsis.pm");
is $main::for_checked, 1;
