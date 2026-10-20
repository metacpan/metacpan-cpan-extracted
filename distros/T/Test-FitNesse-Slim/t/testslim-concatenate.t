use strict;
use warnings;
use Test::More;

use lib 't/lib';

my $class = 'Fitnesse::Slim::Test::TestSlim';
require_ok('Fitnesse/Slim/Test/TestSlim.pm');
my $fixture = $class->new;
my $method = $fixture->can('concatenate_three_args');
ok($method, 'TestSlim exposes concatenateThreeArgs');
if ($method) {
    is(
        $fixture->concatenate_three_args('first', 'second', 'third'),
        'first second third',
        'concatenateThreeArgs separates its three values with spaces',
    );
}

done_testing;
