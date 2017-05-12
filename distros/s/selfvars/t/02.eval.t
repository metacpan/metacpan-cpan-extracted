use lib 't/lib';
use EvalTest;
use Test::More tests => 8;

{
    my $o = EvalTest->new;
    $o->in(1);
    is($o->out, 1);
}

for (2 .. 8) {
    my $o = EvalTest->new;
    my $m = "out$_";
    $o->in($_);
    is(eval "\$o->$m", $_);
}
