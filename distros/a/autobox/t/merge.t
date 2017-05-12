#!/usr/bin/perl

use strict;
use warnings;
use vars qw($WANT $DESCR);

use Test::More tests => 28;

BEGIN {
    $DESCR = [
        'basic',
        'no dup',
        'horizontal merge',
        'vertical merge',
        'horizontal merge of outer scope in inner scope',
        'dup in inner scope',
        'horizontal merge of inner scope in inner scope',
        'vertical merge in inner scope',
        'vertical merge in outer scope again',
        'merge DEFAULT into inner scope and unmerge ARRAY',
        'merge DEFAULT into top-level scope',
        'dup in sub',
        'horizontal merge in sub',
        'vertical merge in sub',
        'new scope with "no autobox"',
        'dup in new scope with "no autobox"',
        'horizontal merge in new scope with "no autobox"',
        'vertical merge in new scope with "no autobox"',
        'arrayref: two classes',
        'arrayref: one dup class',
        'arrayref: one dup class and one new namespace',
        'arrayref: one dup namespace and one new class',
        'arrayref: one new class',
        'arrayref: one new namespace',
        'arrayref: two default classes',
        'arrayref: one dup default class',
        'arrayref: one dup default class and one new default namespace',
        'arrayref: one new default class'
    ];

    $WANT = [
        # 1 - basic (line 257)
        {
          'STRING' => [ qw(MyScalar1) ]
        },

        # 2 - no dup (line 258)
        {
          'STRING' => [ qw(MyScalar1) ]
        },

        # 3 - horizontal merge (line 259)
        {
          'STRING' => [ qw(MyScalar1 MyScalar2) ]
        },

        # 4 - vertical merge (line 260)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2) ]
        },

        # 5 - horizontal merge of outer scope in inner scope (line 263)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar3) ]
        },

        # 6 - dup in inner scope (line 264)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar3) ]
        },

        # 7 - horizontal merge of inner scope in inner scope (line 265)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar3 MyScalar4) ]
        },

        # 8 - vertical merge in inner scope (line 266)
        {
          'ARRAY' => [ qw(MyArray1 MyArray2) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar3 MyScalar4) ]
        },

        # 9 - vertical merge in outer scope again (line 269)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2) ]
        },

        # 10 - merge DEFAULT into inner scope and unmerge ARRAY (line 273)
        {
          'ARRAY' => [ qw(MyDefault1) ],
          'CODE' => [ qw(MyDefault1) ],
          'HASH' => [ qw(MyHash1 MyDefault1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault1) ]
        },

        # 11 - merge DEFAULT into top-level scope (line 277)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault2) ],
          'CODE' => [ qw(MyDefault2) ],
          'HASH' => [ qw(MyHash1 MyDefault2) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault2) ]
        },

        # 12 - dup in sub (line 278)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault2) ],
          'CODE' => [ qw(MyDefault2) ],
          'HASH' => [ qw(MyHash1 MyDefault2) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault2) ]
        },

        # 13 - horizontal merge in sub (line 279)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault2) ],
          'CODE' => [ qw(MyDefault2) ],
          'HASH' => [ qw(MyHash1 MyDefault2) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault2 MyScalar5) ]
        },

        # 14 - vertical merge in sub (line 280)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault2) ],
          'CODE' => [ qw(MyDefault2) ],
          'HASH' => [ qw(MyHash1 MyDefault2) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault2 MyScalar5) ],
          'UNDEF' => [ qw(MyUndef1) ]
        },

        # 15 - new scope with "no autobox" (line 285)
        {
          'STRING' => [ qw(MyScalar6) ]
        },

        # 16 - dup in new scope with "no autobox" (line 286)
        {
          'STRING' => [ qw(MyScalar6) ]
        },

        # 17 - horizontal merge in new scope with "no autobox" (line 287)
        {
          'STRING' => [ qw(MyScalar6 MyScalar7) ]
        },

        # 18 - vertical merge in new scope with "no autobox" (line 288)
        {
          'ARRAY' => [ qw(MyArray3) ],
          'STRING' => [ qw(MyScalar6 MyScalar7) ]
        },

        # 19 - arrayref: two classes (line 292)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9) ]
        },

        # 20 - arrayref: one dup class (line 293)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9) ]
        },

        # 21 - arrayref: one dup class and one new namespace (line 294)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9 MyScalar10::SCALAR) ]
        },

        # 22 - arrayref: one dup namespace and one new class (line 295)
        {
          'ARRAY' => [ qw(MyArray1) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9 MyScalar10::SCALAR MyScalar11) ]
        },

        # 23 - arrayref: one new class (line 296)
        {
          'ARRAY' => [ qw(MyArray1 MyArray4) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9 MyScalar10::SCALAR MyScalar11) ]
        },

        # 24 - arrayref: one new namespace (line 297)
        {
          'ARRAY' => [ qw(MyArray1 MyArray4 MyArray5::ARRAY) ],
          'HASH' => [ qw(MyHash1) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyScalar8 MyScalar9 MyScalar10::SCALAR MyScalar11) ]
        },

        # 25 - arrayref: two default classes (line 301)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault3 MyDefault4) ],
          'CODE' => [ qw(MyDefault3 MyDefault4) ],
          'HASH' => [ qw(MyHash1 MyDefault3 MyDefault4) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault3 MyDefault4) ]
        },

        # 26 - arrayref: one dup default class (line 302)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault3 MyDefault4) ],
          'CODE' => [ qw(MyDefault3 MyDefault4) ],
          'HASH' => [ qw(MyHash1 MyDefault3 MyDefault4) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault3 MyDefault4) ]
        },

        # 27 - arrayref: one dup default class and one new default namespace (line 303)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault3 MyDefault4 MyDefault5::ARRAY) ],
          'CODE' => [ qw(MyDefault3 MyDefault4 MyDefault5::CODE) ],
          'HASH' => [ qw(MyHash1 MyDefault3 MyDefault4 MyDefault5::HASH) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault3 MyDefault4 MyDefault5::SCALAR) ]
        },

        # 28 - arrayref: one new default class (line 304)
        {
          'ARRAY' => [ qw(MyArray1 MyDefault3 MyDefault4 MyDefault5::ARRAY MyDefault6) ],
          'CODE' => [ qw(MyDefault3 MyDefault4 MyDefault5::CODE MyDefault6) ],
          'HASH' => [ qw(MyHash1 MyDefault3 MyDefault4 MyDefault5::HASH MyDefault6) ],
          'STRING' => [ qw(MyScalar1 MyScalar2 MyDefault3 MyDefault4 MyDefault5::SCALAR MyDefault6) ]
        },
    ];
}

sub debug {
    my $hash = shift;
    my $descr = sprintf '%s (line %d)', shift(@$DESCR), (caller(2))[2];
    delete @{$hash}{qw(FLOAT INTEGER)}; # delete these to simplify the test

    # $| = 1;
    # my $counter = 0 if (0);
    # use Data::Dumper; $Data::Dumper::Terse = $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;
    # chomp (my $dump = Dumper($hash));
    # printf STDERR "%d - %s\n", ++$counter, $descr;
    # print STDERR "$dump,", $/, $/;

    is_deeply($hash, shift(@$WANT), $descr);
}

no autobox; # make sure a leading "no autobox" doesn't cause any underflow damage

{
    no autobox; # likewise a nested one
}

sub test1 {
    no autobox; # and one in a sub
}

use autobox SCALAR => 'MyScalar1', DEBUG => \&debug;
use autobox SCALAR => 'MyScalar1', DEBUG => \&debug;
use autobox SCALAR => 'MyScalar2', DEBUG => \&debug;
use autobox ARRAY  => 'MyArray1',  DEBUG => \&debug;

{
    use autobox SCALAR => 'MyScalar3', DEBUG => \&debug;
    use autobox SCALAR => 'MyScalar3', DEBUG => \&debug;
    use autobox SCALAR => 'MyScalar4', DEBUG => \&debug;
    use autobox ARRAY  => 'MyArray2',  DEBUG => \&debug;
}

use autobox HASH => 'MyHash1', DEBUG => \&debug;

sub sub2 {
    no autobox 'ARRAY';
    use autobox DEFAULT => 'MyDefault1', DEBUG => \&debug;
}

sub sub3 {
    use autobox DEFAULT => 'MyDefault2', DEBUG => \&debug;
    use autobox DEFAULT => 'MyDefault2', DEBUG => \&debug;
    use autobox SCALAR  => 'MyScalar5',  DEBUG => \&debug;
    use autobox UNDEF   => 'MyUndef1',   DEBUG => \&debug;
}

{
    no autobox;
    use autobox SCALAR => 'MyScalar6', DEBUG => \&debug;
    use autobox SCALAR => 'MyScalar6', DEBUG => \&debug;
    use autobox SCALAR => 'MyScalar7', DEBUG => \&debug;
    use autobox ARRAY  => 'MyArray3',  DEBUG => \&debug;
}

{
    use autobox SCALAR => [ 'MyScalar8', 'MyScalar9' ], DEBUG => \&debug;
    use autobox SCALAR => [ 'MyScalar8' ], DEBUG => \&debug;
    use autobox SCALAR => [ 'MyScalar8',    'MyScalar10::' ], DEBUG => \&debug;
    use autobox SCALAR => [ 'MyScalar10::', 'MyScalar11' ],   DEBUG => \&debug;
    use autobox ARRAY => [ 'MyArray4' ],   DEBUG => \&debug;
    use autobox ARRAY => [ 'MyArray5::' ], DEBUG => \&debug;
}

{
    use autobox DEFAULT => [ 'MyDefault3', 'MyDefault4' ], DEBUG => \&debug;
    use autobox DEFAULT => [ 'MyDefault3' ], DEBUG => \&debug;
    use autobox DEFAULT => [ 'MyDefault3', 'MyDefault5::' ], DEBUG => \&debug;
    use autobox DEFAULT => [ 'MyDefault6' ], DEBUG => \&debug;
}
