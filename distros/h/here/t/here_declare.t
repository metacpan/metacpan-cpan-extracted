use warnings;
use strict;

use Test::More tests => 69;

{my ($i, $msg) = qw(0 test);
sub t {
    return ($msg, $i) = (@_, 0) if @_;
    $msg.' '.++$i
}}

use here::declare;

use const qw($ONE 1 $TWO 2);

t 'const';
eval 'is $ONE, 1, t';
eval 'is $TWO, 2, t';
ok !eval '$TWO = 3', t;
like $@, qr/read.?only/i, t;

use const qw(foo abc bar xyz);

eval 'is $foo, "abc", t';
eval 'is $bar, "xyz", t';
ok !eval '$foo = 3', t;
like $@, qr/read.?only/i, t;

use my [qw(a b c d e)] => [1 .. 5];

t 'my [] => []';
{my $i;
for (qw(a b c d e)) {
    is eval "\$$_", ++$i, t;
    ok !eval "\$main::$_", t;
}}

use our [qw(A B C D E)] => [1 .. 5];

t 'our [] => []';
{my $i;
for (qw(A B C D E)) {
    is eval "\$$_",     ++$i, t;
    is eval "\$main::$_", $i, t;
}}

use my 'bare' => 1, '$sigil' => 2, '@array' => [3 .. 5], '%hash'  => {6 => 7};

t 'my $ @ %';
is eval '$bare', 1, t;
is eval '$sigil', 2, t;
is eval '"@array"', '3 4 5', t;
is eval 'join ", " => %hash', '6, 7', t;

t 'scalar => ref';
use my code => sub {'codecode'};

is eval '$code->()', 'codecode', t;

use our '$arrayref' => [2 .. 4];

is eval '"@$arrayref"', '2 3 4', t;

use const2 ABC => 123;

t 'const2';
is eval 'ABC', 123, t;
is eval 'ABC()', 123, t;
is eval '&ABC', 123, t;
is eval '$ABC', 123, t;
ok !eval '$ABC = 1', t;
like $@, qr/read.?only/i, t;
is eval '$ABC', 123, t;


{
    use my '$x = 2';
    use my '($y, $z) = (3, 4)';
    t 'simple assign';
    is eval '$x', 2, t;
    is eval '$y', 3, t;
    is eval '$z', 4, t;
}

{
    use my [qw($x $y $z)] => 1, 2, 3;
    use my [qw($foo @bar %baz)] => ['FOO', [qw(B A R)], {b => 'az'}];

    t '[] => list';
    is eval '"$x $y $z"', '1 2 3', t;
    is eval '$foo', 'FOO', t;
    is eval '"@bar"', 'B A R', t;
    is eval '$baz{b}', 'az', t;
}

{
    use my '($x, $y, $z)' => 11, 22, 33;

    use my '($foo, @bar, %baz)' => 'FOO1', [qw(B1 A1 R1)], {b => 'az1'};

    t "'()' => list";
    is eval '"$x $y $z"', '11 22 33', t;
    is eval '$foo', 'FOO1', t;
    is eval '"@bar"', 'B1 A1 R1', t;
    is eval '$baz{b}', 'az1', t;
}


no here::declare;

BEGIN {
    t 'no here::declare'; {
        for (qw (my our const const2)) {
            ok !$INC{"$_.pm"}, t;
            no strict 'refs';
            ok !$_->can('import'), t
        }
    }
}

t 'use again'; {
    use here::declare;
    use my qw(x 222);
    is eval '$x', 222, t;
}

SKIP:{
    unless ('B::Hooks::EndOfScope'->can('on_scope_end')) {
        my $msg = 'B::Hooks::EndOfScope required to test scope end';
        diag $msg;
        skip $msg, 8;
    }

    t 'end of scope'; {
        for (qw (my our const const2)) {
            ok !$INC{"$_.pm"}, t;
            no strict 'refs';
            ok !$_->can('import'), t
        }
    }
}
