use Test2::V0;

use lib './t/lib';
use MyConstraint;

subtest 'Test `kura` features' => sub {
    subtest '`kura` import constraint into caller' => sub {
        use kura X => MyConstraint->new;
        isa_ok X, 'MyConstraint';
    };

    subtest '`kura` with constarint and other function.' => sub {
        use MyFoo qw(Foo hello);
        isa_ok Foo, 'MyConstraint';
        is hello(), 'Hello, Foo!';
    };
};

subtest 'Test `kura` exceptions' => sub {
    subtest 'Constraint already defined' => sub {
        eval "use kura Foo => MyConstraint->new";
        like $@, qr/^'Foo' is already defined/;
    };

    subtest 'Not given name' => sub {
        eval "use kura";
        like $@, qr/^name is required/;
    };

    subtest 'Forbidden name' => sub {
        eval "use kura BEGIN => MyConstraint->new";
        like $@, qr/^'BEGIN' is forbidden/;
    };

    subtest 'Not given constraint' => sub {
        eval "use kura Foo";
        like $@, qr/^constraint is required/;
    };

    subtest 'Invalid constraint' => sub {
        eval "use kura Bar => 1";
        like $@, qr/^Invalid constraint/;
    };

    subtest 'Invalid orders' => sub {
        eval "
            use kura B => A;
            use kura A => MyConstraint->new;
        ";
        like $@, qr/^Bareword "A" not allowed/;
    };
};

done_testing;
