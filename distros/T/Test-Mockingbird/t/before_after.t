#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Readonly;
use Test::Mockingbird;

# ---------------------------------------------------------------------------
# Companion packages
# ---------------------------------------------------------------------------

{ package BA::Calc;
	sub add  { $_[0] + $_[1] }
	sub mul  { $_[0] * $_[1] }
	sub list { (1, 2, 3) }
	sub void { return }
	sub boom { die "explode\n" }
}

{ package BA::Counter;
	our $n = 0;
	sub reset_n { $n = 0 }
	sub inc     { $n++ }
	sub get     { $n }
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $ADD_RESULT  => 7;    # 3 + 4
Readonly::Scalar my $MUL_RESULT  => 12;   # 3 * 4
Readonly::Scalar my $AROUND_MULT => 2;

# ===========================================================================
# before()
# ===========================================================================

subtest 'before: shorthand form runs hook then returns original value' => sub {
	my @seen;
	before 'BA::Calc::add' => sub { push @seen, \@_ };

	my $result = BA::Calc::add(3, 4);

	is $result, $ADD_RESULT, 'original return value unchanged';
	is scalar @seen, 1,      'hook called once';
	is_deeply $seen[0], [3, 4], 'hook received original args';

	restore_all();
};

subtest 'before: longhand form' => sub {
	my $called = 0;
	before('BA::Calc', 'add', sub { $called++ });

	BA::Calc::add(1, 2);

	is $called, 1, 'longhand hook called';
	restore_all();
};

subtest 'before: hook return value is discarded' => sub {
	before 'BA::Calc::add' => sub { return 999 };

	my $result = BA::Calc::add(3, 4);

	is $result, $ADD_RESULT, 'hook return value does not affect result';
	restore_all();
};

subtest 'before: list context preserved' => sub {
	before 'BA::Calc::list' => sub { };

	my @got = BA::Calc::list();

	is_deeply \@got, [1, 2, 3], 'list context returns full list';
	restore_all();
};

subtest 'before: scalar context preserved' => sub {
	before 'BA::Calc::list' => sub { };

	my $got = BA::Calc::list();

	is $got, 3, 'scalar context returns last element';
	restore_all();
};

subtest 'before: void context works without dying' => sub {
	my $ran = 0;
	before 'BA::Calc::void' => sub { $ran++ };

	lives_ok { BA::Calc::void() } 'void call survives';
	is $ran, 1, 'before hook ran in void context';
	restore_all();
};

subtest 'before: multiple stacked hooks run in LIFO order' => sub {
	my @order;
	before 'BA::Calc::add' => sub { push @order, 'B1' };
	before 'BA::Calc::add' => sub { push @order, 'B2' };

	BA::Calc::add(1, 1);

	is_deeply \@order, ['B2', 'B1'], 'last-installed before hook runs first';
	restore_all();
};

subtest 'before: unmock restores one layer' => sub {
	my $outer = 0;
	my $inner = 0;
	before 'BA::Calc::add' => sub { $outer++ };
	before 'BA::Calc::add' => sub { $inner++ };

	BA::Calc::add(1, 1);
	is $inner, 1, 'inner hook ran';
	is $outer, 1, 'outer hook ran';

	unmock 'BA::Calc::add';
	BA::Calc::add(1, 1);
	is $inner, 1, 'inner hook peeled off';
	is $outer, 2, 'outer hook still active';

	restore_all();
};

subtest 'before: diagnose_mocks records correct layer type' => sub {
	before 'BA::Calc::add' => sub { };

	my $d = diagnose_mocks();
	is $d->{'BA::Calc::add'}{layers}[0]{type}, 'before',
		'layer type is "before"';

	restore_all();
};

subtest 'before: croaks on missing target' => sub {
	throws_ok { before(undef, 'add', sub { }) }
		qr/Package, method and hook are required for before/,
		'croaks when package is undef';
};

subtest 'before: croaks on non-CODE hook' => sub {
	throws_ok { before 'BA::Calc::add' => 'not_a_coderef' }
		qr/Package, method and hook are required for before/,
		'croaks when hook is not a coderef';
};

# ===========================================================================
# after()
# ===========================================================================

subtest 'after: shorthand form runs hook after original and returns original value' => sub {
	my @seen;
	after 'BA::Calc::mul' => sub { push @seen, \@_ };

	my $result = BA::Calc::mul(3, 4);

	is $result, $MUL_RESULT, 'original return value unchanged';
	is scalar @seen, 1,       'hook called once';
	is_deeply $seen[0], [3, 4], 'hook received original args';

	restore_all();
};

subtest 'after: longhand form' => sub {
	my $called = 0;
	after('BA::Calc', 'mul', sub { $called++ });

	BA::Calc::mul(2, 3);

	is $called, 1, 'longhand after hook called';
	restore_all();
};

subtest 'after: hook return value is discarded' => sub {
	after 'BA::Calc::mul' => sub { return 999 };

	my $result = BA::Calc::mul(3, 4);

	is $result, $MUL_RESULT, 'after hook return value does not affect result';
	restore_all();
};

subtest 'after: hook runs after the original (verified via ordering)' => sub {
	my @order;
	# Instrument original to record its execution slot
	around 'BA::Calc::mul' => sub {
		my ($orig, @args) = @_;
		push @order, 'orig';
		return $orig->(@args);
	};
	after 'BA::Calc::mul' => sub { push @order, 'after' };

	BA::Calc::mul(2, 3);

	is_deeply \@order, ['orig', 'after'], 'original runs before after-hook';
	restore_all();
};

subtest 'after: list context preserved' => sub {
	after 'BA::Calc::list' => sub { };

	my @got = BA::Calc::list();

	is_deeply \@got, [1, 2, 3], 'list context returns full list';
	restore_all();
};

subtest 'after: scalar context preserved' => sub {
	after 'BA::Calc::list' => sub { };

	my $got = BA::Calc::list();

	is $got, 3, 'scalar context returns last element';
	restore_all();
};

subtest 'after: void context works without dying' => sub {
	my $ran = 0;
	after 'BA::Calc::void' => sub { $ran++ };

	lives_ok { BA::Calc::void() } 'void call survives';
	is $ran, 1, 'after hook ran in void context';
	restore_all();
};

subtest 'after: exception from original propagates before hook runs' => sub {
	my $hook_ran = 0;
	after 'BA::Calc::boom' => sub { $hook_ran++ };

	throws_ok { BA::Calc::boom() } qr/explode/, 'exception propagates';
	is $hook_ran, 0, 'after hook not called when original dies';
	restore_all();
};

subtest 'after: multiple stacked hooks run in install order (A1 before A2)' => sub {
	my @order;
	after 'BA::Calc::add' => sub { push @order, 'A1' };
	after 'BA::Calc::add' => sub { push @order, 'A2' };

	BA::Calc::add(1, 1);

	is_deeply \@order, ['A1', 'A2'],
		'first-installed after hook runs first (FIFO via LIFO wrapping)';
	restore_all();
};

subtest 'after: diagnose_mocks records correct layer type' => sub {
	after 'BA::Calc::add' => sub { };

	my $d = diagnose_mocks();
	is $d->{'BA::Calc::add'}{layers}[0]{type}, 'after',
		'layer type is "after"';

	restore_all();
};

subtest 'after: croaks on missing target' => sub {
	throws_ok { after(undef, 'add', sub { }) }
		qr/Package, method and hook are required for after/,
		'croaks when package is undef';
};

subtest 'after: croaks on non-CODE hook' => sub {
	throws_ok { after 'BA::Calc::add' => 42 }
		qr/Package, method and hook are required for after/,
		'croaks when hook is not a coderef';
};

# ===========================================================================
# around()
# ===========================================================================

subtest 'around: shorthand form — hook receives ($orig, @args)' => sub {
	around 'BA::Calc::add' => sub {
		my ($orig, @args) = @_;
		return $orig->(@args) * $AROUND_MULT;
	};

	my $result = BA::Calc::add(3, 4);

	is $result, $ADD_RESULT * $AROUND_MULT, 'return value modified by around hook';
	restore_all();
};

subtest 'around: longhand form' => sub {
	around('BA::Calc', 'add', sub {
		my ($orig, @args) = @_;
		return $orig->(@args) + 1;
	});

	is BA::Calc::add(3, 4), $ADD_RESULT + 1, 'longhand around works';
	restore_all();
};

subtest 'around: can skip calling original' => sub {
	around 'BA::Calc::add' => sub { return 0 };

	is BA::Calc::add(3, 4), 0, 'original not called when around skips it';
	restore_all();
};

subtest 'around: can call original multiple times' => sub {
	my $calls = 0;
	around 'BA::Calc::add' => sub {
		my ($orig, @args) = @_;
		$calls++;
		my $a = $orig->(@args);
		my $b = $orig->(@args);
		return $a + $b;
	};

	my $result = BA::Calc::add(3, 4);

	is $calls,  1,                   'outer around called once';
	is $result, $ADD_RESULT * 2,     'called original twice; values summed';
	restore_all();
};

subtest 'around: hook can pass different args to $orig' => sub {
	# Verify by checking the return value: add(10, 20) = 30, not add(1, 2) = 3.
	around 'BA::Calc::add' => sub {
		my ($orig, @args) = @_;
		return $orig->(10, 20);   # ignore incoming args, pass different ones
	};

	is BA::Calc::add(1, 2), 30, 'original called with overridden args (10+20=30)';
	restore_all();
};

subtest 'around: stacking — outer around wraps inner' => sub {
	around 'BA::Calc::add' => sub { my ($orig, @a) = @_; $orig->(@a) + 1 };
	around 'BA::Calc::add' => sub { my ($orig, @a) = @_; $orig->(@a) * 2 };

	# Stack (LIFO): outer wrapper = *2; its $orig = +1 wrapper; +1's $orig = real add
	# BA::Calc::add(3,4) = real(3,4)=7 → +1=8 → *2=16
	is BA::Calc::add(3, 4), 16, 'stacked around wrappers compose correctly';
	restore_all();
};

subtest 'around: unmock peels one layer' => sub {
	around 'BA::Calc::add' => sub { my ($o, @a) = @_; $o->(@a) + 100 };
	around 'BA::Calc::add' => sub { my ($o, @a) = @_; $o->(@a) * 10  };

	is BA::Calc::add(1, 2), (3 + 100) * 10, 'both layers active';

	unmock 'BA::Calc::add';

	is BA::Calc::add(1, 2), 3 + 100, 'outer peeled; inner still active';
	restore_all();
};

subtest 'around: diagnose_mocks records correct layer type' => sub {
	around 'BA::Calc::add' => sub { my ($o, @a) = @_; $o->(@a) };

	my $d = diagnose_mocks();
	is $d->{'BA::Calc::add'}{layers}[0]{type}, 'around',
		'layer type is "around"';

	restore_all();
};

subtest 'around: croaks on missing target' => sub {
	throws_ok { around('', 'add', sub { }) }
		qr/Package, method and hook are required for around/,
		'croaks on empty package';
};

subtest 'around: croaks on non-CODE hook' => sub {
	throws_ok { around 'BA::Calc::add' => 'not_code' }
		qr/Package, method and hook are required for around/,
		'croaks when hook is not a coderef';
};

# ===========================================================================
# Mixed interactions
# ===========================================================================

subtest 'mixed before+after: both hooks run, original return preserved' => sub {
	my @order;
	before 'BA::Calc::add' => sub { push @order, 'before' };
	after  'BA::Calc::add' => sub { push @order, 'after'  };

	my $result = BA::Calc::add(3, 4);

	is $result, $ADD_RESULT, 'original return value preserved';
	is_deeply \@order, ['before', 'after'], 'before runs first, after runs last';
	restore_all();
};

subtest 'mixed before+around: before runs before around hook' => sub {
	my @order;
	before 'BA::Calc::add' => sub { push @order, 'before' };
	around 'BA::Calc::add' => sub {
		my ($orig, @args) = @_;
		push @order, 'around-pre';
		my $r = $orig->(@args);
		push @order, 'around-post';
		return $r;
	};

	BA::Calc::add(1, 2);

	# around is installed second (outer); before is inner
	# Call: around-pre → before → orig → around-post
	is_deeply \@order, ['around-pre', 'before', 'around-post'],
		'around wraps before; around-pre runs first';
	restore_all();
};

subtest 'restore_all cleans up before, after, and around layers' => sub {
	before 'BA::Calc::add' => sub { };
	after  'BA::Calc::add' => sub { };
	around 'BA::Calc::add' => sub { my ($o, @a) = @_; $o->(@a) };

	restore_all();

	my $d = diagnose_mocks();
	ok !exists $d->{'BA::Calc::add'}, 'all layers removed by restore_all';
	is BA::Calc::add(3, 4), $ADD_RESULT, 'original restored';
};

done_testing();
