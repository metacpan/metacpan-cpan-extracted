use Config;
use Data::Dumper;
use Win32::Job;

my $job;
my $perlpath = $Config{perlpath};
if ($^O eq 'cygwin') {
    chomp($perlpath = `cygpath -w $perlpath`);
    $perlpath .= '.exe' if $perlpath !~ /\.exe$/;
}

# Processes you spawn in the job are initially suspended. You can activate
# them by using one of the following functions. This allows you to run several 
# processes in the same job.

# You can do this to run sub{} every 50 seconds until the process dies. This
# is one way to implement your own timeout, for example. The watchdog is passed
# the $job object.

my $pid;
if ($pid = fork()) {
    waitpid($pid,0);
    exit($? >> 8);
}
$ENV{xxyyzz} = 'fOo';

$job = Win32::Job->new;
$job->spawn($perlpath, "perl child.t", {
	stdin => 'NUL',
	stdout => 'stdout.txt',
	stderr => 'stdout.txt',
});
$job->spawn($perlpath, "perl -le \"print \$\$\"");
$job->spawn("cmd", q{cmd /C "echo %PATH%"});
$i = 0;
$job->watch(sub {
	print "Callback ($i / 3)\n";
	return ++$i >= 3;
}, 1);
print Dumper $job->status;
END { unlink "stdout.txt" }

# You can do this to set a hard timeout. When it expires, the process and all
# of its subprocesses will be killed. If you specify a timeout of zero, then
# you're letting it run with no timeout at all (and you might as well use a 
# simpler module).
$job = Win32::Job->new;
$job->spawn($perlpath, "perl child.t"); #, {new_console => 1});
$job->run(10);
print Dumper $job->status;
print "$^E\n";

# You can call kill() explicitly to kill the job and all of its subprocesses.
# You could do this from a watchdog timer, for example.
$job = Win32::Job->new;
$job->spawn($perlpath, "perl child.t");
$job->run(1);
print Dumper $job->status;
