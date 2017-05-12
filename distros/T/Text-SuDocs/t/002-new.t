#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Text::SuDocs');
}

my @success_argsets = (
    {},
    {agency => 'Y'},
    {agency => 'Y', subagency => 3},
    {agency => 'Y', subagency => 3, series => 186},
    {agency => 'Y', subagency => 3, series => 186, relatedseries => 2},
    {agency => 'Y', subagency => 3, series => 186, relatedseries => 2, document => 'asdf'},
    );
subtest 'Setting args during instantiation' => sub {
    map { isa_ok(Text::SuDocs->new($_), 'Text::SuDocs') } @success_argsets;
    done_testing();
};

my $s = Text::SuDocs->new();
$s->original('EP 1.23: 998');
is($s->agency, 'EP', 'setting original triggers parse()');
