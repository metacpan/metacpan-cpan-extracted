use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Plugin::DBBreak;

ok(0, "This will fail");

ok(0);

ok(
    0 != 0
);

is(
    {a => 1},
    {a => 2},
    "foo",
);

# Oooh, tricky :-) logical line number is 21: "hash test", I am amazed PPI knows that!
is(
    {a => 1},
    hash {
        field a => 2;
        end;
    },
    "hash test",
);

ok(
    (!grep {
        !!$_
        # Let us just throw in a really big ass comment here, what will happen to this garbage?
        # jgfhsdfjghsdjfghfsdjhgjdfhgjdhgjsdhfjshfjhsdjfhgjsdhgjhjfhgjsdhgjsdhgjdhgjdshgjdhsjgf
        # jgfhsdfjghsdjfghfsdjhgjdfhgjdhgjsdhfjshfjhsdjfhgjsdhgjhjfhgjsdhgjsdhgjdhgjdshgjdhsjgf
        # jgfhsdfjghsdjfghfsdjhgjdfhgjdhgjsdhfjshfjhsdjfhgjsdhgjhjfhgjsdhgjsdhgjdhgjdshgjdhsjgf
        # jgfhsdfjghsdjfghfsdjhgjdfhgjdhgjsdhfjshfjhsdjfhgjsdhgjhjfhgjsdhgjsdhgjdhgjdshgjdhsjgf
    } qw/a b c/),
    "Test::Expr chokes on this"
);

done_testing;
