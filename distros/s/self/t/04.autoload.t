use lib 't/lib';
use AutoloadTest;
use Test2::V0;
plan tests => 1;

{
    my $o = AutoloadTest->new;
    $o->zzzffff(1);
    is($o->out, "zzzffff");
}

