use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Log::Abstraction;
use Capture qw(capture_diag);

# prove -v exports TEST_VERBOSE=1, which would print every message
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

# An unknown method - typically a typo'd level - is captured under that name
# and always noticed, never fatal
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	my $warnings;
	my $ok;
	my $out = capture_diag {
		local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };
		$ok = eval { $logger->notalevel('oops'); 1 };
	};

	ok($ok, 'unknown method does not die') or diag($@);
	ok(!defined($warnings) || $warnings !~ /Deep recursion/, 'no deep recursion');
	is($logger->count(), 1, 'unknown method message captured');
	is($logger->messages()->[0]->{'level'}, 'notalevel', 'captured under the called name');
	is($logger->messages()->[0]->{'message'}, 'oops', 'arguments captured');
	like($out, qr/no method 'notalevel'/, "notice always printed, even with diag => 'none'");
	is(scalar(capture_diag { is($logger->typo('x'), $logger, 'AUTOLOAD returns $self') } =~ tr/\n//), 1, 'one notice per call');
}

# Regression: the old Locale-Places t/lib/MyLogger.pm had
#   sub error { error(@_) }
# which recursed forever.  error(undef) must record once and return.
{
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

# DESTROY is a real method, so destruction never reaches AUTOLOAD.  Calling
# it directly proves that: through AUTOLOAD it would record and print.
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $out = capture_diag { $logger->DESTROY() };
	is($out, '', 'DESTROY prints nothing');
	is($logger->count(), 0, 'DESTROY records nothing');
	ok(defined(&Test::Log::Abstraction::DESTROY), 'DESTROY is defined');
}

# An unknown class method croaks: there is no capture to record it in
{
	throws_ok { Test::Log::Abstraction->notalevel('x') }
		qr/notalevel\(\) must be called on an object, not on the class at \Q${\ __FILE__}\E/,
		'unknown class method croaks at the caller';
}

done_testing();
