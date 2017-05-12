use strict;
use warnings;

{ package MetaRole::attribute; use Moose::Role; }
{ package MetaRole::nope;      use Moose::Role; }
{ package TestClass;           use Moose;       }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.008 ':subtest';

use Moose::Util::MetaRole;

Moose::Util::MetaRole::apply_metaroles for => 'TestClass',
    class_metaroles => { attribute => [ 'MetaRole::attribute' ] };

subtest 'Sanity, simple run' => sub {
    validate_thing 'TestClass' => (
        metaclasses  => {
            class => {
                isa => [ 'Moose::Meta::Class' ],
            },
            attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );
};

{
    my $tap = counters;
    my ($_ok, $_nok) = @$tap{qw{ ok nok }};

    Test::Builder::Tester::_start_testing(); # FIXME damnit.
    test_out subtest_header $tap, 'Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1'
        if subtest_header_needed;
    do {
        my $tap = counters(1);
        my ($_ok, $_nok) = @$tap{qw{ ok nok }};
        test_out $_ok->(q{TestClass's attribute metaclass has a metaclass});
        test_out $_ok->(q{TestClass's attribute metaclass is a Moose class});
        test_out $_ok->(q{TestClass's attribute metaclass isa Moose::Meta::Attribute});
        test_out $_ok->(q{TestClass's attribute metaclass does MetaRole::attribute});
        test_out $tap->{plan}->();
    };
    test_out $_ok->('Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1');
    test_out subtest_header $tap, 'Checking the class metaclass, Moose::Meta::Class'
        if subtest_header_needed;
    do {
        my $tap = counters(1);
        my ($_ok, $_nok) = @$tap{qw{ ok nok }};
        test_out $_ok->(q{TestClass's class metaclass has a metaclass});
        test_out $_ok->(q{TestClass's class metaclass is a Moose class});
        test_out $_ok->(q{TestClass's class metaclass isa Moose::Meta::Class});
        test_out $tap->{plan}->();
    };
    test_out $_ok->('Checking the class metaclass, Moose::Meta::Class');

    validate_thing 'TestClass' => (
        metaclasses  => {
            class => {
                isa => [ 'Moose::Meta::Class' ],
            },
            attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );

    test_test 'metaclasses option honored';
}


done_testing;
