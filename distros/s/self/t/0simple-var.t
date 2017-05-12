
use lib 't/lib2';
use Counter;
use Test::More tests => 9;

{
    my $o = Counter->new;
    is($o->out, 0);
    $o->inc;

    is($o->out, 1);
    $o->set(5);

    is($o->out, 5);
}

{
    my $o = ChildofCounter->new;
    is($o->out, 0);
    $o->inc;

    is($o->out, 1);
    $o->set(5);

    is($o->out, 5);
}

{
    my $o = SecondCounter->new;
    is($o->out, 0);
    $o->inc;

    is($o->out, 1);
    $o->set(5);

    is($o->out, 5);
}
