use strict;
use warnings;
use utf8;
use Test::More;
use Text::Lorem::JA;

my $dict = <<'END_DICT';
1

A
B
C

0=1
1=2
2=3
3=-1
END_DICT

my $lorem = Text::Lorem::JA->new( dictionary => \$dict, lazy => 0 );

is $lorem->sentences(1), "ABC";
is $lorem->sentences(2), "ABCABC";
is $lorem->sentences(3), "ABCABCABC";

done_testing;

