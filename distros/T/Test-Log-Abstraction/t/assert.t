use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Log::Abstraction;

# Assertions are real TAP tests: a failure must be reported at the line of
# the test file that made the assertion, not inside the module, and must
# say what was captured.  Test::Builder::Tester checks the exact output.

$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my $class = 'Test::Log::Abstraction';

# like() failing lists what was captured
{
	my $logger = $class->new(diag => 'none');
	$logger->warn('the widget broke');
	$logger->info('second');

	test_out('not ok 1 - finds updated');
	test_fail(+3);
	test_diag("$class: 2 messages were captured:");
	test_diag('    [warn] the widget broke', '    [info] second');
	$logger->like(qr/updated/, 'finds updated');
	test_test('like() failure is reported at the caller with the capture listed');
}

# unlike() failing lists only the messages that matched
{
	my $logger = $class->new(diag => 'none');
	$logger->warn('fatal: one');
	$logger->info('fine');

	test_out('not ok 1 - nothing fatal');
	test_fail(+2);
	test_diag("$class: 1 message matched:", '    [warn] fatal: one');
	$logger->unlike(qr/fatal/, 'nothing fatal');
	test_test('unlike() failure lists the matches, with the singular form');
}

# empty() and has_level() on an empty logger use the zero form
{
	my $logger = $class->new(diag => 'none');

	test_out('not ok 1 - has an error');
	test_fail(+2);
	test_diag("$class: no messages were captured");
	$logger->has_level('error', 'has an error');
	test_test('has_level() failure uses the zero form');
}

# A long capture is summarised rather than flooding the output
{
	my $logger = $class->new(diag => 'none');
	$logger->info("line $_") foreach 1 .. 25;

	test_out('not ok 1 - nothing logged');
	test_fail(+4);
	test_diag("$class: 25 messages were captured:");
	test_diag(map { "    [info] line $_" } 1 .. 20);
	test_diag('    ... and 5 more');
	$logger->empty('nothing logged');
	test_test('empty() failure lists 20 entries and summarises the rest');
}

# Passing assertions print nothing extra
{
	my $logger = $class->new(diag => 'none');
	$logger->error('boom');

	test_out('ok 1 - has an error', 'ok 2 - boom', 'ok 3 - no fizz');
	$logger->has_level('error', 'has an error');
	$logger->like(qr/boom/, 'boom');
	$logger->unlike(qr/fizz/, 'no fizz');
	test_test('passing assertions are quiet');
}

done_testing();
