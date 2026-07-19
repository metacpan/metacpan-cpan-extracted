######################################################################
# 9082-examples.t  eg/ example scripts run cleanly.
#   For every eg/**/*.pl:
#     E1  exits with status 0 (no non-zero / signalled exit)
#     E2  emits nothing on STDERR when run under -w (no warnings)
#
# Each example is executed in a child perl by its own path, so its
# "use lib \"$FindBin::Bin/../../lib\"" (or ../lib) locates this
# distribution's lib/mb.pm without any -I on the command line. STDOUT is
# discarded (examples print multibyte data); STDERR is captured to a temp
# file and must be empty. This is the same spirit as 9080-cheatsheets.t
# and reuses t/lib/INA_CPAN_Check.pm.
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION); $VERSION = $VERSION;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use File::Find ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my $EGDIR = File::Spec->catdir($ROOT, 'eg');
plan_skip('no eg/ directory found') unless -d $EGDIR;

# Collect every eg/**/*.pl (any depth), sorted for stable numbering.
use vars qw(@script);
@script = ();
File::Find::find({
    wanted => sub {
        push @script, $File::Find::name if -f $File::Find::name && /\.pl\z/;
    },
    no_chdir => 1,
}, $EGDIR);
@script = sort @script;

# Every example costs one child perl (process creation + interpreter
# start-up + loading lib/mb.pm).  On slow CPAN smokers -- above all the
# Windows machines where mb-0.65 already ran close to their limits --
# spawning every eg/**/*.pl pushes the wall-clock time of this one file
# toward the harness timeout.  Under automated testing, therefore, run
# only the first (sorted) example of each eg/ subdirectory: this still
# smoke-tests every language directory and every "use lib" depth, while
# cutting the number of child processes by roughly a factor of five.
# Interactive runs (pmake test on a development machine) and runs with
# PERL_MB_TEST_ALL_EG=1 keep executing all examples.  plan_tests() below
# is derived from scalar(@script), so the plan always matches.
if (($ENV{AUTOMATED_TESTING} or $ENV{NONINTERACTIVE_TESTING}) and not $ENV{PERL_MB_TEST_ALL_EG}) {
    my %seen_dir = ();
    my @sample = ();
    for my $abs (@script) {
        my $dir = (File::Spec->splitpath($abs))[1];
        push @sample, $abs unless $seen_dir{$dir}++;
    }
    if (@sample and (@sample < @script)) {
        print "# automated testing: sampling ", scalar(@sample), " of ", scalar(@script),
              " eg scripts (one per directory; set PERL_MB_TEST_ALL_EG=1 to run all)\n";
        @script = @sample;
    }
}

plan_skip('no eg/**/*.pl scripts found') unless @script;
plan_tests(scalar(@script) * 2);

# Quote the interpreter path for the piped command (it may contain spaces,
# e.g. C:\Program Files\...). Script paths in an ina distribution do not.
use vars qw($perl);
$perl = $^X;
$perl = qq{"$perl"} if $perl =~ /\s/;

for my $abs (@script) {
    my $rel = File::Spec->abs2rel($abs, $ROOT);

    # Per-run STDERR capture file (PID + sanitized rel path; no File::Temp,
    # which is not available on perl 5.005_03).
    my $pid = $$;
    (my $tag = $rel) =~ s/[^0-9A-Za-z]/_/g;
    my $errfile = File::Spec->catfile(File::Spec->tmpdir(), "mb_eg_${pid}_$tag.err");

    my $cmd = qq{$perl -w "$abs" 2>"$errfile"};

    # open(FH, "CMD |") with a bareword filehandle is portable to 5.005_03
    # on both Windows (cmd.exe) and Unix. STDOUT is read and discarded.
    my $ran = 0;
    local *RUN;
    if (open(RUN, "$cmd |")) {
        local $/;
        my $stdout = <RUN>;   # discard example output
        close RUN;
        $ran = 1;
    }
    my $exit = $?;

    # E1: exit status 0
    ok($ran && $exit == 0, "E1 - exits 0: $rel"
        . ($ran ? ($exit == 0 ? '' : " (status $exit)") : ' (could not run)'));

    # E2: no STDERR under -w
    my $stderr = '';
    if (-f $errfile) {
        local *ERRFH;
        if (open(ERRFH, $errfile)) {
            local $/;
            $stderr = <ERRFH>;
            close ERRFH;
        }
        unlink $errfile;
    }
    $stderr = '' unless defined $stderr;
    ok($stderr eq '', "E2 - no warnings on STDERR: $rel"
        . ($stderr eq '' ? '' : (' [' . _oneline($stderr) . ']')));
}

# Collapse captured STDERR to a single US-ASCII-safe diagnostic line.
sub _oneline {
    my ($text) = @_;
    $text =~ s/[\x0D\x0A]+/ /g;
    $text =~ s/[^\x20-\x7E]/./g;
    $text =~ s/\s+\z//;
    return $text;
}

END { end_testing() }
