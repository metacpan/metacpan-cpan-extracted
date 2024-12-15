use Test2::V0;

use lib './t/lib';

subtest 'Test `import_into` method' => sub {
    subtest 'Customize the import method to your taste' => sub {
        use mykura Foo => { a => 1, b => 2 };

        isa_ok Foo, 'MyConstraint';

        is Foo->{a}, 1;
        is Foo->{b}, 2;

        eval 'use mykura Bar => 1';
        like $@, qr/^Invalid mykura arguments/;
    }
};

done_testing;
