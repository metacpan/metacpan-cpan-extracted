use strict;
use warnings;

use Test::More;

eval "use Pod::Coverage";
plan skip_all => "need Pod::Coverage to check that pod is complete." if $@;

plan( tests => 1 );

my $pc = Pod::Coverage->new( package => 'Test::Numeric' );

my $coverage = $pc->coverage;
ok $coverage == 1
  || diag "Your need to write docs for: " . join ', ', sort $pc->uncovered;

