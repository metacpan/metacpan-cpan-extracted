use strict;
use warnings;

use Test::Most;
use Test::Warnings qw(warnings);

use_ok('Test::Log::Abstraction');

# prove -v exports TEST_VERBOSE=1; these tests control verbosity explicitly
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my $logger = Test::Log::Abstraction->new();
isa_ok($logger, 'Test::Log::Abstraction');

# Function-call form, as Log::Abstraction::new(...) allows
my $fn = Test::Log::Abstraction->new();
isa_ok($fn, 'Test::Log::Abstraction');

# Odd/unknown constructor arguments are ignored rather than dying
my $tolerant = Test::Log::Abstraction->new('stray-argument');
isa_ok($tolerant, 'Test::Log::Abstraction');

# Hash reference form
my $href = Test::Log::Abstraction->new({ verbose => 0 });
isa_ok($href, 'Test::Log::Abstraction');
is($href->verbose(), 0, 'verbose option from hashref');

# Clone form, as Log::Abstraction->new does on an existing logger
$logger = Test::Log::Abstraction->new(diag => 'none');
$logger->warn('before clone');
my $clone = $logger->new();
isa_ok($clone, 'Test::Log::Abstraction');
is($clone->count(), 1, 'clone copies captured messages');
$clone->warn('after clone');
is($clone->count(), 2, 'clone records independently');
is($logger->count(), 1, 'original unaffected by clone');

# TEST_VERBOSE drives the default verbosity
{
	local $ENV{'TEST_VERBOSE'} = 1;
	my $v = new_ok('Test::Log::Abstraction');
	is($v->verbose(), 1, 'TEST_VERBOSE enables verbose mode');
}

{
	local $ENV{'TEST_VERBOSE'} = 0;
	local $ENV{'VERBOSE'} = 0;
	my $v = Test::Log::Abstraction->new();
	is($v->verbose(), 0, 'verbose off by default');
}

done_testing();
