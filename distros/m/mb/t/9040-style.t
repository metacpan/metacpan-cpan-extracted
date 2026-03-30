######################################################################
# 9040-style.t  ina@CPAN coding style checks.
#
# Note: lib/mb.pm is a transpiler/source-code-filter.  Its internal
#       code intentionally contains patterns (comma spacing, hash-ref)
#       that serve the transpilation machinery.  K-style checks on
#       lib/mb.pm are skipped; only E (brace style) is checked.
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

# E check: all .pm and .t files in MANIFEST
my $e_count = count_E($ROOT);

# K check: only t/9xxx and t/lib/ (not lib/mb.pm)
my @manifest  = _manifest_files($ROOT);
my @k_targets = grep { /^(?:t\/9\d{3}.*\.t|t\/lib\/.+\.pm)$/ && -f "$ROOT/$_" } @manifest;
my $k_count   = scalar(@k_targets) * 3;  # K1 + K2 + K3

plan_tests($e_count + $k_count);

check_E($ROOT);

# K checks on t/9xxx and t/lib/ only
for my $f (sort @k_targets) {
    my $abs  = "$ROOT/$f";
    my $text = _slurp($abs);
    $text =~ s/\n__END__\b.*\z//s;
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    my @lines = split /\n/, $text;

    # K1: comma followed by space
    my @k1;
    my $ln = 0;
    for my $raw (@lines) {
        $ln++;
        my $s = $raw;
        $s =~ s/^\s*#.*$//; next unless $s =~ /\S/;
        $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
        $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
        $s =~ s{/[^/]+/[gimsex]*}{}g;
        $s =~ s/#.*$//;
        push @k1, $ln if $s =~ /,(?=[^\s\n\)\]\}\/])/;
    }
    ok(!@k1, "K1 - $f: comma space" . (@k1 ? " (lines: @k1[0..(@k1<3?$#k1:2)])" : ''));

    # K2: \@array (exclude \@ inside regex delimiters)
    my @k2;
    $ln = 0;
    for my $line (@lines) {
        $ln++;
        next if $line =~ /^\s*#/;
        if ($line =~ /\\/) {
            my $tmp = $line;
            $tmp =~ s{'[^']*'}{''}g;
            $tmp =~ s{"[^"]*"}{""}g;
            $tmp =~ s{/[^/]*/[gimsex]*}{}g;
            $tmp =~ s{qr/[^/]*/[gimsex]*}{}g;
            $tmp =~ s/\\@\w*\s*=\s*[(\[{]//g;
            push @k2, $ln if $tmp =~ /\\@/;
        }
    }
    ok(!@k2, "K2 - $f: use [ \@array ]" . (@k2 ? " (lines: @k2[0..(@k2<3?$#k2:2)])" : ''));

    # K3: \%hash (exclude \% inside strings and regex)
    my @k3;
    $ln = 0;
    for my $line (@lines) {
        $ln++;
        next if $line =~ /^\s*#/;
        if ($line =~ /\\%/) {
            my $tmp = $line;
            $tmp =~ s{'[^']*'}{''}g;
            $tmp =~ s{"[^"]*"}{""}g;
            $tmp =~ s{/[^/]*/[gimsex]*}{}g;
            $tmp =~ s/\\%(?:env|opts|args|hash)\b\w*//g;
            push @k3, $ln if $tmp =~ /\\%\w/;
        }
    }
    ok(!@k3, "K3 - $f: use { \%hash }" . (@k3 ? " (lines: @k3[0..(@k3<3?$#k3:2)])" : ''));
}

END { end_testing() }
