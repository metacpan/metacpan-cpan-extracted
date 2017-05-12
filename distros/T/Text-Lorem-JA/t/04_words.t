use strict;
use warnings;
use utf8;
use Test::More;
use Text::Lorem::JA;

my $dict = <<'END_DICT';
1

ABC
DEF
GHI
.

0=1
1=2
2=3
3=4,1
4=-1
END_DICT

my $lorem = Text::Lorem::JA->new( dictionary => \$dict, lazy => 0 );

is $lorem->words(1), "ABC";
is $lorem->words(2), "ABCDEF";
is $lorem->words(3), "ABCDEFGHI";
is $lorem->words(4), "ABCDEFGHIABC";
is $lorem->words(6), "ABCDEFGHIABCDEFGHI";
is $lorem->words(8), "ABCDEFGHIABCDEFGHIABCDEF";

done_testing;

