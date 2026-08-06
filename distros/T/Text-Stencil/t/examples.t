use strict;
use warnings;
use Test::More;
use File::Spec;
use Config;

# Nothing ran eg/ until now, which is how a CSV example that emitted output no
# standards-conforming parser would accept came to be shipped. These run each
# script and check the output where the format has an external definition.

my @scripts = sort glob File::Spec->catfile('eg', '*.pl');
plan skip_all => 'no eg/ scripts found' unless @scripts;

# The examples run in child processes, so they need a path to the built XS, not
# just this process's @INC. Skip rather than fail when there is no build to
# point them at -- `prove -l t/examples.t` on a clean checkout has nothing to
# load, since the .so only ever exists under blib.
my @inc = map { "-I$_" } grep { !ref && -d } (qw(blib/arch blib/lib), @INC);
# Run perl without a shell -- a space in $^X or in any @INC entry would
# otherwise be re-split and the child handed a truncated path. The fork form
# lets the child merge its stderr into the pipe, which the shell used to do.
# $merge folds the child's stderr into the returned text. The warnings check
# needs that; the CSV parse must NOT have it, because one unrelated line of
# stderr -- a smoker whose LANG names an uninstalled locale, say -- would be
# fed to the parser and fail the test for no reason.
sub run_child {
    my ($merge, @args) = @_;
    my $pid = open my $p, '-|';
    defined $pid or die "cannot fork: $!";
    unless ($pid) {
        if ($merge) { open STDERR, '>&', \*STDOUT or exit 127 }
        else        { open STDERR, '>', File::Spec->devnull or exit 127 }
        exec $^X, @args;
        exit 127;
    }
    local $/;
    my $out = <$p>;
    close $p;                      # sets $? for the caller
    return defined $out ? $out : '';
}

system($^X, @inc, '-e', 'require Text::Stencil') == 0
    or plan skip_all => 'Text::Stencil is not built; run make first';

for my $script (@scripts) {
    # list form: a space in $^X or any @INC entry would otherwise be re-split
    # by the shell, and the child would be handed a truncated path
    # each example has `use warnings`, which is what this assertion tests; -w
    # would additionally force warnings on inside every module they load, so a
    # future warning from a core dependency would fail this for no good reason
    my $out = run_child(1, @inc, $script);
    my $rc  = $?;
    is $rc & 127, 0, "$script does not die on a signal";
    is $rc >> 8, 0, "$script exits successfully"
        or diag $out;
    ok length $out, "$script produces output";
    unlike $out, qr/\b(?:uninitialized|Use of|isn't numeric|Wide character)\b/,
        "$script runs without warnings";
}

# csv_export.pl claims to emit CSV, so hold it to a real parser
SKIP: {
    my $have_csv = eval { require Text::CSV_XS; 1 };
    skip 'Text::CSV_XS not installed', 3 unless $have_csv;
    my $script = File::Spec->catfile('eg', 'csv_export.pl');
    skip 'no csv_export.pl', 3 unless -f $script;

    my $out = run_child(0, @inc, $script);
    open my $fh, '<', \$out or die $!;
    my $csv = Text::CSV_XS->new({ binary => 1 });
    my @rows;
    while (my $row = $csv->getline($fh)) { push @rows, $row }

    ok $csv->eof, 'csv_export.pl output parses to the end'
        or diag 'parser stopped: ' . join ' ', $csv->error_diag;
    is scalar @rows, 4, '  header plus three records';
    # the sample data contains an embedded quote; it must survive the round trip
    is $rows[2][0], 'Bob "B"', '  an embedded quote round-trips intact';
}

done_testing;
