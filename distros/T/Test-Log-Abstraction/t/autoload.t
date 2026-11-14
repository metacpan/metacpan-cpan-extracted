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

# The notice repeats the caller's method name, which can be any string:
# like every error, it must not add lines, send terminal escapes, or be huge
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $name = "bad\nname\e[2J" . ('z' x 300);
	my $out = capture_diag { $logger->$name('x') };

	is(scalar($out =~ tr/\n//), 1, 'notice for a name with a newline is one line');
	unlike($out, qr/\e/, 'no terminal escape sequence is printed');
	like($out, qr/no method 'bad\\x0Aname\\x1B\[2Jz+\.\.\.'/, 'control characters escaped, long name cut');
	ok(length($out) < 300, 'notice is cut short');
	is($logger->messages()->[0]->{'level'}, lc($name), 'the name is still captured as it was called');
}

# An unknown class method croaks: there is no capture to record it in
{
	throws_ok { Test::Log::Abstraction->notalevel('x') }
		qr/notalevel\(\) must be called on an object, not on the class at \Q${\ __FILE__}\E/,
		'unknown class method croaks at the caller';
}

# Regression (0.002.2): carp, croak, get_params, validate_strict, qv and
# Readonly were imported into the package, so they were methods too.
# $logger->croak('x') died with a raw HASH(0x...) message and
# $logger->carp('x') warned, instead of reaching AUTOLOAD.  Now every name
# reaches AUTOLOAD, as a misspelt level would, and nothing leaks.
{
	my @imported = qw(carp croak confess cluck get_params validate_strict qv Readonly);
	foreach my $name (@imported) {
		ok(!Test::Log::Abstraction->can($name), "$name is not a method");
		my $logger = Test::Log::Abstraction->new(diag => 'none', verbose => 0);
		my $warnings = '';
		my $ok;
		my $out = capture_diag {
			local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };
			$ok = eval { $logger->$name('x'); 1 };
		};
		ok($ok, "$name: does not die") or diag($@);
		is($warnings, '', "$name: does not warn");
		is_deeply($logger->messages(), [{ level => lc($name), message => 'x' }], "$name: captured, as an unknown method");
		like($out, qr/no method '\Q$name\E'/, "$name: noticed");
	}

	# Every sub in the package is either private or a documented method,
	# so a new import cannot quietly become a method again
	my %public = map { $_ => 1 } qw(
		new AUTOLOAD DESTROY messages clear count like unlike has_level empty
		verbose level flush reopen lang i18n
		trace debug info informational notice warn warning error err fatal
		critical crit alert emergency emerg panic
		is_trace is_debug is_info is_notice is_warn is_error is_critical is_alert is_emergency
	);
	no strict 'refs';	## no critic (ProhibitNoStrict)
	my @subs = grep { !/^_/ && defined(&{"Test::Log::Abstraction::$_"}) } keys %Test::Log::Abstraction::;
	is_deeply([ sort grep { !$public{$_} } @subs ], [], 'no sub in the package but the documented methods');
}

done_testing();
