use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Config;
use POSIX ();

plan skip_all => 'Author integration test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Unix only' if $^O eq 'MSWin32';
eval { require Test2::Harness; require Test2::Plugin::BailOnFail; 1 }
    or BAIL_OUT("Harness integration dependencies unavailable: $@");

my $repo = path('.')->absolute;
my $tmp = Path::Tiny->tempdir;
local $ENV{PERL5LIB} = join($Config{path_sep}, "$repo/lib", $ENV{PERL5LIB} || ());
my $pass = $tmp->child('pass.t');
my $hang = $tmp->child('hang.t');
$pass->spew_utf8("use Test::More; ok(1); done_testing;\n");
$hang->spew_utf8("# HARNESS-NO-TIMEOUT\nuse Test::More; sleep 30; ok(1); done_testing;\n");
my $base = $tmp->child('aggregate');
my $log = $tmp->child('log');
my $pid = fork;
die "fork: $!" unless defined $pid;
if (!$pid) {
    POSIX::setpgid(0, 0);
    open STDOUT, '>', "$log" or die $!;
    open STDERR, '>&STDOUT' or die $!;
    exec $^X, "$repo/aggit", '--event_timeout', 1, '--out', "$base", "$pass", "$hang"
        or POSIX::_exit(127);
}
my $status;
{
    local $SIG{ALRM} = sub { kill 9, -$pid; die "Harness integration timed out\n" };
    alarm 60;
    waitpid($pid, 0);
    $status = $?;
    alarm 0;
}
is($status, 0, 'actual yath recovers from an inactive test') or diag $log->slurp_utf8;
is(path("$base.lst")->slurp_utf8, "pass.t\n", 'only passing test is retained');
like($log->slurp_utf8, qr/\*\* Removing hang\.t/, 'removes the timed-out test');
unlike(path("$base.t")->slurp_utf8, qr/_progress_file/, 'final runner has no temporary progress dependency');
done_testing;
