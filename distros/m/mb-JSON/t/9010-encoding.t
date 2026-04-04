######################################################################
# 9010-encoding.t  Encoding hygiene: US-ASCII, no trailing whitespace,
#                  files end with newline.
# Supersedes: t/0003-usascii.t + the C checks in t/0005-cpan_precheck.t
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
plan_tests(count_C($ROOT));
check_C($ROOT);
END { end_testing() }
