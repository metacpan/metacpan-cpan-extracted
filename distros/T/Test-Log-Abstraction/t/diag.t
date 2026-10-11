use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Log::Abstraction;
use Capture qw(capture_diag);

# prove -v exports TEST_VERBOSE=1, which would override every diag rule
# under test here; these tests control verbosity explicitly.
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

# Default: warning and above print, below does not
{
	my $logger = Test::Log::Abstraction->new();
	my $out = capture_diag {
		$logger->debug('quiet debug');
		$logger->info('quiet info');
		$logger->notice('quiet notice');
		$logger->warn('loud warning');
		$logger->error('loud error');
		$logger->critical('loud critical');
	};
	unlike($out, qr/quiet debug/, 'debug not printed by default');
	unlike($out, qr/quiet notice/, 'notice not printed by default');
	like($out, qr/loud warning/, 'warn printed by default');
	like($out, qr/loud error/, 'error printed by default');
	like($out, qr/loud critical/, 'critical printed by default');
	is($logger->count(), 6, 'everything captured whether printed or not');
}

# diag => 'none': nothing prints unless verbose
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $out = capture_diag {
		$logger->error('silent error');
		$logger->emergency('silent emergency');
	};
	is($out, '', "diag => 'none' prints nothing");

	$logger->verbose(1);
	$out = capture_diag { $logger->error('now verbose') };
	like($out, qr/now verbose/, 'verbose overrides the diag rule');
}

# diag => 'all': everything prints
{
	my $logger = Test::Log::Abstraction->new(diag => 'all');
	my $out = capture_diag {
		$logger->trace('all trace');
		$logger->debug('all debug');
		$logger->info('all info');
	};
	like($out, qr/all trace/, 'trace printed with diag all');
	like($out, qr/all debug/, 'debug printed with diag all');
	like($out, qr/all info/, 'info printed with diag all');
}

# diag => 'error': threshold - error and more severe print, warn does not
{
	my $logger = Test::Log::Abstraction->new(diag => 'error');
	my $out = capture_diag {
		$logger->warn('below threshold');
		$logger->error('at threshold');
		$logger->alert('above threshold');
	};
	unlike($out, qr/below threshold/, 'warn below the error threshold is hidden');
	like($out, qr/at threshold/, 'error at threshold prints');
	like($out, qr/above threshold/, 'alert above threshold prints');
}

# diag => [levels]: exactly those levels print
{
	my $logger = Test::Log::Abstraction->new(diag => [qw(info crit)]);
	my $out = capture_diag {
		$logger->info('wanted info');
		$logger->warn('unwanted warn');
		$logger->crit('wanted crit');
		$logger->debug('unwanted debug');
	};
	like($out, qr/wanted info/, 'listed level prints');
	like($out, qr/wanted crit/, 'second listed level prints');
	unlike($out, qr/unwanted warn/, 'unlisted level stays quiet');
	unlike($out, qr/unwanted debug/, 'unlisted level stays quiet');
}

# Invalid diag options croak at construction time
{
	throws_ok { Test::Log::Abstraction->new(diag => 'bogus') } qr/invalid diag level 'bogus'/,
		'invalid level croaks';
	throws_ok { Test::Log::Abstraction->new(diag => ['info', 'bogus2']) } qr/invalid diag level 'bogus2'/,
		'invalid level in arrayref croaks';
	throws_ok { Test::Log::Abstraction->new(diag => {}) } qr/diag must be/,
		'hashref diag croaks';
}

done_testing();
