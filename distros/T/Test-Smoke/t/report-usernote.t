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
        user_note   => 'Blah',
        un_position => Test::Smoke::Reporter::USERNOTE_ON_TOP,
    );
    isa_ok($r, 'Test::Smoke::Reporter');
    $r->{_rpt} = { secs => 42, avg => 21, patchlevel => 987 };

    my $preamble = $r->preamble();
    like(
        $preamble,
        qr/^Blah\n\n/,
        "  user_note on top of preamble"
    );
}

{
    no warnings 'redefine';
    local *Test::Smoke::Reporter::read_parse = sub { return $_[0] };
    my $r = Test::Smoke::Reporter->new(
        ddir        => 't',
        user_note   => 'Blah',
        un_position => 'not' . Test::Smoke::Reporter::USERNOTE_ON_TOP,
    );
    isa_ok($r, 'Test::Smoke::Reporter');

    my $signature = $r->signature();

    like(
        $signature,
        qr/^\nBlah\n\n/,
        "  user_note on top of signature"
    );
}

done_testing();
