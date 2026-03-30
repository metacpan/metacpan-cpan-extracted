######################################################################
# 9030-distribution.t  Distribution integrity.
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_skip('MANIFEST not found') unless -f "$ROOT/MANIFEST";

plan_tests(count_A($ROOT) + count_B($ROOT) + count_F()
         + count_H()      + count_I()      + count_J($ROOT));

check_A($ROOT);
check_B($ROOT);
check_F($ROOT);
check_H($ROOT);
check_I($ROOT);
check_J($ROOT);

END { end_testing() }
