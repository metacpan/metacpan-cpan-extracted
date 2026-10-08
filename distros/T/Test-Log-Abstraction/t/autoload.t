use strict;
use warnings;

use Test::Most;
use Test::Log::Abstraction;
use Test::Builder;

# Capture the always-printed notice so it does not litter this test's TAP.
# failure_output($fh) returns the handle it just set, so fetch the original
# first, without an argument.
my $captured = '';
my $sink;
open($sink, '>', \$captured) or die "cannot capture: $!";
my $original = Test::Builder->new->failure_output;
Test::Builder->new->failure_output($sink);

# An unknown method - typically a typo'd level - is captured under that name
# and always noticed, never fatal
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	my $warnings;
	my $ok = do {
		local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };
		$logger->notalevel('oops');
		1;
	};

	ok($ok, 'unknown method does not die') or diag($@);
	ok(!defined($warnings) || $warnings !~ /Deep recursion/, 'no deep recursion');
	is($logger->count(), 1, 'unknown method message captured');
	is($logger->messages()->[0]->{'level'}, 'notalevel', 'captured under the called name');
	is($logger->messages()->[0]->{'message'}, 'oops', 'arguments captured');
	like($captured, qr/no method 'notalevel'/, 'notice always printed');
}

# Regression: the old Locale-Places t/lib/MyLogger.pm had
#   sub error { error(@_) }
# which recursed forever.  error(undef) must record once and return.
{
	$captured = '';
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	my $warnings;
	my $ok = do {
		local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };
		$logger->error(undef);
		1;
	};

	ok($ok, 'error(undef) does not die') or diag($@);
	ok(!defined($warnings) || $warnings !~ /Deep recursion/, 'error(undef) does not recurse');
	is($logger->count(), 1, 'error(undef) records exactly once');
	is($logger->messages()->[0]->{'level'}, 'error', 'recorded as error');
	is($logger->messages()->[0]->{'message'}, 'undef', 'message is undef');
}

# DESTROY must not record anything
{
	$captured = '';
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	undef $logger;
	is($logger, undef, 'logger destroyed');
	unlike($captured, qr/DESTROY/, 'DESTROY does not hit AUTOLOAD output');
}

Test::Builder->new->failure_output($original);
close($sink);

done_testing();
