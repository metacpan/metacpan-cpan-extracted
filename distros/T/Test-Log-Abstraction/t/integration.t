#!/usr/bin/env perl

# End-to-end tests: Test::Log::Abstraction used the way its POD says it is
# used - handed to other code as its logger, then checked.
#
# The "code under test" is Local::Importer, below: a small, realistic
# consumer that reads files, writes reports and calls an upstream service,
# logging through whatever logger it is given.  The workflows run it with
# the test double, with the real Log::Abstraction (when installed), with
# directories it is not allowed to use, and with an upstream service that is
# slow, failing or sending rubbish.  The double must capture all of it,
# exactly, without ever being the thing that breaks.
#
# This module has no optional dependencies and does no I/O of its own, so
# the optional-dependency and permission scenarios exercise the consumer's
# pipeline, with the double as its logger.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;
use Test::Returns;
use Test::Mockingbird;
use Test::Permissions qw(:revoke :guard);
use Readonly;
use Errno qw(EACCES ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use Time::HiRes ();
use Capture qw(capture_diag run_perl_script);

BEGIN { use_ok('Test::Log::Abstraction') }

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $TIMEOUT => 0.2;	# seconds the importer waits upstream
Readonly::Scalar my $LATENCY => 3;	# seconds a slow upstream would take

# Whether a deadline can interrupt a slow upstream here.  On Windows,
# Time::HiRes::alarm() is not implemented, and perlport says signals there
# cannot interrupt a blocking call anyway, so the slow-upstream cases run
# only where a timeout can actually fire
Readonly::Scalar my $CAN_TIME_OUT => ($^O ne 'MSWin32') && eval { Time::HiRes::alarm(0); 1 };
Readonly::Scalar my $BUDGET => 1.5;	# a workflow must finish within this
Readonly::Scalar my $ROWS => 3;	# lines in each fixture file
Readonly::Scalar my $PAYLOAD_PREVIEW => 64;	# characters of a bad payload logged
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

# Modules that a user might expect this one to need; none are needed
Readonly::Array my @NOT_NEEDED => qw(Log::Abstraction Object::Configure Geo::IP);

# Show a value, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

# A logger that prints nothing and ignores prove -v
sub quiet_logger {
	return new_ok($CLASS => [diag => 'none', verbose => 0, @_]);
}

# The text Perl gives for an errno, in this process's locale
sub os_text {
	local $! = shift;
	return "$!";
}

# ---------------------------------------------------------------------------
# The code under test, and its upstream service
# ---------------------------------------------------------------------------
{
	package Local::Service;

	# A stand-in for an HTTP client; each test decides what get() does
	sub new { my ($class, %args) = @_; return bless { %args }, $class }
	sub get { my ($self, $id) = @_; return $self->{'handler'}->($id) }

	package Local::Importer;

	# Written as typical application code against the Log::Abstraction API
	sub new {
		my ($class, %args) = @_;
		return bless { logger => $args{'logger'}, service => $args{'service'}, timeout => $args{'timeout'} }, $class;
	}

	sub import_file {
		my ($self, $path) = @_;
		my $log = $self->{'logger'};
		$log->debug('importing ', $path) if($log->is_debug());
		my $fh;
		if(!open($fh, '<', $path)) {
			$log->error("cannot open $path: $!");
			return;
		}
		my @rows = <$fh>;
		close($fh);
		$log->info('imported', { file => $path, rows => scalar(@rows) });
		return scalar(@rows);
	}

	sub write_report {
		my ($self, $dir, $name, $text) = @_;
		my $path = File::Spec->catfile($dir, $name);
		my $fh;
		if(!open($fh, '>', $path)) {
			$self->{'logger'}->error("cannot write $path: $!");
			return 0;
		}
		print {$fh} $text;
		close($fh);
		$self->{'logger'}->notice('report written to ', $path);
		return 1;
	}

	# Fetch and decode one record, with a deadline; never dies
	sub fetch {
		my ($self, $id) = @_;
		my $log = $self->{'logger'};
		my $raw = eval {
			local $SIG{'ALRM'} = sub { die "timeout\n" };
			Time::HiRes::alarm($self->{'timeout'}) if($self->{'timeout'});
			my $response = $self->{'service'}->get($id);
			Time::HiRes::alarm(0) if($self->{'timeout'});
			$response;
		};
		Time::HiRes::alarm(0) if($self->{'timeout'});
		if(!defined($raw)) {
			my $error = $@ || "no response\n";
			chomp($error);
			$log->warn("upstream failed for $id: $error");
			return;
		}
		my $data = eval { JSON::PP->new()->decode($raw) };
		if(ref($data) ne 'HASH') {
			$log->error("malformed payload for $id", { payload => substr($raw, 0, $PAYLOAD_PREVIEW) });
			return;
		}
		$log->info("fetched $id");
		return $data;
	}

	# Fetch many; one bad record must not stop the rest
	sub run {
		my ($self, @ids) = @_;
		my $ok = grep { defined($self->fetch($_)) } @ids;
		$self->{'logger'}->notice("run complete: $ok of ", scalar(@ids));
		return $ok;
	}
}

# Write a fixture file with $ROWS lines
sub fixture {
	my ($dir, $name) = @_;

	my $path = File::Spec->catfile($dir, $name);
	open(my $fh, '>', $path) or die "fixture $path: $!";
	print {$fh} map { "row $_\n" } 1 .. $ROWS;
	close($fh);
	return $path;
}

# An upstream that answers each id from a table of handlers
sub service {
	my %answers = @_;

	return Local::Service->new(handler => sub { my $id = shift; return $answers{$id}->() });
}

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

# Strategy: the POD says no logging backend is loaded.  Prove it in clean
# child processes, with every combination of the modules people might
# assume are needed hidden by Test::Without::Module, and the double used
# end to end in each.
subtest 'works with any combination of related modules missing' => sub {
	my $script = join(' ',
		'my $l = Test::Log::Abstraction->new(diag => q{none});',
		'$l->warn(q{w})->info(q{i}, { k => 1 });',
		'die qq{count\n} unless $l->count() == 2;',
		'die qq{loaded a backend\n} if $INC{q{Log/Abstraction.pm}};',
		'print qq{ok\n};',
	) . "\n";
	foreach my $mask (0 .. (2**@NOT_NEEDED) - 1) {
		my @hidden = map { $NOT_NEEDED[$_] } grep { $mask & (1 << $_) } 0 .. $#NOT_NEEDED;
		my @hide = @hidden ? ('-MTest::Without::Module=' . join(',', @hidden)) : ();
		my $output = run_perl_script("use Test::Log::Abstraction;\n$script", @hide);
		is($output, "ok\n", 'hidden: ' . (@hidden ? join(', ', @hidden) : 'nothing'));
	}
};

subtest 'a missing required module stops loading, with its name' => sub {
	# Required modules are required: there is no silent fallback
	foreach my $required (qw(Params::Validate::Strict Params::Get Readonly)) {
		my $output = run_perl_script("require Test::Log::Abstraction;\nprint qq{loaded\\n};\n", "-MTest::Without::Module=$required");
		(my $file = $required) =~ s{::}{/}g;
		like($output, qr/\Q$file.pm\E/, "without $required, loading fails and names it");
		unlike($output, qr/^loaded$/m, '... and does not half-load');
	}
};

# ---------------------------------------------------------------------------
# Drop-in replacement for Log::Abstraction
# ---------------------------------------------------------------------------

# Strategy: run one workflow twice, once with the real logger and once with
# the double, and compare what each recorded.  The POD promises the same
# API and the same messages() shape, so the results must match.
subtest 'same workflow, same record, as the real Log::Abstraction' => sub {
	my $have_real = eval { require Log::Abstraction; 1 };
	plan(skip_all => 'Log::Abstraction is not installed') if(!$have_real);

	my $dir = tempdir(CLEANUP => 1);
	my $good = fixture($dir, 'good.csv');
	my $upstream = service(1 => sub { '{"id":1}' }, 2 => sub { 'not json' });

	my %record;
	foreach my $which ('real', 'double') {
		my $logger = ($which eq 'real') ? Log::Abstraction->new(logger => [], level => 'debug') : quiet_logger();
		my $importer = Local::Importer->new(logger => $logger, service => $upstream, timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef));
		$importer->import_file($good);
		$importer->import_file(File::Spec->catfile($dir, 'missing.csv'));
		$importer->run(1, 2);
		$record{$which} = $logger->messages();
	}
	state_diag(record => \%record);
	is_deeply($record{'double'}, $record{'real'}, 'identical messages(), levels and fields');
	is(scalar(@{$record{'double'}}), 7, 'every step was recorded') or diag(explain($record{'double'}));
};

# Strategy: call every level both modules share with no arguments, and
# compare what each stored.  Log::Abstraction ignores warn() and above, but
# stores an empty message for the less serious levels; code that calls
# $logger->warn() with nothing must count the same under test.
subtest 'calls with no arguments are stored as the real Log::Abstraction stores them' => sub {
	my $have_real = eval { require Log::Abstraction; 1 };
	plan(skip_all => 'Log::Abstraction is not installed') if(!$have_real);

	my %record;
	foreach my $which ('real', 'double') {
		foreach my $level (qw(trace debug info notice warn error fatal critical alert emergency)) {
			my $logger = ($which eq 'real') ? Log::Abstraction->new(logger => [], level => 'trace') : quiet_logger();
			$logger->$level();
			$record{$which}->{$level} = scalar(@{$logger->messages() || []});
		}
	}
	state_diag(record => \%record);
	is_deeply($record{'double'}, $record{'real'}, 'the same levels store an entry');
};

subtest 'Object::Configure can supply the settings' => sub {
	my $have = eval { require Object::Configure; 1 };
	plan(skip_all => 'Object::Configure is not installed') if(!$have);

	# Keep Object::Configure away from the real home directory's files
	my $home = tempdir(CLEANUP => 1);
	local $ENV{'HOME'} = $home;
	local $ENV{'Test__Log__Abstraction__diag'} = 'none';
	local $ENV{'Test__Log__Abstraction__lang'} = 'fr';
	my $params = Object::Configure::configure($CLASS, { level => 'error', verbose => 0, config_dirs => [$home] });
	state_diag(params => { map { $_ => (ref($params->{$_}) || $params->{$_}) } keys %{$params} });

	my $logger = new_ok($CLASS => [$params]);
	is($logger->lang(), 'fr', 'language from the environment');
	is($logger->level(), 3, 'level from the arguments');
	my $out = capture_diag { $logger->emergency('quiet') };
	is($out, '', 'diag from the environment');
	ok(!$logger->count('logger'), 'the extra keys Object::Configure adds are ignored');
};

# ---------------------------------------------------------------------------
# Whole workflows
# ---------------------------------------------------------------------------

# Strategy: drive the importer through several steps with one logger,
# using clear() between phases and the logger's own assertions, as the
# SYNOPSIS shows
subtest 'multi-step workflow with clear() between phases' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $logger = quiet_logger();
	my $importer = Local::Importer->new(logger => $logger);

	is($importer->import_file(fixture($dir, 'a.csv')), $ROWS, 'phase 1: import');
	$logger->has_level('info', 'phase 1: info logged');
	$logger->has_level('debug', 'phase 1: debug logged, because is_debug() is on by default');
	$logger->unlike(qr/cannot/, 'phase 1: no errors');
	is_deeply($logger->messages()->[-1]->{'fields'}, { file => File::Spec->catfile($dir, 'a.csv'), rows => $ROWS }, 'phase 1: structured fields');

	$logger->clear()->level('warning');
	is($importer->import_file(File::Spec->catfile($dir, 'absent.csv')), undef, 'phase 2: missing file');
	my $no_file = os_text(ENOENT);
	$logger->like(qr/\Qcannot open\E.*\Q$no_file\E/, 'phase 2: the OS error was logged');
	is($logger->count('debug'), 0, 'phase 2: is_debug() was off, so no debug message');
	is($logger->count(), 1, 'phase 2: only the error, earlier phase forgotten');

	$logger->clear();
	$logger->empty('phase 3: a clean start');
};

# Strategy: several importers, each with its own logger configured
# differently, run interleaved; nothing may leak between them
subtest 'independent loggers in one block do not interfere' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = fixture($dir, 'shared.csv');
	my %logger = (
		quiet => quiet_logger(),
		german => quiet_logger(lang => 'de'),
		strict => quiet_logger(level => 'error'),
		loud => new_ok($CLASS => [diag => 'all', verbose => 0]),
	);
	my %importer = map { $_ => Local::Importer->new(logger => $logger{$_}) } keys %logger;

	my $printed = capture_diag {
		foreach my $round (1 .. 2) {
			$importer{$_}->import_file($file) foreach sort keys %importer;
		}
	};
	state_diag(printed => $printed);
	is($logger{'quiet'}->count(), 4, 'quiet: two imports, info and debug each');
	is($logger{'german'}->count(), 4, 'german: the same');
	is($logger{'strict'}->count(), 2, 'strict: is_debug() off, so info only');
	is($logger{'loud'}->count(), 4, 'loud: the same as quiet');
	my @lines = ($printed =~ /^\s*# (.*)$/mg);
	is(scalar(@lines), 4, 'only the loud logger printed');

	my $clone = $logger{'quiet'}->new();
	$logger{'quiet'}->clear();
	is($clone->count(), 4, 'a clone keeps its copy when the original is cleared');
	throws_ok { $logger{'german'}->like() } qr/ben\x{f6}tigt ein Muster/, 'German logger still German';
	throws_ok { $logger{'quiet'}->like() } qr/needs a pattern/, 'English logger still English';
};

# Strategy: spy on the external routines the logger hands work to, and
# check they get exactly the documented arguments
subtest 'the logger hands results to Test::Builder correctly' => sub {
	my $logger = new_ok($CLASS => [diag => 'error', verbose => 0]);
	my $ok_spy = spy 'Test::Builder::ok';
	my $diag_spy = spy 'Test::Builder::diag';
	capture_diag {
		$logger->info('not printed');
		$logger->error('printed once');
		$logger->like(qr/printed/, 'like hands its name on');
	};
	my @ok_calls = grep { defined($_->[3]) && ($_->[3] eq 'like hands its name on') } $ok_spy->();
	my @diag_calls = grep { defined($_->[2]) && ($_->[2] =~ /printed/) } $diag_spy->();
	restore_all();

	is(scalar(@ok_calls), 1, 'ok() called once for the assertion');
	ok($ok_calls[0]->[2], '... with a true result');
	is_deeply([map { $_->[2] } @diag_calls], ['printed once'], 'diag() called once, for the error only');
};

# Strategy: the consumer calls the logger; spy on the logger's public
# methods to check the consumer's calls arrive unchanged
subtest 'calls from the code under test arrive unchanged' => sub {
	my $logger = quiet_logger();
	my $error_spy = spy "${CLASS}::error";
	my $upstream = service(7 => sub { '[1,2]' });
	Local::Importer->new(logger => $logger, service => $upstream, timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef))->fetch(7);
	my @calls = $error_spy->();
	restore_all();

	is(scalar(@calls), 1, 'one error() call');
	is($calls[0]->[1], $logger, 'on our logger');
	is($calls[0]->[2], 'malformed payload for 7', 'message argument');
	is_deeply($calls[0]->[3], { payload => '[1,2]' }, 'fields argument');
	is_deeply($logger->messages()->[0], { level => 'error', message => 'malformed payload for 7', fields => { payload => '[1,2]' } }, 'and stored as documented');
};

# ---------------------------------------------------------------------------
# Permission drops
# ---------------------------------------------------------------------------

# Strategy: take away a directory's permissions with Test::Permissions; the
# importer must log the OS error through the double and carry on.  The
# probes skip these where chmod cannot really revoke access (root, Windows).
subtest 'a directory that refuses new files' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $blocked = File::Spec->catdir($dir, 'blocked');
	mkdir($blocked) or die "mkdir: $!";
	SKIP: {
		skip(why_not('create', $dir), 6) if(!can_revoke_create($dir));
		my $logger = quiet_logger();
		my $importer = Local::Importer->new(logger => $logger);
		my $denied = os_text(EACCES);

		my $written = with_revoked(create => $blocked, sub { $importer->write_report($blocked, 'r.txt', 'x') });
		is($written, 0, 'report refused');
		$logger->has_level('error', 'the refusal was logged as an error');
		$logger->like(qr/\Qcannot write\E.*\Q$denied\E/, 'with the OS reason');

		is($importer->write_report($dir, 'r.txt', 'x'), 1, 'the pipeline carries on in a usable directory');
		$logger->has_level('notice', 'and logs its success');
		is($logger->count(), 2, 'one error, one notice');
	}
};

subtest 'a directory that cannot be searched' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $hidden = File::Spec->catdir($dir, 'hidden');
	mkdir($hidden) or die "mkdir: $!";
	my $inside = fixture($hidden, 'in.csv');
	my $outside = fixture($dir, 'out.csv');
	SKIP: {
		skip(why_not('search', $dir), 5) if(!can_revoke_search($dir));
		my $logger = quiet_logger();
		my $importer = Local::Importer->new(logger => $logger);
		my $denied = os_text(EACCES);

		my @counts = with_revoked(search => $hidden, sub { (scalar($importer->import_file($inside)), scalar($importer->import_file($outside))) });
		is($counts[0], undef, 'file in the unsearchable directory not read');
		is($counts[1], $ROWS, 'the next file is still imported');
		$logger->like(qr/\Qcannot open $inside: $denied\E/, 'the refusal and the OS reason were logged');
		is($logger->count('error'), 1, 'exactly one error');
		is($logger->count('info'), 1, 'and one success');
	}
};

# ---------------------------------------------------------------------------
# Upstream sabotage
# ---------------------------------------------------------------------------

# Strategy: an upstream that is slow, throws, or returns rubbish.  The
# importer must give up quickly and log why; the double must record every
# failure exactly and never be what hangs or dies.
subtest 'slow, failing and malformed upstream' => sub {
	my $logger = quiet_logger();
	my $huge = '{' x 100_000;
	my $upstream = service(
		ok => sub { '{"id":"ok"}' },
		slow => sub { Time::HiRes::sleep($LATENCY); '{"late":1}' },
		down => sub { die "503 Service Unavailable\n" },
		empty => sub { undef },
		rubbish => sub { "\xff\xfe<html>" },
		array => sub { '[]' },
		huge => sub { $huge },
	);
	my $importer = Local::Importer->new(logger => $logger, service => $upstream, timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef));
	my $get_spy = spy 'Local::Service::get';

	my $started = Time::HiRes::time();
	my @ids = grep { $CAN_TIME_OUT || ($_ ne 'slow') } qw(ok slow down empty rubbish array huge);
	my $ok = $importer->run(@ids);
	my $elapsed = Time::HiRes::time() - $started;
	my @asked = map { $_->[2] } $get_spy->();
	restore_all();
	state_diag(messages => $logger->messages());

	is($ok, 1, 'one good record out of ' . scalar(@ids));
	ok($elapsed < $BUDGET, sprintf('finished in %.2fs: the slow upstream did not hang the run', $elapsed));
	is_deeply(\@asked, \@ids, 'every id was still tried, in order');
	SKIP: {
		skip('a deadline cannot interrupt a slow call on this platform', 1) if(!$CAN_TIME_OUT);
		$logger->like(qr/\Aupstream failed for slow: timeout\z/, 'timeout logged');
	}
	$logger->like(qr/\Aupstream failed for down: 503 Service Unavailable\z/, 'upstream error logged');
	$logger->like(qr/\Aupstream failed for empty: no response\z/, 'empty response logged');
	is($logger->count('error'), 3, 'three malformed payloads logged as errors');
	my @payloads = map { $_->{'fields'}->{'payload'} } grep { $_->{'level'} eq 'error' } @{$logger->messages()};
	is_deeply(\@payloads, ["\xff\xfe<html>", '[]', '{' x $PAYLOAD_PREVIEW], 'raw payloads kept byte for byte, as fields');
	$logger->like(qr/\Arun complete: 1 of \Q@{[ scalar(@ids) ]}\E\z/, 'the run completed');
};

subtest 'logging inside a timeout handler does not disturb it' => sub {
	plan(skip_all => 'a deadline cannot interrupt a slow call on this platform') if(!$CAN_TIME_OUT);
	my $logger = quiet_logger();
	my $upstream = service(slow => sub {
		# The upstream logs while the importer's deadline is running
		$logger->debug('waiting', { deadline => $TIMEOUT });
		$logger->like(qr/waiting/, 'assertion made while a timer runs');
		Time::HiRes::sleep($LATENCY);
		return '{}';
	});
	my $started = Time::HiRes::time();
	Local::Importer->new(logger => $logger, service => $upstream, timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef))->fetch('slow');
	ok(Time::HiRes::time() - $started < $BUDGET, 'the deadline still fired on time');
	$logger->like(qr/timeout/, 'and the timeout was logged after it');
};

subtest 'a failing output channel does not cascade' => sub {
	my $logger = new_ok($CLASS => [diag => 'all', verbose => 0]);
	my $importer = Local::Importer->new(logger => $logger, service => service(1 => sub { 'bad' }), timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef));

	# Test output that dies: the failure reaches the caller as an error,
	# but what was logged before it is kept and the logger stays usable
	mock_exception 'Test::Builder::diag' => 'TAP stream closed';
	throws_ok { $importer->fetch(1) } qr/TAP stream closed/, 'the output failure is reported, not hidden';
	restore_all();
	is($logger->count('error'), 1, 'the message was stored before printing failed');
	my $out = capture_diag { $logger->error('after') };
	like($out, qr/after/, 'printing works again once the channel is back');
};

# ---------------------------------------------------------------------------
# Return values
# ---------------------------------------------------------------------------

subtest 'documented return types across a workflow' => sub {
	my $logger = quiet_logger();
	my $importer = Local::Importer->new(logger => $logger, service => service(1 => sub { '{"a":1}' }), timeout => ($CAN_TIME_OUT ? $TIMEOUT : undef));
	returns_ok($importer->fetch(1), { type => 'hashref' }, 'the consumer got its data');
	returns_ok($logger->messages(), { type => 'arrayref' }, 'messages()');
	returns_ok($logger->count(), { type => 'integer', min => 0 }, 'count()');
	returns_ok($logger->level(), { type => 'integer', min => 0, max => 7 }, 'level()');
	returns_ok($logger->is_debug(), { type => 'boolean' }, 'is_debug()');
	returns_ok($logger->lang(), { type => 'string', matches => qr/\A[a-z]{2,3}\z/ }, 'lang()');
	returns_ok($logger->flush(), { type => 'object', isa => $CLASS }, 'flush()');
	returns_ok($logger->clear(), { type => 'object', isa => $CLASS }, 'clear()');
};

done_testing();
