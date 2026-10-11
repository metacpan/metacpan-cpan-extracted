use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Capture qw(capture_diag);
use Test::Warnings qw(warnings);

use_ok('Test::Log::Abstraction');

# prove -v exports TEST_VERBOSE=1; these tests control verbosity explicitly
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my $logger = Test::Log::Abstraction->new();
isa_ok($logger, 'Test::Log::Abstraction');

# Function-call form, as Log::Abstraction::new(...) allows
my $fn = Test::Log::Abstraction::new();
isa_ok($fn, 'Test::Log::Abstraction');

# Function-call form with options: the first argument is an option, not a class
$fn = Test::Log::Abstraction::new(verbose => 1);
isa_ok($fn, 'Test::Log::Abstraction');
is($fn->verbose(), 1, 'function-call form keeps its first option');

$fn = Test::Log::Abstraction::new({ verbose => 1 });
is($fn->verbose(), 1, 'function-call form with a hash reference');

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

# Regression: clone overrides used to be copied in raw, so a new diag option
# was stored but never turned into a diag rule
{
	my $quiet = Test::Log::Abstraction->new(diag => 'none');
	my $loud = $quiet->new(diag => 'all');
	like(capture_diag { $loud->trace('loud trace') }, qr/loud trace/, 'clone diag override takes effect');
	is(capture_diag { $quiet->trace('quiet trace') }, '', 'original keeps its diag rule');
	throws_ok { $quiet->new(diag => 'bogus') } qr/invalid diag level 'bogus'/, 'clone validates overrides';
}

# Clones carry runtime changes, and their entries are independent copies
{
	my $original = Test::Log::Abstraction->new(diag => 'none', verbose => 0);
	$original->info('entry');
	$original->verbose(1);
	$original->level('error');
	my $clone = $original->new();
	is($clone->verbose(), 1, 'clone keeps verbose() change');
	is($clone->level(), 3, 'clone keeps level() change');
	$clone->messages()->[0]->{'message'} = 'changed';
	$clone->{'messages'}->[0]->{'message'} = 'changed';
	is($original->messages()->[0]->{'message'}, 'entry', 'clone entries are copies');
	is($original->new(verbose => 0)->verbose(), 0, 'explicit override beats runtime change');
}

# Regression: unknown options used to be copied into the object, so an
# option called 'messages' replaced the capture and the next log call died
{
	my $odd = Test::Log::Abstraction->new(messages => 'oops', diag => 'none');
	lives_ok { $odd->warn('still works') } 'option named messages cannot clobber the capture';
	is($odd->count(), 1, 'capture intact');
}

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
