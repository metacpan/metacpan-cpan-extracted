use strict;
use warnings;

use Moose::Util 'with_traits';

{ package TestClass; use Moose; sub foo { } }

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 0.009;

subtest 'validate w/valid class -- standalone run' => sub {

    validate_thing 'TestClass' => (
        methods    => [ 'foo' ],
        no_methods => [ 'bar' ],
    );
};

note 'validate w/valid class';
{
    my ($_ok, $_nok) = counters();
    test_out $_ok->("TestClass has method $_")
        for qw{ foo };
    test_out $_ok->("TestClass does not have method $_")
        for qw{ bar };
    validate_thing 'TestClass' => (
        methods    => [ 'foo' ],
        no_methods => [ 'bar' ],
    );
    test_test 'validate_thing works correctly for valid classes';
}

done_testing;
__END__
