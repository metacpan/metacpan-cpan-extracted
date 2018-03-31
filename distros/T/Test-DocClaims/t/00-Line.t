#!perl

use strict;
use warnings;
use lib "lib";
use Test::More tests => 12;

BEGIN { use_ok('Test::DocClaims::Line'); }
can_ok('Test::DocClaims::Line', 'new');

my $line;
eval {
    $line = Test::DocClaims::Line->new(
        file => { path => "foo.pm", has_pod => 1 },
        text => "foo();",
        lnum => 1,
    );
};
is($@, "", "does not die") or diag $@;
isa_ok($line, "Test::DocClaims::Line");
is($line->path, "foo.pm");
ok($line->has_pod);
is($line->text, "foo();");
is($line->lnum, 1);
ok(!$line->is_doc);

eval {
    $line = Test::DocClaims::Line->new(
        text => "foo();",
        lnum => 1,
    );
};
like($@, qr/missing file key/, "must die") or diag $@;

eval {
    $line = Test::DocClaims::Line->new(
        file => { path => "foo.pm", has_pod => 1 },
        lnum => 1,
    );
};
like($@, qr/missing text key/, "must die") or diag $@;

eval {
    $line = Test::DocClaims::Line->new(
        file => { path => "foo.pm", has_pod => 1 },
        text => "foo();",
    );
};
like($@, qr/missing lnum key/, "must die") or diag $@;

