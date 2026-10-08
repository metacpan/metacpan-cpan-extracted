use strict;
use warnings;

use Test::Most;
use Test::Log::Abstraction;

# prove -v exports TEST_VERBOSE=1; these tests control verbosity explicitly
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

# Multiple arguments are concatenated
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->warn('the ', 'widget ', 'broke');
	is($logger->messages()->[0]->{'message'}, 'the widget broke', 'arguments concatenated');
}

# Undef arguments become 'undef' and never warn
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };
		$logger->error(undef);
	}
	is(scalar @warnings, 0, 'no warnings logging undef');
	is($logger->messages()->[0]->{'message'}, 'undef', 'undef rendered as the string undef');
}

# A lone hash reference is the message, rendered as key => value pairs
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->error({ error => 'cannot open file', file => '/tmp/x' });
	my $message = $logger->messages()->[0]->{'message'};
	is($message, '{error => cannot open file, file => /tmp/x}', 'lone hashref rendered readably');
	like($message, qr/cannot open file/, 'contents are matchable');
	ok(!defined($logger->messages()->[0]->{'fields'}), 'lone hashref is not fields');
}

# A trailing hash with two or more arguments is structured fields
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->info('user logged in', { user => 'njh', pid => 123 });
	my $entry = $logger->messages()->[0];
	is($entry->{'message'}, 'user logged in', 'message is the leading args');
	is_deeply($entry->{'fields'}, { user => 'njh', pid => 123 }, 'fields captured');
}

# Nested structures stringify without warnings
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };
		$logger->warn('values: ', [1, undef, { a => 2 }]);
	}
	is(scalar @warnings, 0, 'no warnings stringifying nested refs');
	is($logger->messages()->[0]->{'message'}, 'values: [1, undef, {a => 2}]', 'nested structure rendered');
}

# An empty log call still records rather than dying
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $ok = eval { $logger->trace(); 1 };
	ok($ok, 'level method with no arguments does not die') or diag($@);
	is($logger->count(), 1, 'empty call recorded');
}

# An empty hashref message renders as {}
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->debug({});
	is($logger->messages()->[0]->{'message'}, '{}', 'empty hashref rendered');
}

done_testing();
