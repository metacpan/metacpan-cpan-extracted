use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

{
    package TestRole;
    use Moose::Role;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_required  => (is => 'ro', required => 1);
    has no_required   => (is => 'ro', required => 0);
    has null_required => (is => 'ro');
}
{
    package TestClass;
    use Moose;
    use Moose::Deprecated -api_version => '1.07'; # don't complain
    use namespace::autoclean;

    has yes_required  => (is => 'ro', required => 1);
    has no_required   => (is => 'ro', required => 0);
    has null_required => (is => 'ro');
}

note 'finds requiredness correctly';
for my $thing (qw{ TestClass TestRole }) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'yes_required';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name is required");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name is not required");
    test_fail 7;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name is not required");
    test_fail 7;
    validate_attribute $thing => $name => (
        required => 1,
    );
    validate_attribute $thing => $name => (
        required => 0,
    );
    validate_attribute $thing => $name => (
        required => undef,
    );
    test_test "finds requiredness correctly in $thing";
}

note 'finds no requiredness correctly';
for my $thing (qw{ TestClass TestRole}) {
    my ($_ok, $_nok, $_skip) = counters();
    my $name = 'no_required';
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_nok->("${thing}'s attribute $name is required");
    test_fail 5;
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name is not required");
    test_out $_ok->("$thing has an attribute named $name");
    test_out $_ok->("${thing}'s attribute $name is not required");
    validate_attribute $thing => $name => (
        required => 1,
    );
    validate_attribute $thing => $name => (
        required => 0,
    );
    validate_attribute $thing => $name => (
        required => undef,
    );
    test_test "finds no requiredness correctly in $thing";
}

done_testing;
