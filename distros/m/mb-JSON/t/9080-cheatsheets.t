######################################################################
# 9080-cheatsheets.t  doc/ cheat sheet quality checks.
#
# Checks:
#   S1  Native script present for expected languages
#   S2  Section numbers are consecutive [1..N]
#   S3  Header line format: product name + [XX] lang-name
#   S4  Every language carries the same number of sections
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

# Languages expected to use non-Latin native scripts
my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN MY KM MN NE SI UR FR TR VI);

my @tests;

for my $doc (@doc_files) {
    my $path = "$ROOT/$doc";
    my $lang = '';
    $lang = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;

    # S1: native script
    push @tests, sub {
        if ($lang && $native_script{$lang}) {
            local *FHS1;
            open FHS1, "< $path" or do {
                ok(0, "S1 - doc/ cannot open: $doc"); return;
            };
            binmode FHS1;
            my $raw = do { local $/; <FHS1> }; close FHS1;
            my $non_ascii = 0;
            for my $i (0 .. length($raw)-1) {
                $non_ascii++ if ord(substr($raw, $i, 1)) > 127;
            }
            ok($non_ascii > 0,
               "S1 - doc/ native script present [$lang]: $doc");
        }
        else {
            ok(1, "S1 - doc/ native script not required [$lang]: $doc");
        }
    };

    # S2: consecutive section numbers
    push @tests, sub {
        local *FHS2;
        open FHS2, "< $path" or do { ok(0, "S2 - doc/ cannot open: $doc"); return };
        my $doc_text = do { local $/; <FHS2> }; close FHS2;
        my @nums = ($doc_text =~ /^\[ (\d+)\./mg);
        my $s2 = 1;
        for my $i (0 .. $#nums) {
            if ($nums[$i] != $i + 1) { $s2 = 0; last }
        }
        ok($s2,
           "S2 - doc/ section numbers consecutive [1.." . scalar(@nums) . "]: $doc"
           . ($s2 ? '' : " (got: @nums)"));
    };

    # S3: header line must contain [XX] matching the filename lang code
    push @tests, sub {
        my $first_line = '';
        local *FHS3;
        open FHS3, "< $path" or do { ok(0, "S3 - doc/ cannot open: $doc"); return };
        while (<FHS3>) {
            $_ =~ s/\r?\n$//;
            if (/\S/ && !/^=/) { $first_line = $_; last }
        }
        close FHS3;
        my $s3 = $lang && $first_line =~ /\[$lang\]/;
        ok($s3,
           "S3 - doc/ header contains [$lang] language code: $doc"
           . ($s3 ? '' : " (header: $first_line)"));
    };
}

# S4: every cheat sheet must carry the same sections.  S2 only checks that
# the numbering inside one file is consecutive, so a language that merges
# or drops a section stays invisible to it.
push @tests, sub {
    my %count_of;
    for my $doc (@doc_files) {
        local *FHS4;
        open FHS4, "< $ROOT/$doc" or do {
            ok(0, "S4 - doc/ cannot open: $doc"); return;
        };
        my $doc_text = do { local $/; <FHS4> }; close FHS4;
        my @nums = ($doc_text =~ /^\[ (\d+)\./mg);
        $count_of{$doc} = scalar(@nums);
    }
    my %docs_by_count;
    for my $doc (sort keys %count_of) {
        push @{ $docs_by_count{ $count_of{$doc} } }, $doc;
    }
    my @counts = sort { scalar(@{ $docs_by_count{$b} })
                    <=> scalar(@{ $docs_by_count{$a} }) } keys %docs_by_count;
    my $expected = $counts[0];
    my @odd;
    for my $n (@counts) {
        next if $n eq $expected;
        push @odd, map { "$_ has $n" } @{ $docs_by_count{$n} };
    }
    ok(!@odd,
       "S4 - doc/ all languages have $expected sections"
       . (@odd ? " (odd ones out: " . join('; ', @odd) . ")" : ''));
};

plan_tests(scalar(@tests));
$_->() for @tests;

END { end_testing() }
