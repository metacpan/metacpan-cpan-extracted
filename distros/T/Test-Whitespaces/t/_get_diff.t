#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More;

use Test::Whitespaces { _only_load => 1 };

pass("Loaded ok. Perl version $^V");

my @test_cases = (
    {
        got => "",
        expected => "\n",
        diff => "# line 1 No \\n on line\n",
    },
    {
        got => " \n",
        expected => "\n",
        diff => "# line 1: _\\n\n",
    },
    {
        got => "a\tb",
        expected => "a    b\n",
        diff => "# line 1: a\\tb\n",
    },
    {
        got => "a\nb \n",
        expected => "a\nb\n",
        diff => "# ...\n# line 2: b_\\n\n",
    },
    {
        got => "a\nb \nc\nd",
        expected => "a\nb\nc\nd\n",
        diff => "# ...\n# line 2: b_\\n\n# ...\n# line 4: d\n",
    },
    {
        got => "1234567890" x 10 . " \n",
        expected => "1234567890" x 10 . "\n",
        diff => "# line 1: ...90" . "1234567890" x 6 . "_\\n\n",
    },
    {
        got => "абвгдеёжзи" x 10 . " \n",
        expected => "абвгдеёжзи" x 10 . "\n",
        diff => "# line 1: ...зи" . "абвгдеёжзи" x 6 . "_\\n\n",
    },
);

foreach (@test_cases) {
    is(
        Test::Whitespaces::_get_fixed_text($_->{got}),
        $_->{expected},
        "_get_fixed_text()",
    );

    my $got = Test::Whitespaces::_get_diff($_->{got}, $_->{expected});

    is(
        $got,
        $_->{diff},
        "_get_diff()",
    );
}

done_testing();
