use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);
use lib "$Bin";

use TestTypeTiny qw(Foo Bar Baz);

subtest 'Test `kura` with Type::Tiny' => sub {
    for my $type (Foo, Bar, Baz) {
        ok !$type->check('');
        ok $type->check('dog');
    }

    is Foo, object {
        prop blessed => 'Type::Tiny';
        call name => '__ANON__';
    };

    is Bar, object {
        prop blessed => 'Type::Tiny';
        call name => 'Bar';
    };

    is Baz, object {
        prop blessed => 'Type::Tiny';
        call name => 'Baz';
    };

    is +Baz->validate(''), 'too short', 'Bar has a message';
};

done_testing;
