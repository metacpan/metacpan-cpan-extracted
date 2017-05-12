use lib 't/lib';
use AutoloadTest;
use Test::More tests => 1;

{
    my $o = AutoloadTest->new;
    $o->zzzffff(1);
    is($o->out, "zzzffff");
}

