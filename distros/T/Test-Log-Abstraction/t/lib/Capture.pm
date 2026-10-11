package Capture;

# Shared by the tests: run code and return what it printed through
# Test::Builder's diag(), without that output reaching the TAP stream.

use strict;
use warnings;
use autodie qw(:all);

use Exporter qw(import);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Builder;

our @EXPORT_OK = qw(capture_diag failing printed run_perl_script);

# capture_diag - capture diagnostics printed while running a block
#
# Purpose:      Let a test assert on what the logger prints.
# Entry:        $code - code reference to run.
# Exit:         Returns the captured text; rethrows anything $code died with,
#               after restoring the handles.
# Side effects: Temporarily replaces Test::Builder's failure and TODO
#               output handles, which is where diag() writes.
sub capture_diag(&) {
	my $code = shift;

	my $tb = Test::Builder->new();
	my $captured = '';
	open(my $sink, '>', \$captured);

	# failure_output($fh) returns the handle it just set, so fetch the
	# originals first, without an argument
	my @original = ($tb->failure_output(), $tb->todo_output());
	$tb->failure_output($sink);
	$tb->todo_output($sink);

	# The caller's $@ is restored, so tests can check that code under test
	# leaves $@ alone even when it runs inside capture_diag
	my ($ok, $error);
	{
		local $@;
		$ok = eval { $code->(); 1 };
		$error = $@;
	}

	$tb->failure_output($original[0]);
	$tb->todo_output($original[1]);
	close($sink);
	die $error if(!$ok);

	return $captured;
}

# printed - what a block printed through diag(), comparable exactly
#
# Purpose:      capture_diag() returns the text as Test::Builder wrote it,
#               which inside a subtest is indented; this removes that
#               indentation so the text can be compared exactly.
# Entry:        $code - code reference to run.
# Exit:         Returns the captured text.
# Side effects: As capture_diag().
sub printed(&) {
	my $code = shift;

	(my $out = capture_diag(\&{$code})) =~ s/^[ ]+#/#/mg;
	return $out;
}

# failing - run an assertion that is meant to fail, without failing the file
#
# Purpose:      Check what a failing assertion returns and prints.
# Entry:        $code - code reference that makes the assertion.
# Exit:         Returns ($result, $output): what the code returned, and
#               what was printed (as printed() returns it).
# Side effects: Adds one TODO test result to the TAP output.
sub failing {
	my $code = shift;

	my $tb = Test::Builder->new();
	my $result;
	$tb->todo_start('expected to fail: checking its output');
	my $out = printed { $result = $code->() };
	$tb->todo_end();
	return ($result, $out);
}

# run_perl_script - run perl code in a fresh process, portably
#
# Purpose:      Some tests need a clean interpreter (to hide modules, or to
#               replace builtins before anything is compiled).  A forking
#               pipe open ('-|') does not exist on Windows, and passing a
#               multi-line script with -e is quoted differently by every
#               shell, so the script goes in a file and perl is started with
#               list-form system(), which uses no shell at all.
# Entry:        $script   - the perl code to run.
#               @switches - extra perl switches, such as -MModule=args.
# Exit:         Returns everything the child printed, STDOUT and STDERR
#               together; '' if it printed nothing.
# Side effects: Briefly points this process's STDOUT and STDERR at a file
#               (Test::Builder keeps its own copies, so TAP is unaffected).
#               The child runs without TEST_VERBOSE or VERBOSE, so that
#               prove -v does not add diagnostics to what is checked.
sub run_perl_script {
	my ($script, @switches) = @_;

	my $dir = tempdir(CLEANUP => 1);
	my $program = File::Spec->catfile($dir, 'child.pl');
	my $captured = File::Spec->catfile($dir, 'child.out');
	open(my $source, '>', $program);
	print {$source} $script;
	close($source);

	my @include = map { '-I' . File::Spec->rel2abs($_) } ('lib', File::Spec->catdir('t', 'lib'));
	local $ENV{'TEST_VERBOSE'};
	local $ENV{'VERBOSE'};
	delete @ENV{qw(TEST_VERBOSE VERBOSE)};

	# Send this process's output to the file while the child inherits it
	open(my $saved_out, '>&', \*STDOUT);
	open(my $saved_err, '>&', \*STDERR);
	open(STDOUT, '>', $captured);
	open(STDERR, '>&', \*STDOUT);
	{
		no autodie;	# a child that fails is a result to check, not an error here
		system($^X, @include, @switches, $program);
	}
	open(STDOUT, '>&', $saved_out);
	open(STDERR, '>&', $saved_err);

	open(my $result, '<', $captured);
	my $output = do { local $/; <$result> };
	close($result);
	return defined($output) ? $output : '';
}

1;
