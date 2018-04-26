#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Yahoo::Weather::Api;

BEGIN {
    use_ok( 'Yahoo::Weather::Api' ) || print "Unable to load module!\n";
}
diag( "Testing Yahoo::Weather::Api $Yahoo::Weather::Api::VERSION, Perl $], $^X" );

my $api = Yahoo::Weather::Api->new();

is($api->VERSION,'1.10','Version test');

done_testing();