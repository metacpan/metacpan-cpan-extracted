use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use Test::Moose::More::Utils;
use TAP::SimpleOutput 0.009 'counters';

{ package TestRole;  use Moose::Role; }
{ package TestClass; use Moose;       }

use Moose::Util::MetaRole;
use List::Util 1.45 'uniq';

my @class_metaclass_types = qw{
    class
    attribute
    method
    wrapped_method
    instance
    constructor
    destructor
};
    # error ?!

my @role_metaclass_types = qw{
    role
    attribute
    method
    required_method
    wrapped_method
    conflicting_method
    application_to_class
    application_to_role
    application_to_instance
    applied_attribute
};
    # application_role_summation ?!

my %metaroles =
    map { $_ => Moose::Meta::Role->create("MetaRole::nope::$_" => ()) }
    uniq sort @class_metaclass_types, @role_metaclass_types, 'nope'
    ;

my %metaclass_types = (
    class => [ @class_metaclass_types ],
    role  => [ @role_metaclass_types  ],
);

Moose::Util::MetaRole::apply_metaroles for => $_,
    class_metaroles => {
        map { $_ => [ "MetaRole::nope::$_" ] } @class_metaclass_types
    },
    role_metaroles => {
        map { $_ => [ "MetaRole::nope::$_" ] } @role_metaclass_types
    }
    for qw{ TestClass TestRole }
    ;

my %metaclasses;
for my $type (keys %metaclass_types) {
    my $thing = 'Test' . ucfirst $type;
    $metaclasses{$type} = {
        map { $_ => get_mop_metaclass_for($_ => $thing->meta) }
        @{ $metaclass_types{$type} }
    };
}

# We don't know what names these anonymous classes will be graced with -- they
# are anonymous, after all, and we're creating a bunch of them.  _msg() is a
# helper function to make building the output lines a bit less painful.

sub _msg { qq{Test${_[0]}'s $_[1] metaclass } . $metaclasses{lc $_[0]}->{$_[1]} . qq{ does not do MetaRole::} . ($_[2] || $_[1]) }

note explain \%metaclasses;

# NOTE end prep, begin actual tests

subtest 'TestClass via does_not_metaroles_ok' => sub {
    does_not_metaroles_ok TestClass => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    };
};

subtest 'TestRole via does_not_metaroles_ok' => sub {
    does_not_metaroles_ok TestRole => {
        map { $_ => [ "MetaRole::$_" ] } @role_metaclass_types
    };
};

# NOTE begin Test::Builder::Tester tests

{
    # check the output of the two subtests above.  (Just more compactly)
    for my $thing_type (qw{ class role }) {
        my ($_ok, $_nok) = counters;
        my $thing = 'Test' . ucfirst $thing_type;

        test_out $_ok->(_msg ucfirst $thing_type => $_)
            for sort @{ $metaclass_types{$thing_type} };

        does_not_metaroles_ok $thing => {
            map { $_ => [ "MetaRole::$_" ] } @{ $metaclass_types{$thing_type} }
        };

        test_test "$thing all OK";
    }
}

{
    # checking for unapplied trait

    for my $thing_type (qw{ Class Role }) {
        my ($_ok, $_nok) = counters;
        my $thing        = "Test$thing_type";

        test_out $_nok->(_msg $thing_type => 'attribute', 'nope::attribute');
        test_fail 1;
        does_not_metaroles_ok $thing => { attribute => ['MetaRole::nope::attribute'] };
        test_test "test for unapplied metarole ($thing)";
    }
}

done_testing;
