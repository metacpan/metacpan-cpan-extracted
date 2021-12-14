use strict;
use warnings;

use Test::More q//;
use Test::Exception q//;

use FindBin qw/$Bin/;
use lib qq{$Bin/lib};
use Bar;

dies_ok { Bar->new( some => q{thing} ) } q{Test constructor fails when required fields not provided.};

local $@;
eval {
  my $bar = Bar->new( some => q{other thing} );
};
like $@, qr/Missing one or more required fields:/, q{Failure message for missing fields found as expected.}; 

done_testing;
