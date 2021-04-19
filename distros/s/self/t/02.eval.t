use lib 't/lib';
use EvalTest;
use Test2::V0;
plan tests => 8;


{
    my $o = EvalTest->new;
    $o->in(1);
    is($o->out, 1);
}

for (2..8) {
    my $o = EvalTest->new;
    my $m = "out$_";
    $o->in($_);
    is($o->$m, $_);
}
