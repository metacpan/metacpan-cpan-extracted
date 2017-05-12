#!perl
use strict;
use warnings qw(all);

use Carp qw(croak);
use Test::Simple tests => 7;

use Text::Roman qw/isroman roman2int int2roman ismilhar milhar2int/;
ok(1, 'use Text::Roman');

# test reciprocity

my $n = 3999;
my @r;
$r[$_] = int2roman($_) for 1 .. $n;
ok(1, "array created");
for (1 .. $n) {
    my $ar;
    croak "$_: $r[$_] != $ar" unless ($ar = roman2int($r[$_])) == $_;
}
ok(1, "reciprocity tested");

ok(isroman("IV"), "is roman");
ok(!isroman("IVI"), "is not roman");
ok(milhar2int("IV_VIII") == 4008, "milhar converted");

ok(1, "done");
