use strict; 
use warnings;
use Test::More;
use obogaf::parser;

use_ok('obogaf::parser');
my @subroutines= qw( build_edges build_subonto make_stat gene2biofun map_OBOterm_between_release);
foreach my $subroutine (@subroutines) { can_ok('obogaf::parser', $subroutine); }

done_testing();

