use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings qw(warning);
use Test::Log::Abstraction;
use Capture qw(capture_diag);

# The parts of Log::Abstraction's API that are not log levels.  Before they
# existed, a call such as $logger->level('debug') was captured as a log
# message at level 'level' and printed a "no method" notice.

$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my @PREDICATES = qw(trace debug info notice warn error critical alert emergency);

subtest 'level() and is_*() follow the threshold' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	is($logger->level(), 7, 'default threshold is trace');
	ok($logger->can("is_$_"), "is_$_ exists") foreach @PREDICATES;
	is($logger->$_(), 1, "$_ enabled by default") foreach map { "is_$_" } @PREDICATES;

	is($logger->level('WARNING'), $logger, 'setter returns $self, case-insensitively');
	is($logger->level(), 4, 'threshold is warning');
	is($logger->is_warn(), 1, 'is_warn at threshold');
	is($logger->is_error(), 1, 'is_error above threshold');
	is($logger->is_notice(), 0, 'is_notice below threshold');
	is($logger->is_debug(), 0, 'is_debug below threshold');

	$logger->debug('still captured');
	is($logger->count('debug'), 1, 'threshold does not filter capture');
	is($logger->count(), 1, 'level() itself is not captured');
};

subtest 'level() rejects unknown names as Log::Abstraction does' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $result = 'unset';
	like(warning { $result = $logger->level('loud') }, qr/invalid syslog level 'loud' at \Q${\ __FILE__}\E/, 'invalid level carps at the caller');
	is($result, undef, 'invalid level returns undef');
	is($logger->level(), 7, 'threshold unchanged');
};

subtest 'level option' => sub {
	is(Test::Log::Abstraction->new(level => 'error')->level(), 3, 'level option sets threshold');
	is(Test::Log::Abstraction->new(level => 'Error')->is_warn(), 0, 'level option is case-insensitive');
	throws_ok { Test::Log::Abstraction->new(level => 'loud') } qr/invalid syslog level 'loud'/, 'invalid level option croaks';
};

subtest 'flush() is a no-op that chains' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	is($logger->flush(), $logger, 'flush returns $self');
	is($logger->count(), 0, 'flush is not captured');
};

subtest 'reopen() is a no-op that chains, as Log::Abstraction 0.41 has it' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $out = capture_diag { is($logger->reopen(), $logger, 'reopen returns $self') };
	is($logger->count(), 0, 'reopen is not captured');
	is($out, '', 'and no "no method" notice is printed');
};

subtest 'class-method calls croak clearly' => sub {
	my $class = 'Test::Log::Abstraction';
	foreach my $method (qw(warn trace is_debug messages clear count empty verbose level lang flush reopen)) {
		throws_ok { $class->$method() } qr/\Q$method\E\(\) must be called on an object/, "$method on the class croaks";
	}
	throws_ok { $class->like(qr/x/) } qr/like\(\) must be called on an object/, 'like on the class croaks';
	throws_ok { $class->has_level('warn') } qr/has_level\(\) must be called on an object/, 'has_level on the class croaks';
};

subtest 'constructor option validation' => sub {
	throws_ok { Test::Log::Abstraction->new(country => 'GBR') } qr/invalid argument: .*country/, 'three-letter country croaks';
	throws_ok { Test::Log::Abstraction->new(i18n => 'x') } qr/invalid argument: .*i18n/, 'non-hash i18n croaks';
	throws_ok { Test::Log::Abstraction->new(lang => '!!') } qr/invalid argument: .*lang/, 'malformed lang croaks';
	lives_ok { Test::Log::Abstraction->new(verbose => undef, unknown => 1) } 'undef verbose and unknown options are accepted';
	is(Test::Log::Abstraction->new(verbose => 'yes')->verbose(), 1, 'verbose is normalised to 1');
};

subtest '%config supplies defaults' => sub {
	local $Test::Log::Abstraction::config{'diag'} = 'none';
	my $logger = Test::Log::Abstraction->new();
	is(capture_diag { $logger->emergency('quiet') }, '', "configured diag => 'none' applies");
	local $Test::Log::Abstraction::config{'level'} = 'error';
	is(Test::Log::Abstraction->new()->level(), 3, 'configured level applies');
};

# Internal routines are a convention (a leading underscore), not enforced;
# what matters is that a subclass can use the methods meant for it
subtest 'subclasses' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	# A subclass may use the methods for subclasses
	{
		package Local::Subclass;
		our @ISA = ('Test::Log::Abstraction');
		sub greet { return $_[0]->i18n('no_method', { method => 'greet' }) }
	}
	like(Local::Subclass->new()->greet(), qr/Local::Subclass: no method 'greet'/, 'subclass can call i18n');

	lives_ok { $logger->warn('fine')->like(qr/fine/, 'public API works') } 'public API unaffected';
};

done_testing();
