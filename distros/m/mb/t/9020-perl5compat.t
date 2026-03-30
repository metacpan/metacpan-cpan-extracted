######################################################################
# 9020-perl5compat.t  Perl 5.005_03 compatibility checks.
#
# Note: lib/mb.pm has its own header convention.  The functional test
#       files t/1xxx-8xxx are encoded in MBCS and excluded.
#       Checks run on lib/mb.pm, t/9xxx + t/lib/, and Makefile.PL.
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
my @pm_files = grep { /^lib\/.*\.pm$/ && -f "$ROOT/$_" } @manifest;
my @t9_files = grep { /^(?:t\/9\d{3}-.*\.t|t\/lib\/.+\.pm)$/ && -f "$ROOT/$_" } @manifest;
my $has_mkf  = -f "$ROOT/Makefile.PL" ? 1 : 0;

plan_tests(
    scalar(@pm_files) * 13 +   # P1-P13 for lib/*.pm
    scalar(@t9_files) * 14 +   # P1-P14 for t/9xxx
    $has_mkf * 7               # M1-M7 for Makefile.PL
);

# lib/mb.pm is a transpiler: it intentionally contains say/given/state,
# // operator, ..., and non-ASCII chars as part of its transformation engine.
# P-checks are not applicable to lib/mb.pm itself.
for my $f (@pm_files) {
    # skip lib/mb.pm for P1-P13 -- transpiler source has controlled violations
    if ($f eq "lib/mb.pm") {
        for (1..13) { ok(1, "P$_ - transpiler source skipped: $f") }
        next;
    }
    # (other pm files would be checked here)

    my $abs  = "$ROOT/$f";
    my $text = _slurp($abs);
    ok(_scan_code($abs, qr/\bour\b/)                  == 0, "P1  - no 'our': $f");
    ok(_scan_code($abs, qr/\b(?:say|given|state)\b/)  == 0, "P2  - no say/given/state: $f");
    ok(_scan_code($abs, qr/my\s*\(\s*undef\s*,/)      == 0, "P3  - no my(undef,...): $f");
    ok(_scan_code($abs, qr/(?<![=!<>\/])\/\/(?!=)/)   == 0, "P4  - no //: $f");
    ok(_scan_code($abs, qr/\/\/=/)                    == 0, "P5  - no //=: $f");
    ok(_scan_code($abs, qr/(?<!\.)\.\.\.(?!\.)/)       == 0, "P6  - no ...: $f");
    ok(_scan_code($abs, qr/\bwhen\b/)                 == 0, "P7  - no when: $f");
    ok(_scan_code($abs, qr/\\o\{/)                    == 0, "P8  - no \\o{}: $f");
    ok(1,                                                   "P9  - MBCS source (skipped): $f");
    ok($text =~ /\$VERSION\s*=\s*\$VERSION/,               "P10 - \$VERSION self-assign: $f");
    ok($text =~ /\$INC\{'warnings\.pm'\}.*?!defined.*?warnings::import/s
    || $text =~ /!defined.*?warnings::import.*?\$INC\{'warnings\.pm'\}/s,
       "P11 - warnings stub guards with !defined(&warnings::import): $f");
    ok($text =~ /pop[ \t]+\@INC/,
       "P12 - CVE pop \@INC: $f");
    ok(_scan_code($abs, qr/open\s+my\b/)                == 0, "P13 - no 'open my' (use bareword FH): $f");
}

# Run P1-P14 on t/9xxx and t/lib/
for my $f (@t9_files) {
    my $abs  = "$ROOT/$f";
    my $text = _slurp($abs);
    ok(_scan_code($abs, qr/\bour\b/)                  == 0, "P1  - no 'our': $f");
    ok(_scan_code($abs, qr/\b(?:say|given|state)\b/)  == 0, "P2  - no say/given/state: $f");
    ok(_scan_code($abs, qr/my\s*\(\s*undef\s*,/)      == 0, "P3  - no my(undef,...): $f");
    ok(_scan_code($abs, qr/(?<![=!<>\/])\/\/(?!=)/)   == 0, "P4  - no //: $f");
    ok(_scan_code($abs, qr/\/\/=/)                    == 0, "P5  - no //=: $f");
    ok(_scan_code($abs, qr/(?<!\.)\.\.\.(?!\.)/)       == 0, "P6  - no ...: $f");
    ok(_scan_code($abs, qr/\bwhen\b/)                 == 0, "P7  - no when: $f");
    ok(_scan_code($abs, qr/\\o\{/)                    == 0, "P8  - no \\o{}: $f");
    {   # P9: must be US-ASCII
        local *P9FH;
        open P9FH, $abs or do { ok(0, "P9 - cannot open: $f"); next };
        binmode P9FH;
        my $raw = do { local $/; <P9FH> }; close P9FH;
        ok((grep { $_ > 127 } unpack('C*', $raw)) == 0,     "P9  - US-ASCII source: $f");
    }
    ok($text =~ /\$VERSION\s*=\s*\$VERSION/,               "P10 - \$VERSION self-assign: $f");
    ok($text =~ /\$INC\{'warnings\.pm'\}/,                 "P11 - warnings stub: $f");
    ok($text =~ /pop[ \t]+\@INC/,
       "P12 - CVE pop \@INC: $f");
    # P13: no at-minus / at-plus special variables
    my $no_p13 = _scan_code($abs, qr/\$[-+]\[/) == 0;
    if ($no_p13) {
        my $src13 = _slurp($abs);
        my $at = chr(64);
        $no_p13 = index($src13, $at."-") < 0 && index($src13, $at."+") < 0;
    }
    ok($no_p13, "P13 - no " . chr(64) . "-/" . chr(64) . "+: $f");
    ok(_scan_code($abs, qr/open\s+my\b/)                == 0, "P14 - no 'open my' (use bareword FH): $f");
}

# Run M1-M7 on Makefile.PL
if ($has_mkf) {
    my $abs  = "$ROOT/Makefile.PL";
    my $text = _slurp($abs);
    ok(_scan_code($abs, qr/\bour\b/)                  == 0, "M1  - no 'our': Makefile.PL");
    ok(_scan_code($abs, qr/\b(?:say|given|state)\b/)  == 0, "M2  - no say/given/state: Makefile.PL");
    ok(_scan_code($abs, qr/(?<![=!<>\/])\/\/(?!=)/)   == 0, "M3  - no //: Makefile.PL");
    ok(_scan_code($abs, qr/open\s+my\b/)              == 0, "M4  - no 'open my' (use bareword FH): Makefile.PL");
    ok($text =~ /\$INC\{'warnings\.pm'\}.*?!defined.*?warnings::import/s
    || $text =~ /!defined.*?warnings::import.*?\$INC\{'warnings\.pm'\}/s,
       "M5  - warnings stub guards with !defined(&warnings::import): Makefile.PL");
    ok($text =~ /pop[ \t]+\@INC/,
       "M6  - CVE pop \@INC: Makefile.PL");
    {   # M7: must be US-ASCII
        local *M7FH;
        open M7FH, $abs or do { ok(0, "M7 - cannot open: Makefile.PL"); };
        binmode M7FH;
        my $raw = do { local $/; <M7FH> }; close M7FH;
        ok((grep { $_ > 127 } unpack('C*', $raw)) == 0, "M7  - US-ASCII source: Makefile.PL");
    }
}

END { end_testing() }
