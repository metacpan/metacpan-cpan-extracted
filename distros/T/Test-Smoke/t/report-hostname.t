#! perl -w
use strict;

use Test::More;

use Test::Smoke::Reporter;

{
    no warnings 'redefine';
    local *Test::Smoke::Reporter::read_parse = sub { return $_[0] };
    local *Test::Smoke::Reporter::get_smoked_Config = sub {
        return (version => 1234)
    };
    local *Test::Smoke::Reporter::ccinfo = sub { return 'mycc version 42' };
    my $r = Test::Smoke::Reporter->new(
        ddir        => 't',
        hostname    => 'my.custom.hostname',
    );
    isa_ok($r, 'Test::Smoke::Reporter');
    $r->{_rpt} = { secs => 42, avg => 21, patchlevel => 987 };


    my $preamble = $r->preamble();

    like(
        $preamble,
        qr/^\Qmy.custom.hostname\E:/mx,
        "  custom hostname in preamble",
    );
}

done_testing();
