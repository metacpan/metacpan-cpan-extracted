use strict;
use warnings;
use Test::Harness;
use Test::More;

my ($result, $files) = Test::Harness::execute_tests( tests => ["t/basic.pl"] );

is($result->{ok}, 10);
is($result->{bad}, 1);

is( $files->{'t/basic.pl'}->{canon}, '1-2 12-13 15' );
is( $files->{'t/basic.pl'}->{failed}, '5' );

done_testing;