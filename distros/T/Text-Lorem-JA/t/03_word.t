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

is $lorem->word(1), "A";
is $lorem->word(2), "AB";
is $lorem->word(3), "ABC";
is $lorem->word(5), "ABCDE";
is $lorem->word(11), "ABCDEFGHIAB";
is $lorem->word(13), "ABCDEFGHIABCD";

done_testing;

