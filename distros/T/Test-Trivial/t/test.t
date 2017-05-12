#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 26;

my @a=(1,2,3);
OK @a;
OK @a == 3;
TODO OK @a == 4;
IS @a, 3;
TODO IS "abc", "def";
TODO IS 4, 5;
IS [4], [4];
IS [{a=>1}], [{a=>1}];
TODO IS [{a=>1, b=>2}], [{a=>1}];
EQ 4, 4;
TODO EQ 4 => 5;
TODO EQ [4] => [4];
TODO ID [4] => [4];
my $ref = [4];
ID $ref => $ref;
ISNT 5, 6 or die;
IS substr("abcdef",0,3), "abc";
LIKE "acb", qr/^a/;
TODO UNLIKE "abc", qr/^a/;

TODO IS <<GOT, <<EXPECTED;
this
is
a
line
GOT
this
is
not
a
line
EXPECTED

TODO IS [<<GOT], [<<EXPECTED];
this
is
a
line
GOT
this
is
not
a
line
EXPECTED

TODO IS undef() => <<EOM;
this 
is
a
line
EOM

IS 1 =>
    1;

IS 1
    => 
       1;

IS 1
       
,

1;
    

IS  "abc123"
    =>
    "abc123";

IS  "def"
    =>
     "def"
