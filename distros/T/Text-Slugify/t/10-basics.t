#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

use Text::Slugify qw(slugify);
use utf8;

my @tests = (
    ''    => '',

    ' '   => '-',
    '  '  => '-',
    '- '  => '-',
    ' -'  => '-',
    ' - ' => '-',

    '-'   => '-',
    '--'  => '-',
    '---' => '-',

    'abc'    => 'abc',
    '123'    => '123',
    'abc123' => 'abc123',

    ' abc'  => 'abc',
    'abc '  => 'abc',
    ' abc ' => 'abc',

    '  abc  ' => 'abc',

    'abc 123'   => 'abc-123',
    'abc  123'  => 'abc-123',
    'abc   123' => 'abc-123',

    ' abc   123'  => 'abc-123',
    'abc   123 '  => 'abc-123',
    ' abc   123 ' => 'abc-123',

    'abc-123'   => 'abc-123',
    'abc--123'  => 'abc-123',
    'abc---123' => 'abc-123',

    '-abc-123'  => 'abc-123',
    'abc-123-'  => 'abc-123',
    '-abc-123-' => 'abc-123',

    '---abc---123'    => 'abc-123',
    'abc---123---'    => 'abc-123',
    '---abc---123---' => 'abc-123',

    '@@@' => '-',
    '@#$' => '-',
    '@#$ !@^*%' => '-',
);


if(eval "require Text::Unaccent::PurePerl") {
    push @tests => (
        'abc-ö-123' => 'abc-o-123',
        'å-123'      => 'a-123',
    );
}
else {
    push @tests => (
        'abc-ö-123' => 'abc-123',
        'å-123'      => '123',
    );
}


while (defined (my $s = shift @tests)) {
    my $d = shift @tests;
    is(slugify($s), $d, "$s -> $d");
}

done_testing;
