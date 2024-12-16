use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);
use lib "$Bin";

use TestTypeTiny qw(NamedType NoNameType CodeRefType HashRefType);

subtest 'Test `kura` with Type::Tiny' => sub {
    for my $type (NamedType, NoNameType, CodeRefType HashRefType) {
        ok !$type->check('');
        ok $type->check('dog');
    }

    is NamedType, object {
        prop blessed      => 'Type::Tiny';
        call name         => 'NamedType';
        call display_name => 'NamedType';
    };

    is NoNameType, object {
        prop blessed      => 'Type::Tiny';
        call name         => 'NoNameType';
        call display_name => 'NoNameType';
    };

    is CodeRefType, object {
        prop blessed      => 'Type::Tiny';
        call name         => 'CodeRefType';
        call display_name => 'CodeRefType';
    };

    is HashRefType, object {
        prop blessed      => 'Type::Tiny';
        call name         => 'HashRefType';
        call display_name => 'HashRefType';
        call sub { $_[0]->validate('') }, 'too short';
    };
};

done_testing;
