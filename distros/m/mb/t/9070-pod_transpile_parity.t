######################################################################
#
# 9070-pod_transpile_parity.t
#
#   Drift detector for the "Each elements in regular expressions are
#   transpiled as follows" catalog in lib/mb.pm.
#
#   The catalog documents, for the encoding-independent case and for
#   every supported script encoding, how each regex construct is
#   transpiled. Those rows are maintained by hand and byte-verified.
#   This test re-derives each transpiled column from the live output of
#   mb::parse() and compares it, byte for byte, with the checked-in POD.
#   Any drift (a new/changed encoding, a tweak to _cc/_anchor, an edited
#   byte in the table) fails here at install time.
#
#   Checks per catalog row (T1):
#     the checked-in line equals sprintf("  %-43s%s", input, got), where
#     got = mb::parse(input) with the row's script encoding selected.
#     This validates the input column, the column padding, and the
#     transpiled column all at once. The compare is exact except that the
#     stringified-qr flag group "(?^:" (perl >= 5.14) and "(?-xism:" (perl
#     < 5.14) are treated as equal, since that spelling is a perl-version
#     artifact, not catalog drift.
#
#   Structural checks:
#     S1  the catalog region is present in lib/mb.pm
#     S2  the "on every encodings" table is present
#     S3  a per-encoding table exists for each allow-listed encoding
#     S4  no per-encoding table exists for a non-allow-listed name
#
#   Authoritative sources (never duplicated in this test):
#     * encodings -> the import allow-list in lib/mb.pm
#     * patterns  -> the left column of each POD table itself
#
#   The plan count is derived (never hardcoded): it is the number of
#   assertions actually built while walking the POD.
#
#   Portable to perl 5.005_03 through the latest. 2-argument bareword
#   open() only; use vars (no our); no //, say, state, \x{}.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION); $VERSION = $VERSION;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;
use mb;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));
my $MB_PM = File::Spec->catfile($ROOT, 'lib', 'mb.pm');

# --- read lib/mb.pm --------------------------------------------------
my @src = _slurp_lines($MB_PM);
for (@src) {
    s/[\x0D\x0A]+\z//;
}

# --- authoritative encoding allow-list -------------------------------
# Taken from the import() die message, the single place that lists the
# encodings with the "*mb, %mb, " prefix. Every token after that prefix
# except "mb" is an encoding.
use vars qw(@enc %is_enc);
@enc = ();
{
    my $joined = join("\n", @src);
    if ($joined =~ /use \s+ one \s+ of: \s* \*mb, \s* %mb, \s* ([^)]+?) \)/xms) {
        for my $tok ($1 =~ /([0-9A-Za-z]+)/g) {
            push @enc, $tok unless $tok eq 'mb';
        }
    }
}
%is_enc = map { ($_ => 1) } @enc;

# --- locate the catalog region ---------------------------------------
# From the start anchor up to (not including) the next =head1.
my $START = 'Each elements in regular expressions are transpiled as follows';
my ($lo, $hi) = (-1, -1);
for my $i (0 .. $#src) {
    if ($lo < 0 && $src[$i] eq $START) {
        $lo = $i;
        next;
    }
    if ($lo >= 0 && $src[$i] =~ /^=head1 /) {
        $hi = $i - 1;
        last;
    }
}
$hi = $#src if $lo >= 0 && $hi < 0;

# --- build the assertion list (derives the plan) ---------------------
# Each element: [ ok_flag, name, expected_line, got_line ]. expected/got
# are only used to print a diff on failure.
use vars qw(@assert);
@assert = ();

sub _push {
    my ($ok, $name, $exp, $got) = @_;
    push @assert, [ $ok ? 1 : 0, $name,
                    defined($exp) ? $exp : '', defined($got) ? $got : '' ];
}

# S1: catalog region present.
_push(($lo >= 0 && @enc), 'S1 - transpile catalog region present in lib/mb.pm');

if ($lo >= 0 && @enc) {
    # Walk the region, splitting it into tables keyed by =head2 heading.
    # A table is (encoding_key, [ raw_row, ... ]); encoding_key is 'every'
    # for the encoding-independent table or the encoding name otherwise.
    use vars qw(@table %seen_table);
    @table = ();
    %seen_table = ();
    my $cur = undef;   # aref [ key, quote_open, quote_close, enc_for_parse, rows_aref ]
    for my $i ($lo .. $hi) {
        my $line = $src[$i];
        if ($line =~ /^=head2 on every encodings\s*\z/) {
            $cur = [ 'every', 'qr/', '/', (@enc ? $enc[0] : ''), [] ];
            push @table, $cur;
            $seen_table{'every'} = 1;
            next;
        }
        if ($line =~ /^=head2 on (\S+) encoding\s*\z/) {
            my $name = $1;
            $cur = [ $name, "qr'", "'", $name, [] ];
            push @table, $cur;
            $seen_table{$name} = 1;
            next;
        }
        next unless defined $cur;
        # a data row starts with two spaces then qr
        if ($line =~ /^  qr/) {
            push @{$cur->[4]}, $line;
        }
    }

    # S2: the every-encodings table is present.
    _push($seen_table{'every'}, 'S2 - "on every encodings" table present');

    # S3: one table per allow-listed encoding.
    for my $e (@enc) {
        _push($seen_table{$e}, "S3 - per-encoding table present: $e");
    }

    # S4: no table for a name outside the allow-list.
    for my $t (@table) {
        my $key = $t->[0];
        next if $key eq 'every';
        _push($is_enc{$key},
              "S4 - table encoding is allow-listed: $key",
              join(',', @enc), $key);
    }

    # T1: per-row byte-for-byte parity with mb::parse(), after collapsing
    # the one difference that is a perl-version artifact rather than drift:
    # an embedded qr// stringifies its flag group as "(?-xism:" on perl
    # before 5.14 and as "(?^:" on 5.14+. Both mean "reset flags to the
    # default", so _canon() maps either spelling to one sentinel before the
    # compare. Every other byte (the \xHH ranges, class contents, column
    # padding) is still matched exactly, so real drift still fails.
    for my $t (@table) {
        my ($key, $qo, $qc, $penc, $rows) = @$t;
        # Selecting the script encoding is required before mb::parse().
        # For the every-encodings table the transpiled column defers to
        # @mb::_dot etc. and is encoding-independent, so $enc[0] is used.
        mb::set_script_encoding($penc) if $penc ne '';
        for my $raw (@$rows) {
            my $input;
            if ($raw =~ /^  (\S.*?)\s{2,}(qr\{.*)\z/) {
                $input = $1;
            }
            else {
                _push(0, "T1 - [$key] malformed catalog row",
                      $raw, '(does not match "  <input>  <qr{...}>")');
                next;
            }
            my $got = mb::parse("$input\n");
            $got =~ s/[\x0D\x0A]+\z//;
            my $rebuilt = sprintf("  %-43s%s", $input, $got);
            _push((_canon($raw) eq _canon($rebuilt)),
                  "T1 - [$key] $input", $raw, $rebuilt);
        }
    }
}

# Collapse the two equivalent flag-reset spellings of a stringified qr//
# (perl < 5.14 "(?-xism:" and perl >= 5.14 "(?^:") to one sentinel, so the
# parity compare does not depend on the perl the test runs under. A bare
# "(?:" is left untouched, so a drift that dropped the reset group entirely
# would still be caught.
sub _canon {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text =~ s/\(\?\^:/\x01/g;
    $text =~ s/\(\?-xism:/\x01/g;
    return $text;
}

# --- emit the plan, then run -----------------------------------------
plan_tests(scalar(@assert));
for my $a (@assert) {
    my ($ok, $name, $exp, $got) = @$a;
    ok($ok, $name);
    if (!$ok) {
        diag('expected: ' . _oneline($exp));
        diag('actual  : ' . _oneline($got));
    }
}

# Collapse a value to a single US-ASCII-safe diagnostic line.
sub _oneline {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text =~ s/[\x0D\x0A]+/ /g;
    $text =~ s/[^\x20-\x7E]/./g;
    $text =~ s/\s+\z//;
    return $text;
}

END { end_testing() }
