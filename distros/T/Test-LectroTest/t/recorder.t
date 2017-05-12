#! perl

# Tom Moertel <tom@moertel.com>

# Here we test the failure-recoding and failure-playback features.

use File::Temp 'tempfile';
use Test::More tests => 14;

BEGIN { unshift @INC, 't/lib'; }
use CaptureOutput;

my $prop_success = "Property { ##[ ]## 1 };\n";
my $prop_failure = "Property { ##[ ]## 0 };\n";

my @MODULES = my ( $LT, $LTC )
    = (qw( Test::LectroTest Test::LectroTest::Compat ));
my @RECORDER_OPTS = my ( $RF, $PF, $RG)
    = (qw( record_failures playback_failures regressions ));


$| = 1;

# make sure it is OK to specify an unusable file for recoding and
# playback (e.g., we may be on read-only media or perhaps no regressions
# have been recorded yet)

for my $module (@MODULES) {
    my $plan = sub { mk_plan($module, 1, 1, @_) };
    for my $opt (@RECORDER_OPTS) {
        my $opt_plan = $plan->("$opt => '/path/that/does/not/exist/....';\n");
        my $oks = suite_results($opt_plan, prop_succ($module, 1))->[1];
        is( $oks, 1, "$module + $opt + non-existent file is OK" );
    }
}

# make sure playback works

for my $pass (0, 1) {
    with_temp_file( sub {
        my ($pfile) = @_;
        for my $module (@MODULES) {
            for my $opt ($PF, $RG) {
                my $plan = mk_plan($module, 2, 0, "$opt => '$pfile';\n",
                                   (prop_x($module, 0)) x 2);
                my ($results, $oks, $noks) = @{suite_results($plan)};
                is_deeply( [$oks, $noks], [2 * $pass, 2 * (1-$pass)],
                           "$module + $opt playback works (npass=$pass)" );
            }
        }},
        "[ 'P', { x => $pass } ]\n"
    );
}





sub mk_plan {
    my ($module, $tests, $trials, @statements) = @_;
    $tests   = $module eq $LT ? "" : "tests => $tests, ";
    $module .= " trials => $trials, " if $module eq $LT;
    join("", "use $module $tests", @statements, "\n");
}

sub mk_prop {
    my ($module, $trials, $body) = @_;
    my $prop = "Property { $body }, name => 'P'";
    return "$prop;\n" if $module eq $LT;
    return "holds( ($prop), trials => $trials );\n";
}

sub prop_succ { mk_prop(@_, '##[ x <- Int ]## 1' ) }
sub prop_fail { mk_prop(@_, '##[ x <- Int ]## 0' ) }
sub prop_x    { mk_prop(@_, '##[ x <- Int ]## $x' ) }


sub suite_results {
    my $results  = make_and_run_suite(@_);
    my $oks      = @{[ $results =~ /^ok/mg ]};
    my $noks     = @{[ $results =~ /^not ok/mg ]};
    my ($status) = $results =~ /^(.*)/;
    [$results, $oks, $noks, $status];
}

sub with_temp_file {
    my ($code, @body) = @_;
    my ($fh, $fn) = tempfile() or die "can't open temp file: $!";
    print $fh @body;
    close $fh;
    my $result = $code->($fn);
    unlink $fn;
    $result;
}

sub make_and_run_suite {
    my $code = sub {
        my @cmd = ($^X, "-Ilib", $_[0]);
        my $recorder = capture(*STDOUT);
        my $errors = capture(*STDERR);
        my $exit_status = system(@cmd) >> 8;
        $errors->();  # don't care about STDERR output
        "$exit_status\n" . $recorder->();
    };
    with_temp_file( $code, @_ );
}
