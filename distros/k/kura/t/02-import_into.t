use Test2::V0;

use lib './t/lib';
use MyConstraint;

subtest 'Test `import_into` method' => sub {
    subtest 'Customize the import method to your taste' => sub {
        use mykura Foo => MyConstraint->new;

        # MyKura customize the name of the constraint
        isa_ok MyFoo, 'MyConstraint';
    }
};

done_testing;
