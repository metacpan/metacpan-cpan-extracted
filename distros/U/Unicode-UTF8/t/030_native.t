#!perl

use strict;
use warnings;

use Test::More  tests => 3;
use Test::Fatal qw[lives_ok];

BEGIN {
    use_ok('Unicode::UTF8', qw[ encode_utf8 ]);
}

{   my $string = "bl\xE5b\xE4r \xE4r g\xF6tt!";
    my $octets = "blåbär är gött!";
    my $got    = '';
    lives_ok { 
        use warnings FATAL => 'utf8';
        $got = encode_utf8($string); 
    } 'encode_utf8() native string';
    is($got, $octets, 'encoded native string');
}

