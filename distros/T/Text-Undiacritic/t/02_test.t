#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
#use Test::Exception;

use File::Basename;
use charnames ':full';
use utf8;

BEGIN {
    require lib;
    lib->import( grep { -d $_; } map { dirname(__FILE__) . "/$_"; }
        qw(lib ../lib ../blib/lib)
    );
}

use Text::Undiacritic qw(undiacritic);

plan ( tests => 12 );

use_ok('Text::Undiacritic');

ok( undiacritic('abc') eq 'abc', 'abc' );
ok( undiacritic('äöü') eq 'aou', 'äöü' );
ok( undiacritic("\N{LATIN SMALL LETTER O WITH DIAERESIS}") eq 'o', 'o with diaresis' );
ok( undiacritic("\N{LATIN SMALL LETTER O}\N{COMBINING DIAERESIS}") eq 'o', 'o and combining diaresis' );
ok( undiacritic("\N{COMBINING DIAERESIS}\N{LATIN SMALL LETTER O}") eq 'o', 'combining diaresis and o' );
ok( undiacritic("\N{LATIN SMALL LETTER L WITH STROKE}") eq 'l', 'latin small letter l with stroke' );

ok( undiacritic(1) eq 1, 'numeric 1' );
ok( undiacritic(' ') eq ' ', 'space' );
ok( !undiacritic(''), 'empty string' );
ok( !undiacritic(0), 'numeric 0' );
ok( !undiacritic(), 'without param' );
