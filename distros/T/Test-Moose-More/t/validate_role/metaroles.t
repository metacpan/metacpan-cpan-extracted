use strict;
use warnings;

{ package MetaRole::attribute; use Moose::Role; }
{ package MetaRole::nope;      use Moose::Role; }
{ package TestRole;            use Moose::Role; }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.007 'counters';

use Moose::Util::MetaRole;

Moose::Util::MetaRole::apply_metaroles for => 'TestRole',
    role_metaroles  => { attribute => [ 'MetaRole::attribute' ] },
    ;

subtest 'Sanity, simple run' => sub {
    validate_role TestRole => (
        role_metaroles    => { attribute => [ 'MetaRole::attribute' ] },
        no_role_metaroles => { attribute => [ 'MetaRole::nope'      ] },
    );
};

{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{TestRole has a metaclass});
    test_out $_ok->(q{TestRole is a Moose role});
    test_out $_ok->(q{TestRole's attribute metaclass Moose::Meta::Class::__ANON__::SERIAL::1 does MetaRole::attribute});
    test_out $_ok->(q{TestRole's attribute metaclass Moose::Meta::Class::__ANON__::SERIAL::1 does not do MetaRole::nope});
    validate_role 'TestRole' => (
        role_metaroles    => { attribute => [ 'MetaRole::attribute' ] },
        no_role_metaroles => { attribute => [ 'MetaRole::nope'      ] },
    );
    test_test '{,no_}role_metaroles option honored';

}


done_testing;
