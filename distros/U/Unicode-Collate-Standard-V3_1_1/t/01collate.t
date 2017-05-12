use strict;

use Test::More tests => 2;

use Unicode::Collate;
use Unicode::Collate::Standard::V3_1_1;


# See if we get something for the path to the table
isnt(V3_1_1_COLLATION, "", "check table path");

# Make a collator and make sure it picks up the allkeys
my $s1    = "GeneviÃve";
my $s2    = "geneviave";
my $level = 1;

# Cheat and change the load path to point to our version
$Unicode::Collate::Path = $INC{'Unicode/Collate/Standard/V3_1_1.pm'};
$Unicode::Collate::Path =~ s/\/Standard\/V3_1_1.pm$//;

my $col = Unicode::Collate->new
   (table => V3_1_1_COLLATION,
   level  => $level);

my $res = $col->cmp($s1, $s2);

is($res, 0, "Compare '$s1' $s2' ignoring case and accents");
