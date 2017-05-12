use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

use Moose::Util::TypeConstraints;
subtype 'AllCaps', as 'Str', where { !m/[a-z]/ }, message { 'String contains some lower-case chars' };
coerce 'AllCaps', from 'Str', via { tr/[a-z]/A-Z]/ };

{
    package TestRole;
    use Moose::Role;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_coerce  => (is => 'ro', isa => 'AllCaps', coerce => 1);
    has no_coerce   => (is => 'ro', isa => 'AllCaps', coerce => 0);
    has null_coerce => (is => 'ro', isa => 'AllCaps');
}
{
    package TestClass;
    use Moose;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_coerce  => (is => 'ro', isa => 'AllCaps', coerce => 1);
    has no_coerce   => (is => 'ro', isa => 'AllCaps', coerce => 0);
    has null_coerce => (is => 'ro', isa => 'AllCaps');
}

note 'finds coercion correctly';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'yes_coerce';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name should coerce");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name should not coerce");
    test_fail 7;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name should not coerce");
    test_fail 7;
    validate_attribute $thing => $name => (
        coerce => 1,
    );
    validate_attribute $thing => $name => (
        coerce => 0,
    );
    validate_attribute $thing => $name => (
        coerce => undef,
    );
    test_test "finds coercion correctly in $thing";
}

note 'finds no coercion correctly';
for my $thing (qw{ TestClass TestRole}) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'no_coerce';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name should coerce");
    test_fail 5;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name should not coerce");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name should not coerce");
    validate_attribute $thing => $name => (
        coerce => 1,
    );
    validate_attribute $thing => $name => (
        coerce => 0,
    );
    validate_attribute $thing => $name => (
        coerce => undef,
    );
    test_test "finds no coercion correctly in $thing";
}

done_testing;
