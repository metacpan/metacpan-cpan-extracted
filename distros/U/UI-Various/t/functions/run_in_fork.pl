#!/bin/false
# not to be used stand-alone
#
# Due to the singleton implementation we need to run the tests within a fork
# (or we would need a lot of different test sources).  Note that we also
# need our own "_ok" as we otherwise would confuse the test harness ("Parse
# errors: Tests out of sequence."):
my ($fork, $test, $ok) = (1, 0, 0);
sub _ok($$)
{
    $test++;
    if ($_[0])
    {
	$ok++;
    }
    else
    {
	print STDERR "    #   Failed test '", $_[1], "':\n";
	print STDERR '    #   failed test ', $test, ' in fork ', $fork, "\n";
    }
}
sub _run_in_fork($$$)
{
    my ($desc, $is_ok, $sub) = @_;
    my $pid = undef;
    if (not defined($pid = fork))
    {   die "fork failed\n";   }
    elsif ($pid)		# main process
    {
	local $SIG{INT} = sub { die "interrupted fork\n"; };
	waitpid($pid, 0);
	is($?, $is_ok << 8, "$desc \[fork $fork]");
	$fork++;
	return;
    }
    &$sub;
    exit $ok;
}
