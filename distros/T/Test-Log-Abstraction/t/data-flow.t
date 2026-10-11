#!/usr/bin/env perl

# Data-flow tests: each piece of data the module holds is followed from
# where it is defined (D), through every use (U), to where it is killed (K).
#
#   Data                  D                          U                               K
#   --------------------  -------------------------  ------------------------------  -------------------------
#   options (diag, i18n)  new(): copied from caller  _diag_rule, i18n, _template,    the logger is freed
#                                                    every clone
#   entry                 level method (_entry)      messages, count, like, unlike,  clear(), or the logger
#                                                    has_level, empty, _explain      is freed
#   fields                level method: copied       messages                        as entry
#   verbose, level        new() from options/ENV/     _diags, is_*, clones            setters overwrite
#                         %config; setters
#   lang                  new() (_resolve_lang)      every message the module makes  the logger is freed
#   diag rule             new() (_diag_rule)         _diags                          the logger is freed
#   output handle         Test::Builder (borrowed)   _emit: layers read, diag()      never: not ours to close
#
# Data-flow anomalies found while mapping these chains, all now fixed:
# the caller's diag list and i18n tables were kept by reference, so the
# caller could change a logger after creating it (a scope leak); _object
# computed its error class on every call but used it only on failure (D~);
# level() overwrote its getter value unread on the setter path (DD); and
# _resolve_lang, _plural and _format computed values some paths never
# read (D~).
#
# The module opens no files or sockets.  The only resource it touches is
# the output handle it borrows from Test::Builder, so the resource tests
# prove it never opens, closes or changes a handle - including while the
# file behind that handle loses its permissions part way through.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;
use Test::Mockingbird;
use Test::Returns;
use Test::Permissions qw(:revoke :guard);
use Readonly;
use Errno qw(EACCES EPERM ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(weaken refaddr);
use Capture qw(capture_diag);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $SENTINEL => 'caller value';
Readonly::Scalar my $ROUNDS => 2_000;	# operations in the handle-leak test
Readonly::Scalar my $FD_DIRECTORY => (-d '/proc/self/fd') ? '/proc/self/fd' : (-d '/dev/fd') ? '/dev/fd' : undef;
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

# Show a value, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

# How many file descriptors this process has open, or undef if the system
# cannot say
sub open_descriptors {
	return if(!defined($FD_DIRECTORY));
	opendir(my $listing, $FD_DIRECTORY) or return;
	my $count = grep { /\A\d+\z/ } readdir($listing);
	closedir($listing);
	return $count - 1;	# not counting the listing itself
}

# Run code with Test::Builder's diagnostics going to a file, and return
# what was written there.  The handle is opened and closed here, by the
# test, as the module must never do either itself.
sub with_output_file {
	my ($path, $code) = @_;

	my $tb = Test::Builder->new();
	my @original = ($tb->failure_output(), $tb->todo_output());
	open(my $out, '>>', $path) or die "open $path: $!";
	$out->autoflush(1);
	$tb->failure_output($out);
	$tb->todo_output($out);
	my $ok = eval { $code->($out); 1 };
	my $error = $@;
	$tb->failure_output($original[0]);
	$tb->todo_output($original[1]);
	close($out) or die "close $path: $!";
	die $error if(!$ok);

	open(my $in, '<', $path) or die "read $path: $!";
	my $written = do { local $/; <$in> };
	close($in);
	return $written;
}

# ===========================================================================
# Options: D in the caller, copied by new(), used by every clone
# ===========================================================================

# Strategy: define each option structure in the caller, create a logger,
# then redefine the caller's structure.  A use after that (a clone, a
# message) must still see the value at the time of new().
subtest 'option structures are copied, not shared with the caller' => sub {
	my @diag = ('error');
	my %i18n = (en => { no_method => 'first %{method}s', nested => { other => 'deep first' } });
	my %options = (diag => \@diag, i18n => \%i18n, verbose => 0);
	my $logger = $CLASS->new(\%options);

	# Redefine everything the caller still holds
	push @diag, 'bogus';
	$i18n{'en'}{'no_method'} = 'changed %{method}s';
	$i18n{'en'}{'nested'}{'other'} = 'deep changed';
	$i18n{'de'} = { no_method => 'neu' };
	$options{'diag'} = 'all';

	my $clone;
	lives_ok { $clone = $logger->new() } 'a clone after the caller changed the diag list';
	my $out = capture_diag { $clone->error('x'); $clone->info('y') };
	like($out, qr/x/, '... prints errors, as diag => [error] says');
	unlike($out, qr/y/, '... and not info: the caller\'s later push was not seen');

	$out = capture_diag { $logger->wran('z') };
	like($out, qr/first wran/, 'i18n text is the value at new(), not the caller\'s later change');
	is($logger->lang(), 'en', 'a language added to the caller\'s table later is not used');
	state_diag(options_after => $logger->{'options'});
};

subtest 'each clone owns its options' => sub {
	my $original = quiet(i18n => { en => { no_method => 'original %{method}s' } });
	my $clone = $original->new();
	isnt($clone->{'options'}->{'i18n'}, $original->{'options'}->{'i18n'}, 'different tables');

	# Change the original's own copy; the clone must not see it
	$original->{'options'}->{'i18n'}->{'en'}->{'no_method'} = 'tampered %{method}s';
	my $out = capture_diag { $clone->wran('x') };
	like($out, qr/original wran/, 'the clone keeps its own text');
};

subtest 'a cyclic option table is copied without its cycle, and freed' => sub {
	my %cyclic = (en => {});
	$cyclic{'en'}{'captured'} = { other => undef };
	$cyclic{'en'}{'captured'}{'other'} = $cyclic{'en'}{'captured'};
	$cyclic{'self'} = \%cyclic;

	my $weak;
	{
		my $logger = quiet(i18n => \%cyclic);
		memory_cycle_free($logger->{'options'}->{'i18n'});
		$weak = $logger;
		weaken($weak);
	}
	ok(!defined($weak), 'the logger is freed: the copy did not keep a cycle');
	delete $cyclic{'self'};
	delete $cyclic{'en'}{'captured'}{'other'};
};

# No reference in a structure leads back to a structure above it
sub memory_cycle_free {
	my ($value, $path) = (@_, {});

	my $type = ref($value);
	if(($type eq 'HASH') || ($type eq 'ARRAY')) {
		my $address = refaddr($value);
		if($path->{$address}) {
			fail('cycle found in the copy');
			return;
		}
		local $path->{$address} = 1;
		memory_cycle_free($_, $path) foreach (($type eq 'HASH') ? values(%{$value}) : @{$value});
	}
	pass('no cycle in the copy') if(!%{$path});
	return;
}

# ===========================================================================
# Entries: D by a level method, U by every reader, K by clear()
# ===========================================================================

subtest 'an entry is fixed at the moment it is logged' => sub {
	my $logger = quiet();
	my $text = 'before';
	my %fields = (user => 'alice', list => [1]);
	$logger->info($text, \%fields);

	# Redefine everything the caller passed
	$text = 'after';
	$fields{'user'} = 'mallory';
	$fields{'added'} = 1;

	my $entry = $logger->messages()->[0];
	is($entry->{'message'}, 'before', 'message text is a copy');
	is($entry->{'fields'}->{'user'}, 'alice', 'field values are copies');
	ok(!exists($entry->{'fields'}->{'added'}), 'keys added later do not appear');
	push @{$fields{'list'}}, 2;
	is_deeply($entry->{'fields'}->{'list'}, [1, 2], 'but nested references are shared, as COMMON PITFALLS documents');
};

{
	package Local::Counter;
	# A tied scalar that counts its reads and gives a new value each time
	sub TIESCALAR { my ($class, $count) = @_; return bless { count => $count }, $class }
	sub FETCH { my $self = shift; ${$self->{'count'}}++; return 'read ' . ${$self->{'count'}} }
}

subtest 'each argument is read exactly once' => sub {
	my $reads = 0;
	tie my $volatile, 'Local::Counter', \$reads;
	my $logger = quiet();
	$logger->info($volatile, ' and ', $volatile);
	is($reads, 2, 'two arguments, two reads: none read twice');
	is($logger->messages()->[0]->{'message'}, 'read 1 and read 2', 'the message is built from those reads');
	untie $volatile;
};

subtest 'every reader sees the same entries, in order' => sub {
	my $logger = quiet();
	$logger->warn('one');
	$logger->error('two', { k => 1 });
	$logger->warn('three');

	my @texts = map { $_->{'message'} } @{$logger->messages()};
	is_deeply(\@texts, ['one', 'two', 'three'], 'messages(): order of definition');
	is($logger->count(), 3, 'count(): all');
	is($logger->count('warn'), 2, 'count(level): the same entries');
	ok($logger->like(qr/two/, 'like(): the same entries'), 'like');
	ok($logger->has_level('error', 'has_level(): the same entries'), 'has_level');
	returns_ok($logger->messages(), { type => 'arrayref' }, 'messages() type');
	returns_ok($logger->count(), { type => 'integer', min => 0 }, 'count() type');
};

subtest 'clear() kills the entries; a held copy keeps its own' => sub {
	my $logger = quiet();
	$logger->info('m', { big => [1 .. 10] });
	my $fields = $logger->messages()->[0]->{'fields'};
	my $held = $logger->messages();
	my $weak_fields = $fields;
	weaken($weak_fields);
	undef $fields;

	returns_ok($logger->clear(), { type => 'object', isa => $CLASS }, 'clear() returns the logger');
	is($logger->count(), 0, 'nothing left to count');
	ok(defined($weak_fields), 'an entry is still alive while the caller holds a messages() copy');
	undef $held;
	ok(!defined($weak_fields), 'and freed as soon as that copy goes');
};

subtest 'the logger and everything in it are freed with it' => sub {
	my ($weak_logger, $weak_entry, $weak_options);
	{
		my $logger = quiet(i18n => { en => { k => 'v' } }, diag => ['error']);
		$logger->info('m', { k => 1 });
		$weak_logger = $logger;
		$weak_entry = $logger->{'messages'}->[0];
		$weak_options = $logger->{'options'};
		weaken($_) foreach ($weak_logger, $weak_entry, $weak_options);
	}
	ok(!defined($weak_logger), 'logger freed');
	ok(!defined($weak_entry), 'its entries freed');
	ok(!defined($weak_options), 'its options freed');
};

# ===========================================================================
# Settings: D at new() (a snapshot), U by printing and is_*, D again by setters
# ===========================================================================

# Strategy: the inputs new() reads from outside - %config, %ENV - are read
# once.  Changing them afterwards must not change an existing logger.
subtest 'settings are a snapshot of %config and %ENV at new()' => sub {
	local $ENV{'TEST_VERBOSE'} = 0;
	local $ENV{'VERBOSE'} = 0;
	local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
	my $logger = $CLASS->new(lang => 'auto');
	my %before = (verbose => $logger->verbose(), lang => $logger->lang(), level => $logger->level());

	local $Test::Log::Abstraction::config{'diag'} = 'all';
	local $Test::Log::Abstraction::config{'level'} = 'error';
	local $ENV{'TEST_VERBOSE'} = 1;
	local $ENV{'LC_ALL'} = 'fr_FR.UTF-8';

	is_deeply({ verbose => $logger->verbose(), lang => $logger->lang(), level => $logger->level() }, \%before, 'verbose, lang and level unchanged');
	is(capture_diag { $logger->info('quiet') }, '', 'the diag rule unchanged too');
	is($CLASS->new()->level(), 3, 'a new logger does see the new %config');
};

subtest 'setters redefine, and clones inherit the redefinition' => sub {
	my $logger = quiet();
	is($logger->verbose(1), 1, 'verbose redefined');
	is($logger->level('alert'), $logger, 'level redefined');
	my $clone = $logger->new();
	is($clone->verbose(), 1, 'the clone uses the redefined verbose');
	is($clone->level(), 1, 'and the redefined level');
	$clone->verbose(0);
	is($logger->verbose(), 1, 'redefining the clone does not reach back');
	my $result;
	warning_like { $result = $logger->level('bogus') } qr/invalid syslog level/, 'a rejected redefinition';
	is($logger->level(), 1, 'leaves the old value');
};

# ===========================================================================
# Global variables: read where documented, never written
# ===========================================================================

# Strategy: perl's punctuation variables are hidden inputs to string and
# I/O operations.  Set every one that could change a message, then check
# both the stored and the printed text are unaffected, and that none of
# them is changed.
subtest 'punctuation variables do not leak into data' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my $printed;
	{
		local $/ = undef;
		local $\ = 'RECORD-SEPARATOR';
		local $, = 'FIELD-SEPARATOR';
		local $" = 'LIST-SEPARATOR';
		local $; = 'SUBSCRIPT-SEPARATOR';
		local $_ = $SENTINEL;
		$@ = $SENTINEL;
		$! = ENOENT;
		$printed = capture_diag { $logger->info("a\n", 'b', ['c', 'd'], { e => 'f' }, 'g') };
		is($_, $SENTINEL, '$_ unchanged');
		is($@, $SENTINEL, '$@ unchanged');
		is($! + 0, ENOENT, '$! unchanged');
		is($/, undef, '$/ unchanged');
	}
	is($logger->messages()->[0]->{'message'}, "a\nb[c, d]{e => f}g", 'stored text uses none of the separators');
	(my $clean = $printed) =~ s/^[ ]+#/#/mg;
	is($clean, "# a\n# b[c, d]{e => f}g\n", 'printed text uses none of them either');
};

# ===========================================================================
# The borrowed output handle: never opened, closed or changed
# ===========================================================================

subtest 'no file descriptors are opened or left behind' => sub {
	plan(skip_all => 'this system cannot list open file descriptors') if(!defined(open_descriptors()));
	my $before = open_descriptors();
	for my $round (1 .. $ROUNDS) {
		my $logger = $CLASS->new(diag => (($round % 2) ? 'all' : 'none'), verbose => 0, lang => 'zh');
		capture_diag {
			$logger->warn('w', { r => $round })->wran('x');
			$logger->new()->clear();
		};
		eval { $logger->like() };	# a croak must not leave a handle behind either
	}
	my $after = open_descriptors();
	state_diag(descriptors => { before => $before, after => $after });
	is($after, $before, "$ROUNDS rounds of logging, clones and errors: the same descriptors open");
};

subtest 'the borrowed handle is used, not owned' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'tap.out');
	my %seen;
	my $written = with_output_file($path, sub {
		my $handle = shift;
		my @layers = PerlIO::get_layers($handle);
		my $fileno = fileno($handle);
		my $logger = $CLASS->new(diag => 'all', verbose => 0);
		$logger->error("caf\x{e9} \x{2603}")->wran('x');
		%seen = (open => defined(fileno($handle)), same_fd => (fileno($handle) == $fileno), layers => [PerlIO::get_layers($handle)], layers_before => \@layers);
	});
	ok($seen{'open'}, 'still open after logging');
	ok($seen{'same_fd'}, 'still the same descriptor');
	is_deeply($seen{'layers'}, $seen{'layers_before'}, 'its layers were not changed (no binmode)');
	like($written, qr/^\s*# caf\xc3\xa9 \xe2\x98\x83$/m, 'what was written went through it, encoded');
};

# Strategy: take permissions away from the output file and its directory
# while the handle is open.  Writes through an open descriptor still work;
# what matters is that the module never tries to reopen, create or close
# anything, so it keeps working and leaves nothing open.
subtest 'permissions revoked part way through' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'tap.out');
	open(my $touch, '>', $path) or die "create: $!";
	close($touch);

	foreach my $kind ('write', 'create') {
		SKIP: {
			my $possible = ($kind eq 'write') ? can_revoke_write($dir) : can_revoke_create($dir);
			skip(why_not($kind, $dir), 3) if(!$possible);
			my $target = ($kind eq 'write') ? $path : $dir;
			my $before = open_descriptors();
			my $logger = $CLASS->new(diag => 'all', verbose => 0);
			my $written = with_output_file($path, sub {
				$logger->error("before revoking $kind");
				with_revoked($kind => $target, sub {
					$logger->error("while $kind is revoked")->wran('x');
					$logger->like(qr/revoked/, "assertion while $kind is revoked");
				});
				$logger->error("after restoring $kind");
			});
			like($written, qr/before revoking $kind.*while $kind is revoked.*after restoring $kind/s, "$kind revoked: every message written, in order");
			is($logger->count(), 4, "$kind revoked: every message stored");
			is(open_descriptors(), $before, "$kind revoked: no descriptor left open") if(defined($before));
			pass('descriptor count not available') if(!defined($before));
		}
	}
};

# Strategy: make the write itself fail with EACCES or EPERM, as a locked
# file would; the entry must already be stored, the error must not leak,
# and no handle may be left behind
subtest 'writes that fail with EACCES or EPERM' => sub {
	my $before = open_descriptors();
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my @states;
	foreach my $errno (EACCES, EPERM) {
		my $stored_at_write;
		mock 'Test::Builder::diag' => sub { $stored_at_write = $logger->count(); $! = $errno; return 0 };
		$! = 0;
		my $returned = $logger->error("denied $errno");
		push @states, { errno => $errno, after => $! + 0, stored_at_write => $stored_at_write, returned => $returned };
		restore_all();
	}
	foreach my $state (@states) {
		is($state->{'after'}, 0, "errno $state->{'errno'}: not leaked into \$!");
		ok($state->{'stored_at_write'}, "errno $state->{'errno'}: the entry was stored before the write was tried");
		is($state->{'returned'}, $logger, "errno $state->{'errno'}: the logger is still returned");
	}
	is($logger->count(), 2, 'both entries kept');
	is(open_descriptors(), $before, 'no descriptor left open') if(defined($before));
};

subtest 'a missing or closed output handle' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my @printed;
	open(my $closed, '<', File::Spec->devnull()) or die "devnull: $!";
	close($closed);
	foreach my $handle (undef, $closed) {
		mock 'Test::Builder::failure_output' => sub { return $handle };
		mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 1 };
		lives_ok { $logger->error("snow \x{2603}") } 'output handle ' . (defined($handle) ? 'closed' : 'undef') . ': logging still works';
		restore_all();
	}
	is(scalar(@printed), 2, 'and the line was still handed to Test::Builder each time');
};

done_testing();
