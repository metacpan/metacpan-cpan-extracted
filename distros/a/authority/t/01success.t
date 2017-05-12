use Test::More tests => 1;
use lib "t";
use lib ".";

BEGIN { use_ok(authority => 'cpan:TOBYINK', Local::TestModule => qw()); }
