#perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Tie::Sub');
}

my $test = Tie::Sub::Test->new({ test_key => 'test_value' });
tie my %test, 'Tie::Sub', sub {
    my ($method, $parameter) = @_;

    return $test->$method($parameter);
};
is(
    $test{ [ get => 'test_key' ] },
    'test_value',
    'method return value',
);

package Tie::Sub::Test;

sub new {
    my ($class, $param) = @_;

    return bless $param, $class;
}

sub get {
    return shift->{ shift() };
}
