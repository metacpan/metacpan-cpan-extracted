######################################################################
#
# gen_pod_transpile_catalog.pl
#
#   Regenerate the "Each elements in regular expressions are transpiled
#   as follows" catalog of lib/mb.pm from the live output of mb::parse().
#
#   This is a HAND-MANAGED maintainer tool, not a pmake-generated file.
#   The authoritative POD text still lives in lib/mb.pm; this script only
#   reproduces it mechanically so that the maintainer can diff, refresh,
#   or bootstrap a table for a newly added encoding without hand editing
#   every "\xHH" byte.
#
# What is authoritative and where it is read from (never duplicated here):
#   * the list of encodings  -> the import allow-list in lib/mb.pm
#                               ("use one of: *mb, %mb, big5, ... wtf8")
#   * the list of patterns   -> the left column of the
#                               "=head2 on every encodings" table
#   * the table framing/prose -> carried through verbatim from lib/mb.pm
#
# For each pattern core P (e.g. ".", "\B", "[[:alnum:]]"):
#   * the "every encodings" row feeds  qr/P/  to mb::parse() (the
#     encoding-independent, deferred @mb::_dot ... form)
#   * each "on <enc> encoding" row feeds  qr'P'  to mb::parse() with that
#     script encoding selected (the fully expanded per-encoding form)
#
# Usage:
#   perl devtool/gen_pod_transpile_catalog.pl              > catalog.new
#   perl devtool/gen_pod_transpile_catalog.pl path/to/mb.pm > catalog.new
#
#   Then diff catalog.new against the same span of lib/mb.pm. An empty
#   diff means the checked-in POD matches mb::parse(); t/9070 enforces
#   the same invariant at install time.
#
# Portability: runs on perl 5.005_03 through the latest. 2-argument
# bareword open() only; use vars (no our); no //, say, state, \x{}.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION); $VERSION = '0.01';
use FindBin ();
use lib "$FindBin::Bin/../lib";

# Locate lib/mb.pm: explicit argument wins, else ../lib/mb.pm next to this
# script's directory (devtool/ -> ../lib/mb.pm).
use vars qw($MB_PM);
$MB_PM = @ARGV ? $ARGV[0] : "$FindBin::Bin/../lib/mb.pm";
die "cannot find mb.pm at '$MB_PM'\n" unless -f $MB_PM;

require mb;

# --- read the source -------------------------------------------------
use vars qw(@src);
{
    local *IN;
    open(IN, $MB_PM) or die "cannot open '$MB_PM': $!\n";
    @src = <IN>;
    close IN;
}
for (@src) {
    s/[\x0D\x0A]+\z//;
}

# --- 1) authoritative encoding allow-list ----------------------------
# The import() die message is the one place that enumerates the list with
# the "*mb, %mb, " prefix, so it identifies the canonical allow-list
# unambiguously. Encodings are every token after that prefix except "mb".
use vars qw(@enc);
@enc = ();
{
    my $joined = join("\n", @src);
    if ($joined =~ /use \s+ one \s+ of: \s* \*mb, \s* %mb, \s* ([^)]+?) \)/xms) {
        my $list = $1;
        for my $tok ($list =~ /([0-9A-Za-z]+)/g) {
            push @enc, $tok unless $tok eq 'mb';
        }
    }
}
die "could not extract encoding allow-list from $MB_PM\n" unless @enc;

# --- 2) locate the catalog region ------------------------------------
# From the "Each elements ... transpiled as follows" heading up to (but
# not including) the next "=head1".
use vars qw($START_ANCHOR $lo $hi);
$START_ANCHOR = 'Each elements in regular expressions are transpiled as follows';
($lo, $hi) = (-1, -1);
for my $i (0 .. $#src) {
    if ($lo < 0 && $src[$i] eq $START_ANCHOR) {
        $lo = $i;
        next;
    }
    if ($lo >= 0 && $src[$i] =~ /^=head1 /) {
        $hi = $i - 1;
        last;
    }
}
$hi = $#src if $lo >= 0 && $hi < 0;
die "could not locate catalog region in $MB_PM\n" if $lo < 0;

# --- 3) intro prose, table framing, canonical pattern cores ----------
# Intro prose: everything from the start anchor up to the first "=head2".
use vars qw(@intro $first_head2);
@intro = ();
$first_head2 = -1;
for my $i ($lo .. $hi) {
    if ($src[$i] =~ /^=head2 /) {
        $first_head2 = $i;
        last;
    }
    push @intro, $src[$i];
}
die "no =head2 tables found in catalog region\n" if $first_head2 < 0;

# Table framing (dash rule and column header) and pattern cores are taken
# from the "on every encodings" table so widths match byte-for-byte.
use vars qw($DASH $HEADER @core %seen_core);
$DASH   = '';
$HEADER = '';
@core   = ();
%seen_core = ();
{
    my $in_every = 0;
    for my $i ($first_head2 .. $hi) {
        my $line = $src[$i];
        if ($line =~ /^=head2 on every encodings\s*\z/) {
            $in_every = 1;
            next;
        }
        if ($in_every && $line =~ /^=head2 /) {
            last;
        }
        next unless $in_every;
        if ($line =~ /^  -+\z/) {
            $DASH = $line unless $DASH ne '';
            next;
        }
        if ($line =~ /in your script/) {
            $HEADER = $line unless $HEADER ne '';
            next;
        }
        if ($line =~ /^  qr/) {
            my $input = substr($line, 2, 43);
            $input =~ s/\s+\z//;
            # every-table inputs are qr/CORE/ ; extract CORE.
            if ($input =~ m{\A qr/ (.*) / \z}xms) {
                my $c = $1;
                push @core, $c unless $seen_core{$c}++;
            }
        }
    }
}
die "could not read table framing from the every-encodings table\n"
    if $DASH eq '' || $HEADER eq '';
die "no pattern cores found in the every-encodings table\n" unless @core;

# --- helpers ---------------------------------------------------------
sub row {
    my ($input, $output) = @_;
    return sprintf("  %-43s%s", $input, $output);
}

sub transpiled {
    my ($input) = @_;
    my $out = mb::parse("$input\n");
    $out =~ s/[\x0D\x0A]+\z//;
    # An embedded qr// stringifies its flag group as "(?-xism:" on perl
    # before 5.14 and "(?^:" on 5.14+. The checked-in POD uses the "(?^:"
    # spelling, so normalize to it here; the generator then emits the same
    # catalog text on any perl and a diff against lib/mb.pm stays clean.
    $out =~ s/\(\?-xism:/(?^:/g;
    return $out;
}

sub emit_table {
    my ($heading, $quote_open, $quote_close, $encoding) = @_;
    mb::set_script_encoding($encoding);
    print "=head2 $heading\n";
    print "\n";
    print "$DASH\n";
    print "$HEADER\n";
    print "$DASH\n";
    for my $c (@core) {
        my $input = $quote_open . $c . $quote_close;
        print row($input, transpiled($input)), "\n";
    }
    print "$DASH\n";
}

# --- 4) emit the reconstructed catalog -------------------------------
# Intro prose verbatim (it already ends with the blank line before the
# first =head2).
for my $line (@intro) {
    print "$line\n";
}

# The "every encodings" table is encoding-independent (its transpiled
# column defers to @mb::_dot etc. at runtime), so any valid script
# encoding produces identical text; use the first allow-listed one.
emit_table('on every encodings', 'qr/', '/', $enc[0]);

for my $e (@enc) {
    print "\n";
    emit_table("on $e encoding", "qr'", "'", $e);
}
