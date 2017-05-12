use Test::More tests => 1;
use lib "t";
use lib ".";

my $r = eval 'use authority "cpan:ISABELINK", "Local::TestModule", qw(); 1' || 0;
ok(!$r, "Failed to use module with incorrect authority.");
