#!/usr/bin/env perl

use strict;
use warnings;

# Test suite for mock_scoped:
#   - bug fix: single mock_scoped call must record exactly one meta layer
#     of type 'mock_scoped', not two ('mock' + 'mock_scoped')
#   - new feature: multi-method mock_scoped in all four argument forms

use Test::Most;
use Readonly;

# Path fixup so this runs from the repo root without installation
use FindBin qw($Bin);
use lib "$Bin/../lib";	# dist root/lib (standard CPAN layout)

use Test::Mockingbird;

# ---------------------------------------------------------------------------
# Inline packages used as subjects under test.  Kept minimal so test output
# is not polluted by incidental method calls.
# ---------------------------------------------------------------------------

{
	package Subject::Alpha;

	# Two independent methods so multi-method tests have distinct targets
	sub fetch  { 'original_fetch'  }
	sub save   { 'original_save'   }
	sub remove { 'original_remove' }
}

{
	package Subject::Beta;

	# Used for cross-package multi-shorthand tests
	sub process { 'original_process' }
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $MOCKED_FETCH   => 'mocked_fetch';
Readonly::Scalar my $MOCKED_SAVE    => 'mocked_save';
Readonly::Scalar my $MOCKED_REMOVE  => 'mocked_remove';
Readonly::Scalar my $MOCKED_PROCESS => 'mocked_process';

Readonly::Scalar my $EXPECTED_TYPE  => 'mock_scoped';
Readonly::Scalar my $EXPECTED_DEPTH => 1;

# ---------------------------------------------------------------------------
# Helper: return the meta layers recorded for a fully qualified method name.
# Returns an empty list when the method has no active mock.
# ---------------------------------------------------------------------------

sub _layers_for {
	my $full = $_[0];

	my $report = diagnose_mocks();
	return () unless exists $report->{$full};
	return @{ $report->{$full}{layers} };
}

# ---------------------------------------------------------------------------
# SUBTEST 1: bug fix -- single meta entry
#
# Prior to the fix, mock_scoped called mock() (which recorded type 'mock')
# and then pushed a second entry of type 'mock_scoped', giving depth 2 with
# mismatched types.  After the fix, exactly one entry of type 'mock_scoped'
# must appear.
# ---------------------------------------------------------------------------

subtest 'bug fix: single meta entry of correct type' => sub {
	plan tests => 3;

	# Install a scoped mock and inspect before the guard falls out of scope
	my $guard = mock_scoped 'Subject::Alpha::fetch' => sub { $MOCKED_FETCH };

	# Exactly one layer must be recorded -- not two
	my @layers = _layers_for('Subject::Alpha::fetch');
	is(scalar @layers, $EXPECTED_DEPTH, 'exactly one meta layer recorded');

	# That layer must carry the correct type label
	is($layers[0]{type}, $EXPECTED_TYPE, 'layer type is mock_scoped, not mock');

	# Sanity: the mock is actually active
	is(Subject::Alpha::fetch(), $MOCKED_FETCH, 'mock is live during guard scope');

	# Guard destroyed at end of subtest block; restore_all cleans up below
};

restore_all();

# ---------------------------------------------------------------------------
# SUBTEST 2: single shorthand form (pre-existing behaviour, no regression)
#
#   mock_scoped 'Pkg::method' => sub { ... }
# ---------------------------------------------------------------------------

subtest 'single shorthand form' => sub {
	plan tests => 3;

	# Confirm original behaviour before mocking
	is(Subject::Alpha::fetch(), 'original_fetch', 'original value before scope');

	{
		my $guard = mock_scoped 'Subject::Alpha::fetch' => sub { $MOCKED_FETCH };

		# Method must return the mocked value inside the lexical block
		is(Subject::Alpha::fetch(), $MOCKED_FETCH, 'mocked inside scope');
	}

	# Guard destroyed: original must be restored automatically
	is(Subject::Alpha::fetch(), 'original_fetch', 'restored after guard destroyed');
};

# ---------------------------------------------------------------------------
# SUBTEST 3: single longhand form (pre-existing behaviour, no regression)
#
#   mock_scoped('Pkg', 'method', sub { ... })
# ---------------------------------------------------------------------------

subtest 'single longhand form' => sub {
	plan tests => 3;

	is(Subject::Alpha::fetch(), 'original_fetch', 'original value before scope');

	{
		my $guard = mock_scoped('Subject::Alpha', 'fetch', sub { $MOCKED_FETCH });

		is(Subject::Alpha::fetch(), $MOCKED_FETCH, 'mocked inside scope');
	}

	is(Subject::Alpha::fetch(), 'original_fetch', 'restored after guard destroyed');
};

# ---------------------------------------------------------------------------
# SUBTEST 4: multi shorthand form (new feature)
#
#   mock_scoped 'Pkg::m1' => $c1, 'Pkg::m2' => $c2
#
# Two methods on different packages are mocked by a single guard.
# Both must be live inside the scope, both restored outside.
# ---------------------------------------------------------------------------

subtest 'multi shorthand form: two methods, two packages' => sub {
	plan tests => 6;

	# Confirm originals before mocking
	is(Subject::Alpha::fetch(),   'original_fetch',   'Alpha::fetch original before scope');
	is(Subject::Beta::process(),  'original_process', 'Beta::process original before scope');

	{
		my $guard = mock_scoped(
			'Subject::Alpha::fetch'   => sub { $MOCKED_FETCH   },
			'Subject::Beta::process'  => sub { $MOCKED_PROCESS },
		);

		# Both methods must reflect their mocked implementations
		is(Subject::Alpha::fetch(),  $MOCKED_FETCH,   'Alpha::fetch mocked inside scope');
		is(Subject::Beta::process(), $MOCKED_PROCESS, 'Beta::process mocked inside scope');
	}

	# Both must be restored when the single guard is destroyed
	is(Subject::Alpha::fetch(),  'original_fetch',   'Alpha::fetch restored after guard');
	is(Subject::Beta::process(), 'original_process', 'Beta::process restored after guard');
};

# ---------------------------------------------------------------------------
# SUBTEST 5: multi longhand form (new feature)
#
#   mock_scoped('Pkg', m1 => $c1, m2 => $c2)
#
# Two methods on the same package mocked together via the longhand form.
# ---------------------------------------------------------------------------

subtest 'multi longhand form: two methods, same package' => sub {
	plan tests => 6;

	is(Subject::Alpha::fetch(), 'original_fetch', 'fetch original before scope');
	is(Subject::Alpha::save(),  'original_save',  'save original before scope');

	{
		my $guard = mock_scoped('Subject::Alpha',
			fetch => sub { $MOCKED_FETCH },
			save  => sub { $MOCKED_SAVE  },
		);

		is(Subject::Alpha::fetch(), $MOCKED_FETCH, 'fetch mocked inside scope');
		is(Subject::Alpha::save(),  $MOCKED_SAVE,  'save mocked inside scope');
	}

	is(Subject::Alpha::fetch(), 'original_fetch', 'fetch restored after guard');
	is(Subject::Alpha::save(),  'original_save',  'save restored after guard');
};

# ---------------------------------------------------------------------------
# SUBTEST 6: multi longhand form with three methods (new feature)
#
# Verifies that the guard correctly tracks an arbitrary number of methods,
# not just two.
# ---------------------------------------------------------------------------

subtest 'multi longhand form: three methods, same package' => sub {
	plan tests => 9;

	# Confirm all three originals up front
	is(Subject::Alpha::fetch(),  'original_fetch',  'fetch original before scope');
	is(Subject::Alpha::save(),   'original_save',   'save original before scope');
	is(Subject::Alpha::remove(), 'original_remove', 'remove original before scope');

	{
		my $guard = mock_scoped('Subject::Alpha',
			fetch  => sub { $MOCKED_FETCH   },
			save   => sub { $MOCKED_SAVE    },
			remove => sub { $MOCKED_REMOVE  },
		);

		# All three must be live simultaneously under one guard
		is(Subject::Alpha::fetch(),  $MOCKED_FETCH,   'fetch mocked inside scope');
		is(Subject::Alpha::save(),   $MOCKED_SAVE,    'save mocked inside scope');
		is(Subject::Alpha::remove(), $MOCKED_REMOVE,  'remove mocked inside scope');
	}

	# Guard DESTROY must restore all three in a single sweep
	is(Subject::Alpha::fetch(),  'original_fetch',  'fetch restored after guard');
	is(Subject::Alpha::save(),   'original_save',   'save restored after guard');
	is(Subject::Alpha::remove(), 'original_remove', 'remove restored after guard');
};

# ---------------------------------------------------------------------------
# SUBTEST 7: explicit guard undef triggers restore
#
# Verifies that calling undef $guard (not waiting for lexical scope exit)
# also triggers the unmock, since DESTROY fires on explicit undef.
# ---------------------------------------------------------------------------

subtest 'explicit guard undef triggers restore' => sub {
	plan tests => 3;

	my $guard = mock_scoped('Subject::Alpha',
		fetch => sub { $MOCKED_FETCH },
		save  => sub { $MOCKED_SAVE  },
	);

	# Both mocked before undef
	is(Subject::Alpha::fetch(), $MOCKED_FETCH, 'fetch mocked before undef');

	undef $guard;	# DESTROY fires immediately

	# Both must be restored without waiting for lexical scope exit
	is(Subject::Alpha::fetch(), 'original_fetch', 'fetch restored on explicit undef');
	is(Subject::Alpha::save(),  'original_save',  'save restored on explicit undef');
};

# ---------------------------------------------------------------------------
# SUBTEST 8: diagnose_mocks reflects multi-method state correctly
#
# Each method in a multi-method mock_scoped call must appear in the
# diagnostic report with depth 1 and type 'mock_scoped'.
# ---------------------------------------------------------------------------

subtest 'diagnose_mocks: multi-method state' => sub {
	plan tests => 6;

	my $guard = mock_scoped('Subject::Alpha',
		fetch => sub { $MOCKED_FETCH },
		save  => sub { $MOCKED_SAVE  },
	);

	# Fetch diagnostics for both methods
	my @fetch_layers = _layers_for('Subject::Alpha::fetch');
	my @save_layers  = _layers_for('Subject::Alpha::save');

	# Each method must have exactly one layer recorded
	is(scalar @fetch_layers, $EXPECTED_DEPTH, 'fetch: one meta layer');
	is(scalar @save_layers,  $EXPECTED_DEPTH, 'save: one meta layer');

	# Both layers must carry the mock_scoped type label
	is($fetch_layers[0]{type}, $EXPECTED_TYPE, 'fetch: layer type is mock_scoped');
	is($save_layers[0]{type},  $EXPECTED_TYPE, 'save: layer type is mock_scoped');

	undef $guard;	# restore before checking post-state

	# Both entries must be removed from the diagnostic report on restore
	my @fetch_after = _layers_for('Subject::Alpha::fetch');
	my @save_after  = _layers_for('Subject::Alpha::save');

	is(scalar @fetch_after, 0, 'fetch: no layers after guard destroyed');
	is(scalar @save_after,  0, 'save: no layers after guard destroyed');
};

done_testing();
