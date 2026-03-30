######################################################################
# 9080-cheatsheets.t  doc/ cheat sheet quality checks.
#   S1  Native script present for expected languages
#   S2  Section numbers are consecutive [1..N]
#   S3  Header line contains [XX] language code
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

my @doc_files = sort glob "$ROOT/doc/mb_cheatsheet.*.txt";
plan_skip('no cheatsheets found') unless @doc_files;
plan_tests(scalar(@doc_files) * 3);

# Languages expected to use non-Latin native scripts
my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN MY KM MN NE SI UR FR TR VI);

for my $path (@doc_files) {
    my $doc  = File::Spec->abs2rel($path, $ROOT);
    my $lang = (split /\./, $doc)[-2];

    # S1: native script check
    if ($lang && $native_script{$lang}) {
        local *S1FH;
        open S1FH, $path or do { ok(0, "S1 - cannot open: $doc"); next };
        binmode S1FH;
        my $raw = do { local $/; <S1FH> }; close S1FH;
        ok((grep { $_ > 127 } unpack('C*', $raw)) > 0,
           "S1 - doc/ native script present: $doc");
    }
    else {
        ok(1, "S1 - doc/ native script not required [$lang]: $doc");
    }

    # S2: consecutive section numbers
    local *S2FH;
    open S2FH, $path or do { ok(0, "S2 - cannot open: $doc"); ok(0, "S3 - cannot open: $doc"); next };
    my @lines = <S2FH>; close S2FH;
    my @nums = map { /^\[ (\d+)\./ ? $1 : () } @lines;
    my $s2 = (@nums == 0) ? 0 : do {
        my $ok2 = 1;
        for my $i (0..$#nums) { $ok2 = 0 unless $nums[$i] == $i+1 }
        $ok2;
    };
    ok($s2, "S2 - doc/ section numbers consecutive [1..N]: $doc");

    # S3: [XX] header tag
    my $first = '';
    for my $l (@lines) { if ($l =~ /\S/ && $l !~ /^=/) { $first = $l; last } }
    my $s3 = $lang && $first =~ /\[$lang\]/;
    ok($s3, "S3 - doc/ header contains [$lang] language code: $doc"
       . ($s3 ? '' : " (header: $first)"));
}

END { end_testing() }
