use Test2::V0;

use lib './t/lib';
use MyConstraint;

subtest 'Test `kura` features' => sub {
    subtest '`kura` import constraint into caller' => sub {
        use kura X => MyConstraint->new;
        isa_ok X, 'MyConstraint';
    };

    subtest '`kura` with constraint and other function.' => sub {
        use MyFoo qw(Foo hello);
        isa_ok Foo, 'MyConstraint';
        is hello(), 'Hello, Foo!';
    };

    subtest '`kura` with tags' => sub {
        use MyBar qw(:types);
        isa_ok Bar1, 'MyConstraint';
        isa_ok Bar2, 'MyConstraint';
        isa_ok Bar3, 'MyConstraint';
        is \@MyBar::KURA, [qw(Bar1 Bar2 Bar3)], 'types defined by kura are stored in $PACKAGE::KURA';
        is \@MyBar::EXPORT_OK, [qw(Bar1 Bar2 Bar3 bar_hello)];
    };

    subtest '`kura` with private constraint' => sub {
        use MyFoo qw(call_private_foo);
        ok lives { call_private_foo() }; # _PrivateFoo is called at `call_private_foo`

        eval 'use MyFoo qw(_PrivateFoo)';
        like $@, qr/^"_PrivateFoo" is not exported by the MyFoo module/;
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

        eval "use kura Bar => (bless {}, 'SomeObject')";
        like $@, qr/^Invalid constraint. Object must have a `check` method or allowed constraint class: SomeObject/;
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
