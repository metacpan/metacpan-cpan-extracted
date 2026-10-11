use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Log::Abstraction;
use Capture qw(capture_diag);

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

# A lone array reference is a list of message parts, as in Log::Abstraction
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->info(['part one, ', 'part two']);
	is($logger->messages()->[0]->{'message'}, 'part one, part two', 'lone arrayref flattened');
}

# A trailing newline is removed, as in Log::Abstraction
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->warn("line\n");
	is($logger->messages()->[0]->{'message'}, 'line', 'trailing newline chomped');
}

# Fields are copied: changing the caller's hash later cannot rewrite history
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my %fields = (user => 'njh');
	$logger->info('login', \%fields);
	$fields{'user'} = 'someone else';
	is($logger->messages()->[0]->{'fields'}->{'user'}, 'njh', 'fields copied at log time');
	isnt($logger->messages()->[0]->{'fields'}, \%fields, 'fields are not the caller hash');

	$logger->info('no fields', {});
	ok(!exists($logger->messages()->[1]->{'fields'}), 'empty fields hash dropped');
}

# Regression: a self-referential structure used to recurse forever
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $loop = { name => 'loop' };
	$loop->{'self'} = $loop;
	my @list = (1);
	push @list, \@list;
	my $ok = eval { $logger->info($loop); $logger->info('list ', \@list); 1 };
	ok($ok, 'cyclic structures do not die') or diag($@);
	is($logger->messages()->[0]->{'message'}, '{name => loop, self => (cycle)}', 'hash cycle marked');
	is($logger->messages()->[1]->{'message'}, 'list [1, (cycle)]', 'array cycle marked');

	# A repeated, but not cyclic, reference is rendered in full each time
	my $shared = [2];
	$logger->info('shared ', [$shared, $shared]);
	is($logger->messages()->[2]->{'message'}, 'shared [[2], [2]]', 'shared reference is not a cycle');
}

# Objects keep their own stringification
{
	package Local::Stringy;
	use overload '""' => sub { 'stringy!' }, fallback => 1;
	sub new { return bless {}, shift }

	package main;
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->warn('object: ', Local::Stringy->new());
	is($logger->messages()->[0]->{'message'}, 'object: stringy!', 'overloaded object stringified');
}

# Logging must not change $@ or $!, which an error handler may be about to
# use.  diag => 'all' takes the printing path too.
{
	my $logger = Test::Log::Abstraction->new(diag => 'all');
	my ($at, $errno);
	capture_diag {
		eval { die "original error\n" };
		local $! = 2;
		$logger->error('handling: ', $@);
		($at, $errno) = ($@, $! + 0);
	};
	is($at, "original error\n", '$@ preserved across a log call');
	is($errno, 2, '$! preserved across a log call');
	is($logger->messages()->[0]->{'message'}, 'handling: original error', '$@ was logged');
}

done_testing();
