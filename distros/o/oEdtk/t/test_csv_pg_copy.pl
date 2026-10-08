#!/usr/bin/perl
#
# Test harness for the PostgreSQL COPY import path of oEdtk::DBAdmin::csv_import.
#
# For a Pg driver, csv_import routes (non-merge) imports through
# _load_csv_pg_copy, which cleans the CSV via clean_val into a temp file and
# then loads it with COPY ... FROM STDIN.
#
# Target table: the distribution table (config EDTK_DBI_DISTRIB, default
# 'edtk_distrib'), whose columns are @DISTRIB_COLS in oEdtk::DBAdmin. Every
# test row is tagged with a marker in ed_idjob, and an END block deletes those
# rows on exit, so real data is left untouched.
#
# The @expected table below encodes the clean_val contract of the row-by-row
# (prepare_cached) path:
#   - text column: value truncated to the column size
#   - empty text column    => ''   (empty string, NOT NULL)
#   - empty numeric column => NULL
#   - separator, quote char and newline inside a field survive the round-trip
#   (the distribution table has no date column -- ed_dtlot is varchar2(10))
#
# Usage: perl -Ilib t/test_csv_pg_copy.pl
# Requires EDTK_DBI_DSN to point at a dbi:Pg: database (see tracker/dev/edtk.ini).
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempfile);
use Text::CSV;
use Encode      qw(encode);
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect csv_import);

my $cfg   = config_read('EDTK_DB');
my $TABLE = $cfg->{'EDTK_DBI_DISTRIB'} || 'edtk_distrib';
my $dbh   = db_connect($cfg, 'EDTK_DBI_DSN', { AutoCommit => 1, RaiseError => 1 });
my $MARKER = 'CSVPGCOPYTEST';   # value written to ed_idjob to tag test rows

# always remove the test rows, even if the script dies
END {
    eval { $dbh->do("DELETE FROM $TABLE WHERE ed_idjob = ?", undef, $MARKER) } if $dbh;
}

my $driver = oEdtk::DBAdmin::_db_check_driver_name($dbh);
unless ($driver eq 'PostgreSQL') {
    die "This test targets PostgreSQL (the COPY path); current driver is '$driver'.\n"
      . "Point EDTK_DBI_DSN at a dbi:Pg: database.\n";
}
print "Driver: $driver   table: $TABLE   marker: $MARKER\n";

my @cols = map { $_->[0] } @oEdtk::DBAdmin::DISTRIB_COLS;

# row values in @cols order ; blanks are '' (see @expected for the outcome)
my @rows = (
    # ed_idldoc ed_idseqpg ed_seqdoc ed_idjob ed_idlot       ed_seqlot ed_dtlot      ed_idfiliere ed_seqpgdoc ed_nbpgdoc ed_workflow ed_chanel_out   ed_idged
    [ 'DOC1', 1, 1, $MARKER, 'LOT1',       'S1', '2026-07-09', 'FIL1',  1, 2, 'WF',  'CH',           'GED1' ],
    [ 'DOC2', 2, 2, $MARKER, 'LONGVALUE123','S2', '2026-07-09X','ABCDEFG',3, 4, 'WF2', 'CH2',          'GED2' ], # truncation
    [ 'DOC3', 3, 3, $MARKER, '',           'S3', '',           '',       '', '', 'WF3', 'CH3',          'GED3' ], # blanks
    [ 'DOC4', 4, 4, $MARKER, 'LOT4',       'S4', '2026-01-02', 'FIL4',  5, 6, 'a,b', 'He said "hi"', 'GED4' ], # sep + quote
    [ 'DOC5', 5, 5, $MARKER, 'LOT5',       'S5', '2026-01-03', 'FIL5',  7, 8, 'multi','line',        "GED5\nline2" ],
);

# expected values after clean_val (what the row-by-row path stores)
my @expected = (
    [ 'DOC1', 1, 1, $MARKER, 'LOT1',        'S1', '2026-07-09', 'FIL1',  1,    2,    'WF',   'CH',           'GED1' ],
    [ 'DOC2', 2, 2, $MARKER, 'LONGVALU',    'S2', '2026-07-09', 'ABCDE', 3,    4,    'WF2',  'CH2',          'GED2' ],
    [ 'DOC3', 3, 3, $MARKER, '',            'S3', '',           '',      undef,undef,'WF3',  'CH3',          'GED3' ],
    [ 'DOC4', 4, 4, $MARKER, 'LOT4',        'S4', '2026-01-02', 'FIL4',  5,    6,    'a,b',  'He said "hi"', 'GED4' ],
    [ 'DOC5', 5, 5, $MARKER, 'LOT5',        'S5', '2026-01-03', 'FIL5',  7,    8,    'multi','line',         "GED5\nline2" ],
);

# build the source CSV (header + rows)
my ($cfh, $cfile) = tempfile('oedtk_csvpg_XXXXXX', SUFFIX => '.csv', UNLINK => 1);
my $w = Text::CSV->new({ binary => 1, eol => "\n" });
$w->combine(@cols) or die "combine header: " . $w->error_input;
print $cfh $w->string;
for my $r (@rows) {
    $w->combine(@$r) or die "combine row: " . $w->error_input;
    print $cfh $w->string;
}
close($cfh);

# import via csv_import -> PostgreSQL COPY path
my ($count, $msg) = csv_import($dbh, $TABLE, $cfile,
    { sep_char => ',', quote_char => '"', mode => 'insert' });
print "csv_import returned: count=$count msg='$msg'\n";

my $sth = $dbh->prepare("SELECT " . join(',', @cols) . " FROM $TABLE"
                      . " WHERE ed_idjob = ? ORDER BY ed_seqdoc");
$sth->execute($MARKER);

my $fail = 0;
my $i    = 0;
while (my $got = $sth->fetchrow_arrayref) {
    my $exp = $expected[$i];
    my $ok  = 1;
    for my $c (0 .. $#$exp) {
        my $g    = $got->[$c];
        my $e    = $exp->[$c];
        my $same = defined $e ? (defined $g && $g eq $e) : !defined $g;
        next if $same;
        $ok = 0;
        printf "row %d col %s: expected [%s] got [%s]\n",
            $i + 1, $cols[$c],
            (defined $e ? $e : '<NULL>'), (defined $g ? $g : '<NULL>');
    }
    print "row " . ($i + 1) . ": " . ($ok ? "OK" : "FAIL") . "\n";
    $fail++ unless $ok;
    $i++;
}

if ($i != scalar @expected) {
    print "FAIL: expected " . scalar(@expected) . " rows, got $i\n";
    $fail++;
}
if (!defined $count || $count != scalar @rows) {
    print "FAIL: csv_import returned count " . (defined $count ? $count : '<undef>')
        . " but " . scalar(@rows) . " rows were submitted\n";
    $fail++;
}

# --- Encoding regression: an accented value and a pre-existing U+FFFD must
# --- round-trip through COPY as the client_encoding bytes, with no warnings.
# --- The source line is written as explicit UTF-8 bytes (combine with
# --- binary=>1 does not encode, so it is not used here).
my $client_enc = uc($dbh->selectrow_array('SHOW client_encoding') // '');
if ($client_enc ne 'UTF8') {
    print "note: client_encoding=$client_enc, skipping UTF-8 encoding case\n";
} else {
    $dbh->{pg_enable_utf8} = 0;   # fetch raw bytes for a deterministic compare
    my @evals = ('DOCE', 9, 9, $MARKER, "caf\x{E9}", 'S9', '2026-03-04', "FIL\x{FFFD}",
                 11, 12, 'WF9', 'CH9', 'GED9');
    my ($efh, $efile) = tempfile('oedtk_csvenc_XXXXXX', SUFFIX => '.csv', UNLINK => 1);
    binmode($efh);
    print $efh join(',', @cols), "\n";
    print $efh join(',', map { encode('UTF-8', $_) } @evals), "\n";
    close($efh);

    my ($ecount, $emsg) = csv_import($dbh, $TABLE, $efile,
        { sep_char => ',', quote_char => '"', mode => 'insert' });
    my $esth = $dbh->prepare("SELECT ed_idlot, ed_idfiliere FROM $TABLE"
                           . " WHERE ed_idjob = ? AND ed_idseqpg = 9");
    $esth->execute($MARKER);
    my ($lot, $fil) = $esth->fetchrow_array;
    my %want = ( ed_idlot    => encode('UTF-8', "caf\x{E9}"),
                 ed_idfiliere => encode('UTF-8', "FIL\x{FFFD}") );
    for my $c ([ 'ed_idlot', $lot ], [ 'ed_idfiliere', $fil ]) {
        my ($name, $got) = @$c;
        my $ok = defined $got && $got eq $want{$name};
        print "encoding $name: " . ($ok ? 'OK' : 'FAIL') . "\n";
        unless ($ok) {
            $fail++;
            printf "  %s expected bytes [%v02X] got [%s]\n", $name, $want{$name},
                (defined $got ? sprintf('%v02X', $got) : '<undef>');
        }
    }
    if (!defined $ecount || $ecount != 1) {
        print "encoding: csv_import count " . (defined $ecount ? $ecount : '<undef>')
            . " (expected 1)\n";
        $fail++;
    }
}

print($fail ? "RESULT: $fail failure(s)\n" : "RESULT: all checks passed\n");
exit($fail ? 1 : 0);
