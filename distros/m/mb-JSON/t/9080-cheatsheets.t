######################################################################
# 9080-cheatsheets.t  doc/ cheat sheet quality checks.
#
# Checks:
#   S1  Native script present for expected languages
#   S2  Section numbers are consecutive [1..N]
#   S3  Header line format: product name + [XX] lang-name
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

my @manifest  = _manifest_files($ROOT);
my @doc_files = sort grep { m{^doc/.*\.txt$} && -f "$ROOT/$_" } @manifest;

plan_skip('no doc/*.txt files found') unless @doc_files;
plan_tests(scalar(@doc_files) * 3);

# Languages expected to use non-Latin native scripts
my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN MY KM MN NE SI UR FR TR VI);

for my $doc (@doc_files) {
    my $path = "$ROOT/$doc";
    my $lang = '';
    $lang = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;

    # S1: native script
    if ($lang && $native_script{$lang}) {
        local *FHS1;
        open FHS1, "< $path" or do {
            ok(0, "S1 - doc/ cannot open: $doc");
            ok(1, "S2 - skipped"); ok(1, "S3 - skipped"); next;
        };
        binmode FHS1;
        my $raw = do { local $/; <FHS1> }; close FHS1;
        my $non_ascii = 0;
        for my $i (0 .. length($raw)-1) {
            $non_ascii++ if ord(substr($raw,$i,1)) > 127;
        }
        ok($non_ascii > 0,
           "S1 - doc/ native script present [$lang]: $doc");
    }
    else {
        ok(1, "S1 - doc/ native script not required [$lang]: $doc");
    }

    # S2: consecutive section numbers
    local *FHS2;
    open FHS2, "< $path" or do { ok(0, "S2 - cannot open: $doc"); ok(1,""); next };
    my $doc_text = do { local $/; <FHS2> }; close FHS2;
    my @nums = ($doc_text =~ /^\[ (\d+)\./mg);
    my $s2 = 1;
    for my $i (0 .. $#nums) {
        if ($nums[$i] != $i + 1) { $s2 = 0; last }
    }
    ok($s2,
       "S2 - doc/ section numbers consecutive [1.." . scalar(@nums) . "]: $doc"
       . ($s2 ? '' : " (got: @nums)"));

    # S3: header line must contain [XX] matching the filename lang code
    my $first_line = '';
    local *FHS3;
    open FHS3, "< $path" or do { ok(0, "S3 - cannot open: $doc"); next };
    while (<FHS3>) {
        $_ =~ s/\r?\n$//;
        if (/\S/ && !/^=/) { $first_line = $_; last }
    }
    close FHS3;
    my $s3 = $lang && $first_line =~ /\[$lang\]/;
    ok($s3,
       "S3 - doc/ header contains [$lang] language code: $doc"
       . ($s3 ? '' : " (header: $first_line)"));
}

END { end_testing() }
