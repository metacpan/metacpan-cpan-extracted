#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Readonly;

use Test::Mockingbird;

# ---------------------------------------------------------------------------
# CORE::GLOBAL semantics note:
#
# mock_core installs in CORE::GLOBAL, which is Perl's documented mechanism
# for globally overriding named builtins.  The override is a compile-time
# hook: it affects code compiled AFTER the override is installed, not
# already-compiled call sites.
#
# We use string eval ("eval ...") to compile fresh code that will see the
# installed override.  Direct calls in this file (e.g. "warn 'hello'") were
# compiled at compile-time of this file, before any mocks exist, so they
# bypass the override and call the real builtin.
# ---------------------------------------------------------------------------

Readonly my $ERR_ARGS    => 'mock_core requires a builtin name and a replacement coderef';
Readonly my $ERR_IDENT   => qr/is not a valid identifier/;
Readonly my $ERR_BUILTIN => qr/is not an overridable Perl builtin/;

subtest 'mock_core(): intercepts builtin in string-eval-compiled code' => sub {
	# String eval compiles at runtime, AFTER mock_core installs the override.
	# CORE::GLOBAL::warn is therefore visible and the mock fires.
	my @captured;
	mock_core 'warn' => sub {
		my ($call_warn, @msgs) = @_;
		push @captured, @msgs;
	};

	eval 'warn "hello"';    ## no critic (ProhibitStringyEval)

	is scalar @captured, 1, 'warn intercepted in eval-compiled code';
	like $captured[0], qr/hello/, 'message captured';

	restore_all();

	# After restore, the override is gone; string-eval code uses real warn.
	@captured = ();
	my @real;
	local $SIG{__WARN__} = sub { push @real, @_ };
	eval 'warn "restored"';    ## no critic (ProhibitStringyEval)
	is scalar @captured, 0, 'mock no longer fires after restore_all';
	is scalar @real,     1, 'real warn fires after restore_all';
};

subtest 'mock_core(): $call_builtin delegates to CORE::builtin directly' => sub {
	my @log;
	mock_core 'warn' => sub {
		my ($call_warn, @msgs) = @_;
		push @log, "before:@msgs";
		$call_warn->(@msgs);    # call through to real CORE::warn
		push @log, 'after';
	};

	my @real;
	local $SIG{__WARN__} = sub { push @real, @_ };

	eval 'warn "passthrough"';    ## no critic (ProhibitStringyEval)

	is $log[0], 'before:passthrough', 'before-hook ran';
	is $log[1], 'after',              'after-hook ran';
	is scalar @real, 1, 'real warn fired once via $call_builtin';
	like $real[0], qr/passthrough/, 'real warning content correct';

	restore_all();
};

subtest 'mock_core(): wrapper carries CORE prototype (no Prototype mismatch warning)' => sub {
	# stat has the '_' prototype.  Our wrapper must carry the same prototype so
	# that Perl does not emit a "Prototype mismatch" warning when compiling calls
	# to CORE::GLOBAL::stat in eval'd code.
	#
	# Note: Perl's compiler does NOT apply the user-sub '_' defaulting rule
	# (substitute $_ when no arg given) for CORE::GLOBAL overrides of builtins
	# whose no-arg form has special semantics (stat with no args reuses the '_'
	# filehandle cache at the opcode level).  We therefore test with an explicit
	# argument rather than relying on no-arg $_ binding.
	my @received_args;
	mock_core 'stat' => sub {
		my ($call_stat, @args) = @_;
		@received_args = @args;
		return (0) x 13;
	};

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	# Explicit arg: verifies the wrapper is called and args are forwarded.
	eval 'my @s = stat "/no/such/path"; $main::_stat_result = \@s';    ## no critic

	is scalar @{ $main::_stat_result // [] }, 13,
		'stat wrapper returned 13-element list';
	is scalar @received_args, 1,    'one arg passed to wrapper';
	is $received_args[0], '/no/such/path', 'arg value forwarded correctly';

	is scalar(grep { /Prototype mismatch/ } @warnings), 0,
		'no Prototype mismatch warning emitted';

	restore_all();
	undef $main::_stat_result;
};

subtest 'mock_core(): participates in LIFO mock stack' => sub {
	my @log;
	mock_core 'warn' => sub { my ($c, @m) = @_; push @log, "first:@m" };
	mock_core 'warn' => sub { my ($c, @m) = @_; push @log, "second:@m" };

	eval 'warn "a"';    ## no critic (ProhibitStringyEval)
	is $log[-1], 'second:a', 'second (outermost) mock fires';
	is scalar @log, 1, 'only the outermost layer fires';

	unmock 'CORE::GLOBAL::warn';
	@log = ();
	eval 'warn "b"';    ## no critic (ProhibitStringyEval)
	is $log[-1], 'first:b', 'first mock active after unmock peels second';

	restore_all();
};

subtest 'mock_core(): unmock restores real builtin' => sub {
	mock_core 'warn' => sub { };    # suppress warn

	my @real;
	{
		local $SIG{__WARN__} = sub { push @real, @_ };
		eval 'warn "mocked"';    ## no critic (ProhibitStringyEval)
	}
	is scalar @real, 0, 'real warn suppressed while mock active';

	unmock 'CORE::GLOBAL::warn';

	{
		local $SIG{__WARN__} = sub { push @real, @_ };
		eval 'warn "real"';    ## no critic (ProhibitStringyEval)
	}
	is scalar @real, 1, 'real warn fires after unmock';

	restore_all();
};

subtest 'mock_core(): diagnose_mocks records type mock_core' => sub {
	mock_core 'warn' => sub { };

	my $d = diagnose_mocks();
	ok exists $d->{'CORE::GLOBAL::warn'}, 'CORE::GLOBAL::warn tracked';
	is $d->{'CORE::GLOBAL::warn'}{layers}[0]{type}, 'mock_core',
		'layer type is mock_core';

	restore_all();
};

subtest 'mock_core(): CORE:: prefix in name is stripped' => sub {
	my @captured;
	mock_core 'CORE::warn' => sub { push @captured, 'caught' };

	eval 'warn "test"';    ## no critic (ProhibitStringyEval)
	is scalar @captured, 1, 'CORE:: prefix stripped and mock applied';

	restore_all();
};

subtest 'mock_core(): used in a module loaded after installation' => sub {
	# Install mock BEFORE loading the helper package (simulates BEGIN usage).
	# The helper package uses warn internally -- the mock intercepts it.
	my @captured;
	mock_core 'warn' => sub {
		my ($c, @m) = @_;
		push @captured, @m;
	};

	# Compile fresh code that calls warn -- represents a newly loaded module.
	eval q{
		package MC::Fresh;
		sub emit { warn "from fresh module" }
		1;
	};    ## no critic (ProhibitStringyEval)

	MC::Fresh::emit();

	is scalar @captured, 1, 'warn in freshly compiled module intercepted';
	like $captured[0], qr/from fresh module/, 'message correct';

	restore_all();
};

subtest 'mock_core(): croak on missing or wrong-typed arguments' => sub {
	throws_ok { mock_core('warn') }
		qr/\Q$ERR_ARGS\E/, 'one arg (no coderef) croaks';

	throws_ok { mock_core('warn', 'not-a-coderef') }
		qr/\Q$ERR_ARGS\E/, 'string instead of coderef croaks';

	throws_ok { mock_core(undef, sub { }) }
		qr/\Q$ERR_ARGS\E/, 'undef name croaks';
};

subtest 'mock_core(): croak on non-identifier or unknown builtin' => sub {
	throws_ok { mock_core('has::colons', sub { }) }
		$ERR_IDENT, 'name with :: croaks (not a valid identifier)';

	throws_ok { mock_core('no_such_builtin_xyz', sub { }) }
		$ERR_BUILTIN, 'unknown builtin name croaks';
};

done_testing();
