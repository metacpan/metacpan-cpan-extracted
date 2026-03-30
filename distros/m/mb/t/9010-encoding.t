######################################################################
# 9010-encoding.t  Encoding hygiene for distribution meta-files and
#                  9000-series test files (which must be US-ASCII).
#
# Note: lib/mb.pm and t/1xxx-8xxx are intentionally encoded in UTF-8
#       or other MBCS to test the mb module itself.  They are excluded
#       from this check.
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

my @manifest = _manifest_files($ROOT);

# Only check meta-files and 9xxx test files (US-ASCII required)
my @check_files = grep {
    /^(?:META\.yml|META\.json|Makefile\.PL|Changes|MANIFEST|
         LICENSE|CONTRIBUTING|SECURITY\.md|
         t\/9\d{3}-|t\/lib\/).*$/x
    && -f "$ROOT/$_"
} @manifest;

my $total = scalar(@check_files) * 3;  # C1 + C2 + C3
plan_skip('no files to check') unless $total;
plan_tests($total);

for my $rel (sort @check_files) {
    my $abs = "$ROOT/$rel";

    # C1: US-ASCII only (read raw bytes)
    my $raw = '';
    {
        local *FH;
        open FH, $abs or do { ok(0, "C1 - cannot open: $rel"); ok(0, "C2 - cannot open: $rel"); ok(0, "C3 - cannot open: $rel"); next };
        binmode FH;
        local $/;
        $raw = <FH>;
        close FH;
    }
    my @bytes = unpack('C*', $raw);
    ok((grep { $_ > 127 } @bytes) == 0, "C1 - US-ASCII only: $rel");

    # C2: no trailing whitespace
    {
        local *FH2;
        open FH2, $abs or do { ok(0, "C2 - cannot open: $rel"); ok(0, "C3 - cannot open: $rel"); next };
        my $bad_tw = 0;
        my $n = 0;
        while (<FH2>) {
            $n++;
            if (/[ \t]+\r?$/) {
                $bad_tw = $n;
                last;
            }
        }
        close FH2;
        ok(!$bad_tw, "C2 - no trailing whitespace: $rel"
            . ($bad_tw ? " (first at line $bad_tw)" : ''));
    }

    # C3: ends with newline
    ok(length($raw) == 0 || substr($raw, -1) eq "\n",
       "C3 - ends with newline: $rel");
}

END { end_testing() }
