use strict;
use warnings;

{ package MetaRole::attribute; use Moose::Role; }
{ package MetaRole::nope;      use Moose::Role; }
{ package TestRole;            use Moose::Role; }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.008 ':subtest';

use Moose::Util::MetaRole;

# So this is somewhat unfortunate, but it would appear that apply_metaroles()
# is not deterministic; that is, it doesn't sort the keys of role_metaroles
# before applying them.  Normally one probably couldn't care less, however
# here Test::Builder::Tester has very strict notions of what "1" and "2" are.
#
# 0:)
Moose::Util::MetaRole::apply_metaroles for => 'TestRole', role_metaroles => {
    $_ => [ 'MetaRole::attribute' ] } for qw{ attribute applied_attribute } ;

subtest 'Sanity, simple run' => sub {
    validate_role 'TestRole' => (
        role_metaclasses  => {
            role => {
                isa => [ 'Moose::Meta::Role' ],
            },
            applied_attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
            attribute => {
                isa  => [ 'Moose::Meta::Role::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );
};

{
    my $tap = counters;
    my ($_ok, $_nok) = @$tap{qw{ ok nok }};

    test_out $_ok->(q{TestRole has a metaclass});
    test_out $_ok->(q{TestRole is a Moose role});

    # FIXME either ::1 or ::2, depending on run

    test_out subtest_header $tap, 'Checking the applied_attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::2'
        if subtest_header_needed;
    do {
        my $tap = counters(1);
        my ($_ok, $_nok) = @$tap{qw{ ok nok }};
        test_out $_ok->(q{TestRole's applied_attribute metaclass has a metaclass});
        test_out $_ok->(q{TestRole's applied_attribute metaclass is a Moose class});
        test_out $_ok->(q{TestRole's applied_attribute metaclass isa Moose::Meta::Attribute});
        test_out $_ok->(q{TestRole's applied_attribute metaclass does MetaRole::attribute});
        test_out $tap->{plan}->();
    };
    test_out $_ok->('Checking the applied_attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::2');
    test_out subtest_header $tap, 'Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1'
        if subtest_header_needed;
    do {
        my $tap = counters(1);
        my ($_ok, $_nok) = @$tap{qw{ ok nok }};
        test_out $_ok->(q{TestRole's attribute metaclass has a metaclass});
        test_out $_ok->(q{TestRole's attribute metaclass is a Moose class});
        test_out $_ok->(q{TestRole's attribute metaclass isa Moose::Meta::Role::Attribute});
        test_out $_ok->(q{TestRole's attribute metaclass does MetaRole::attribute});
        test_out $tap->{plan}->();
    };
    test_out $_ok->('Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1');
    test_out subtest_header $tap, 'Checking the role metaclass, Moose::Meta::Role'
        if subtest_header_needed;
    do {
        my $tap = counters(1);
        my ($_ok, $_nok) = @$tap{qw{ ok nok }};
        test_out $_ok->(q{TestRole's role metaclass has a metaclass});
        test_out $_ok->(q{TestRole's role metaclass is a Moose class});
        test_out $_ok->(q{TestRole's role metaclass isa Moose::Meta::Role});
        test_out $tap->{plan}->();
    };
    test_out $_ok->('Checking the role metaclass, Moose::Meta::Role');

    validate_role 'TestRole' => (
        role_metaclasses  => {
            role => {
                isa => [ 'Moose::Meta::Role' ],
            },
            applied_attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
            attribute => {
                isa  => [ 'Moose::Meta::Role::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );

    test_test 'role_metaclasses option honored';
}


done_testing;
