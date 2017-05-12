use strict;
use warnings;

{ package MetaRole::attribute; use Moose::Role; }
{ package MetaRole::nope;      use Moose::Role; }
{ package TestClass;           use Moose;       }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters';

use Moose::Util::MetaRole;

Moose::Util::MetaRole::apply_metaroles for => 'TestClass',
    class_metaroles => { attribute => [ 'MetaRole::attribute' ] };

subtest 'Sanity, simple run' => sub {
    validate_class 'TestClass' => (
        class_metaroles    => { attribute => [ 'MetaRole::attribute' ] },
        no_class_metaroles => { attribute => [ 'MetaRole::nope'      ] },
    );
};

{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{TestClass has a metaclass});
    test_out $_ok->(q{TestClass is a Moose class});
    test_out $_ok->(q{TestClass's attribute metaclass Moose::Meta::Class::__ANON__::SERIAL::1 does MetaRole::attribute});
    test_out $_ok->(q{TestClass's attribute metaclass Moose::Meta::Class::__ANON__::SERIAL::1 does not do MetaRole::nope});
    validate_class 'TestClass' => (
        class_metaroles    => { attribute => [ 'MetaRole::attribute' ] },
        no_class_metaroles => { attribute => [ 'MetaRole::nope'      ] },
    );
    test_test '{,no_}class_metaroles option honored';

}


done_testing;
