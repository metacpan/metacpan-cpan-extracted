package Test::Mockingbird;

use strict;
use warnings;

# TODO: Look into Sub::Install

use Carp qw(croak);
use Exporter 'import';
use Scalar::Util ();

our @EXPORT = qw(
	mock
	unmock
	mock_scoped
	spy
	inject
	restore
	restore_all
	mock_return
	mock_exception
	mock_sequence
	mock_once
	diagnose_mocks
	diagnose_mocks_pretty
);

# Store mocked data
my %mocked;		# becomes: method => [ stack of backups ]
my %mock_meta;	# full_method => [ { type => ..., installed_at => ... }, ... ]

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

  use Test::Mockingbird;

  # Mocking
  Test::Mockingbird::mock('My::Module', 'method', sub { return 'mocked!' });

  # Spying
  my $spy = Test::Mockingbird::spy('My::Module', 'method');
  My::Module::method('arg1', 'arg2');
  my @calls = $spy->(); # Get captured calls

  # Dependency Injection
  Test::Mockingbird::inject('My::Module', 'Dependency', $mock_object);

  # Unmocking
  Test::Mockingbird::unmock('My::Module', 'method');

  # Restore everything
  Test::Mockingbird::restore_all();

=head1 DESCRIPTION

Test::Mockingbird provides powerful mocking, spying, and dependency injection capabilities to streamline testing in Perl.

=head1 DIAGNOSTICS

Test::Mockingbird provides optional, non-intrusive diagnostic routines
that allow inspection of the current mocking state during test execution.
These routines are purely observational. They do not modify any mocking
behaviour, symbol table entries, or internal state.

Diagnostics are useful when debugging complex test suites, verifying
mock layering behaviour, or understanding interactions between multiple
mocking primitives such as mock, spy, inject, and the sugar functions.

=head2 diagnose_mocks

Return a structured hashref describing all currently active mock layers.
Each entry includes the fully qualified method name, the number of active
layers, whether the original method existed, and metadata for each layer
(type and installation location). See the diagnose_mocks method for full
API details.

=head2 diagnose_mocks_pretty

Return a human-readable, multi-line string describing all active mock
layers. This routine is intended for debugging and inspection during test
development. The output format is stable for human consumption but is not
guaranteed for machine parsing. See the diagnose_mocks_pretty method for
full API details.

=head2 Diagnostic Metadata

Diagnostic information is recorded automatically whenever a mock layer is
successfully installed. Each layer records:

  * type          The category of mock layer (for example: mock, spy,
                  inject, mock_return, mock_exception, mock_sequence,
                  mock_once, mock_scoped)

  * installed_at  The file and line number where the layer was created

This metadata is maintained in parallel with the internal mock stack and
is automatically cleared when a method is fully restored via unmock or
restore_all.

Diagnostics never alter the behaviour of the mocking engine and may be
safely invoked at any point during a test run.

=head1 DEBUGGING EXAMPLES

This section provides practical examples of using the diagnostic routines
to understand and debug complex mocking behaviour.
All examples are safe to run inside test files and do not modify mocking semantics.

=head2 Example 1: Inspecting a simple mock

    {
        package Demo::One;
        sub value { 1 }
    }

    mock_return 'Demo::One::value' => 42;

    my $diag = diagnose_mocks();
    print diagnose_mocks_pretty();

The output will resemble:

    Demo::One::value:
      depth: 1
      original_existed: 1
      - type: mock_return   installed_at: t/example.t line 12

This confirms that the method has exactly one active mock layer and shows
where it was installed.

=head2 Example 2: Stacked mocks

    {
        package Demo::Two;
        sub compute { 10 }
    }

    mock_return    'Demo::Two::compute' => 20;
    mock_exception 'Demo::Two::compute' => 'fail';

    print diagnose_mocks_pretty();

Possible output:

    Demo::Two::compute:
      depth: 2
      original_existed: 1
      - type: mock_return   installed_at: t/example.t line 8
      - type: mock_exception installed_at: t/example.t line 9

This shows the order in which layers were applied. The most recent layer
appears last.

=head2 Example 3: Spies and injected dependencies

    {
        package Demo::Three;
        sub action { 1 }
        sub dep    { 2 }
    }

    spy 'Demo::Three::action';
    inject 'Demo::Three::dep' => sub { 99 };

    print diagnose_mocks_pretty();

Example output:

    Demo::Three::action:
      depth: 1
      original_existed: 1
      - type: spy           installed_at: t/example.t line 7

    Demo::Three::dep:
      depth: 1
      original_existed: 1
      - type: inject        installed_at: t/example.t line 8

This confirms that both the spy and the injected dependency are active.

=head2 Example 4: After restore_all

    mock_return 'Demo::Four::x' => 5;
    restore_all();

    print diagnose_mocks_pretty();

Output:

    (no output)

After restore_all, all diagnostic metadata is cleared along with the
mock layers.

=head2 Example 5: Using diagnostics inside a failing test

When a test fails unexpectedly, adding the following line can help
identify the active mocks:

    diag diagnose_mocks_pretty();

This prints the current mocking state into the test output without
affecting the test run.

=cut

=head1 METHODS

=head2 mock($package, $method, $replacement)

Mocks a method in the specified package.
Supports two forms:

    mock('My::Module', 'method', sub { ... });

or the shorthand:

    mock 'My::Module::method' => sub { ... };

If the original function carries a Perl prototype, the same prototype is
automatically applied to the replacement coderef before it is installed.
This prevents Perl from emitting C<Prototype mismatch> warnings at call
sites that were compiled against the original signature. The canonical
case is functions declared with a C<()> no-args prototype, such as
C<I18N::LangTags::Detect::detect>. The replacement is almost always an
anonymous C<sub {}> created for the mock, so mutating its prototype
in-place is safe.

If the original has no prototype, no prototype is imposed on the
replacement.

=cut

sub mock {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $replacement);

	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		$package     = $1;
		$method      = $2;
		$replacement = $arg2;
	} else {
		($package, $method, $replacement) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and replacement are required for mocking'
		unless $package && $method && $replacement;

	my $full_method = "${package}::$method";

	# Capture the original coderef before replacing it.  A named variable
	# is required here so we can inspect its prototype in the next step.
	my $original = \&{$full_method};
	push @{ $mocked{$full_method} }, $original;

	# If the original carries a prototype, stamp the same prototype onto
	# the replacement.  This prevents Perl emitting prototype-mismatch
	# warnings at call sites that were compiled against the original
	# signature (e.g. functions with a () no-args prototype such as
	# I18N::LangTags::Detect::detect).  The replacement is almost always
	# an anonymous sub created for this mock, so mutating its prototype
	# in-place is safe.
	my $proto = prototype($original);
	&Scalar::Util::set_prototype($replacement, $proto) if defined $proto;

	no warnings 'redefine';
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		*{$full_method} = $replacement;
	}

	my $type = $Test::Mockingbird::TYPE // 'mock';

	push @{ $mock_meta{$full_method} }, {
		type         => $type,
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
}

=head2 unmock($package, $method)

Restores the original method for a mocked method.
Supports two forms:

    unmock('My::Module', 'method');

or the shorthand:

    unmock 'My::Module::method';

Because C<mock> stores the original coderef (not a copy), reinstating it
via glob assignment also restores its prototype automatically. No explicit
prototype handling is required in C<unmock>.

=cut

sub unmock {
	my ($arg1, $arg2) = @_;

	my ($package, $method);

	if (defined $arg1 && !defined $arg2 && $arg1 =~ /^(.*)::([^:]+)$/) {
		# Case 1: unmock 'Pkg::method'
		($package, $method) = ($1, $2);
	} else {
		# Case 2: unmock 'Pkg', 'method'
		($package, $method) = ($arg1, $arg2);
	}

	croak 'Package and method are required for unmocking' unless $package && $method;

	my $full_method = "${package}::$method";

	# Restore previous layer if present
	if (exists $mocked{$full_method} && @{ $mocked{$full_method} }) {
		my $prev = pop @{ $mocked{$full_method} };

		no warnings 'redefine';

		{
			## no critic (ProhibitNoStrict)  # symbolic reference required for restore
			no strict 'refs';
			*{$full_method} = $prev;
		}
		delete $mocked{$full_method} unless @{ $mocked{$full_method} };
		delete $mock_meta{$full_method};
	}
}

=head2 mock_scoped

Creates a scoped mock that is automatically restored when the returned guard
goes out of scope.

This behaves like C<mock>, but instead of requiring an explicit call to
C<unmock> or C<restore_all>, all mocked methods are reverted automatically
when the guard object is destroyed.

=head3 Single-method forms

Shorthand:

    my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };

Longhand:

    my $g = mock_scoped('My::Module', 'method', sub { ... });

=head3 Multi-method forms

Mock several methods on one package with a single guard:

    my $g = mock_scoped('My::Module',
        fetch  => sub { 'mocked_fetch'  },
        save   => sub { 'mocked_save'   },
        delete => sub { 'mocked_delete' },
    );

Mock methods across different packages in one call (shorthand pairs):

    my $g = mock_scoped(
        'My::Module::fetch'  => sub { 'mocked_fetch'  },
        'Other::Module::save' => sub { 'mocked_save'  },
    );

In both multi-method forms, every mocked method is restored when C<$g>
goes out of scope or is explicitly undefed.

=head3 Scoped lifecycle

    {
        my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
        My::Module::method();   # returns 'mocked'
    }

    My::Module::method();       # original behaviour restored

=head3 Interaction with spy

A C<spy> is not automatically restored when a C<mock_scoped> guard
goes out of scope. C<mock_scoped> only manages the specific mock
layer it installs. If you install a spy inside a scoped block, you
must restore it explicitly:

    {
        my $g   = mock_scoped 'My::Module::method' => sub { 1 };
        my $spy = spy 'My::Module::method';

        My::Module->method('arg');
    }
    # $g is destroyed here -- the mock_scoped layer is restored
    # but the spy layer is still active

    restore_all();    # needed to fully restore method

The safe pattern when combining C<mock_scoped> and C<spy> is to
call C<restore_all> at the end of the block, or to avoid combining
them and use C<mock> with an explicit C<restore_all> instead:

    spy 'My::Module::method';
    My::Module->method('arg');
    my @calls = $spy->();
    restore_all();

=head3 Notes

If you need both a modified implementation and call recording in
the same test, install the spy first and then the mock. The spy
will still capture calls even when the implementation is replaced
by the mock layer above it, because the spy wraps the layer below
it at installation time, not the current top of the stack. To avoid
confusion, prefer explicit C<restore_all> over C<mock_scoped> when
combining with spies.

=cut

sub mock_scoped {
	my @args = @_;

	# ------------------------------------------------------------------
	# Parse argument forms into a list of [package, method, coderef].
	#
	# Four recognised forms:
	#
	#   Single shorthand  (2 args):
	#     mock_scoped 'Pkg::method' => $code
	#
	#   Single longhand   (3 args):
	#     mock_scoped 'Pkg', 'method', $code
	#
	#   Multi shorthand   (>=4 args, even count, arg[1] is CODE):
	#     mock_scoped 'Pkg::m1' => $code1, 'Pkg::m2' => $code2
	#
	#   Multi longhand    (>=5 args, odd count, arg[2] is CODE):
	#     mock_scoped 'Pkg', m1 => $code1, m2 => $code2
	# ------------------------------------------------------------------

	my @pairs;	# accumulated [pkg, method, code] triples

	if (@args == 2 && ref($args[1]) eq 'CODE') {
		# Single shorthand: 'Pkg::method' => $code
		my ($pkg, $method) = _parse_target($args[0]);
		push @pairs, [ $pkg, $method, $args[1] ];

	} elsif (@args == 3 && !ref($args[1]) && ref($args[2]) eq 'CODE') {
		# Single longhand: 'Pkg', 'method', $code
		push @pairs, [ $args[0], $args[1], $args[2] ];

	} elsif (@args >= 4 && (@args % 2) == 0 && ref($args[1]) eq 'CODE') {
		# Multi shorthand: pairs of ('Pkg::method', $code)
		my @a = @args;
		while (@a) {
			my ($target, $code) = splice @a, 0, 2;
			croak "mock_scoped: expected coderef for '$target'"
				unless ref($code) eq 'CODE';
			my ($pkg, $method) = _parse_target($target);
			push @pairs, [ $pkg, $method, $code ];
		}

	} elsif (@args >= 5 && (@args % 2) == 1 && ref($args[2]) eq 'CODE') {
		# Multi longhand: 'Pkg', method1 => $code1, method2 => $code2, ...
		my @a   = @args;
		my $pkg = shift @a;
		while (@a) {
			my ($method, $code) = splice @a, 0, 2;
			croak "mock_scoped: expected coderef for method '$method'"
				unless ref($code) eq 'CODE';
			push @pairs, [ $pkg, $method, $code ];
		}

	} else {
		croak 'mock_scoped: unrecognised argument form';
	}

	# ------------------------------------------------------------------
	# Install each mock.  local TYPE ensures mock() records the correct
	# layer type without an extra meta push, matching the pattern used
	# by mock_return, mock_exception, etc.
	# ------------------------------------------------------------------

	my @full_methods;

	{
		local $Test::Mockingbird::TYPE = 'mock_scoped';
		for my $pair (@pairs) {
			my ($pkg, $method, $code) = @{$pair};
			mock($pkg, $method, $code);
			push @full_methods, "${pkg}::${method}";
		}
	}

	# Return a guard that unmocks every installed method on destruction
	return Test::Mockingbird::Guard->new(@full_methods);
}

=head2 spy($package, $method)

Wraps a method so that all calls and arguments are recorded.
Supports two forms:

    spy('My::Module', 'method');

or the shorthand:

    spy 'My::Module::method';

Returns a coderef which, when invoked, returns the list of captured calls.
The original method is preserved and still executed.

=head3 Call record format

Each captured call is an arrayref with the following structure:

    [ $method_name, $invocant, @arguments ]

where:

=over 4

=item * C<$method_name> - the fully qualified method name as a string
(e.g. C<'My::Module::method'>)

=item * C<$invocant> - the first argument to the call, typically C<$self>
for method calls or the first positional argument for function calls

=item * C<@arguments> - the remaining arguments passed to the method,
in the order they were supplied. For named-parameter calls these will
be alternating key/value pairs suitable for assignment to a hash:
C<my %args = @{$call}[2..$#{$call}]>

=back

=head3 Example

    spy 'My::Module::process';
    My::Module->process(name => 'foo', value => 42);

    my @calls = $spy->();
    my $call  = $calls[0];

    # $call->[0] eq 'My::Module::process'
    # $call->[1] is the My::Module object
    # @{$call}[2..$#{$call}] gives (name => 'foo', value => 42)

    my %args = @{$call}[2..$#{$call}];
    is($args{name},  'foo', 'name arg captured');
    is($args{value}, 42,    'value arg captured');

=head3 Limitations

C<spy> installs its wrapper coderef directly into the glob without going
through C<mock>, so the prototype-preservation logic in C<mock> does not
apply. If the target function carries a Perl prototype (for example a
C<()> no-args prototype), installing a spy will emit a
C<Prototype mismatch> warning.

If you need warning-free wrapping of a prototyped function, install the
spy on a non-prototyped alias, or use C<mock> with a wrapper that records
calls and delegates to the original:

    my @calls;
    mock 'My::Module::detect' => sub {
        push @calls, [@_];
        return My::Module::_real_detect(@_);   # delegate manually
    };

This limitation will be addressed in a future release.

=cut

sub spy {
	my ($arg1, $arg2) = @_;

	my ($package, $method) = _parse_target(@_);

	croak 'Package and method are required for spying' unless $package && $method;

	my $full_method = "${package}::$method";

	# Capture the current implementation BEFORE installing the wrapper
	my $orig;
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		$orig = \&{$full_method};
	}

	# Track the original implementation
	push @{ $mocked{$full_method} }, $orig;

	my @calls;

	# Wrapper: record call, then delegate to the captured original
	my $wrapper = sub {
		push @calls, [ $full_method, @_ ];
		return $orig->(@_);
	};

	no warnings 'redefine';
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		*{$full_method} = $wrapper;
	}

	push @{ $mock_meta{$full_method} }, {
		type         => 'spy',
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
	return sub { @calls };
}

=head2 inject($package, $dependency, $mock_object)

Injects a mock dependency. Supports two forms:

    inject('My::Module', 'Dependency', $mock_object);

or the shorthand:

    inject 'My::Module::Dependency' => $mock_object;

The injected dependency can be restored with C<restore_all> or C<unmock>.

=cut

sub inject {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $dependency, $mock_object);

	# ------------------------------------------------------------
	# New shorthand syntax:
	#   inject 'My::Module::Dependency' => $mock_obj
	# ------------------------------------------------------------
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		$package     = $1;
		$dependency  = $2;
		$mock_object = $arg2;
	} else {
		# ------------------------------------------------------------
		# Original syntax:
		#   inject('My::Module', 'Dependency', $mock_obj)
		# ------------------------------------------------------------
		($package, $dependency, $mock_object) = ($arg1, $arg2, $arg3);
	}

	croak 'Package and dependency are required for injection' unless $package && $dependency;

	my $full_dependency = "${package}::$dependency";

	my $orig;

	{
		## no critic (ProhibitNoStrict)  # symbolic reference required
		no strict 'refs';
		$orig = \&{$full_dependency};
	}

	push @{ $mocked{$full_dependency} }, $orig;

	# Build the injected dependency wrapper outside the strict-free block
	my $wrapper = sub { $mock_object };

	no warnings 'redefine';

	{
		## no critic (ProhibitNoStrict)  # symbolic reference required for injection
		no strict 'refs';
		*{$full_dependency} = $wrapper;
	}
	push @{ $mock_meta{$full_dependency} }, {
		type         => 'inject',
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
}

=head2 restore_all

Restores all mocked methods and injected dependencies.

Called with no arguments, restores everything that has been mocked
in the current test run:

    restore_all();

Called with a package name, restores only the mocks whose fully
qualified names begin with that package:

    restore_all 'My::Module';

This is useful when a test installs mocks across multiple packages
and needs to tear down only one package's mocks without disturbing
the others:

    mock 'My::Module::fetch'   => sub { 'mocked_fetch' };
    mock 'Other::Module::save' => sub { 'mocked_save'  };

    # Tear down only My::Module mocks
    restore_all 'My::Module';

    # Other::Module::save is still mocked here
    restore_all();    # now everything is restored

=head3 Notes

Restoring a package that was never mocked is a no-op and does not
warn or croak.

=cut

sub restore_all {
	my $arg = $_[0];

	# ------------------------------------------------------------------
	# If a package name is provided, restore only methods belonging to
	# that package. Otherwise, restore everything.
	# ------------------------------------------------------------------

	if (defined $arg) {
		my $package = $arg;

		for my $full_method (keys %mocked) {
			next unless $full_method =~ /^\Q$package\E::/;

			# Restore all layers for this method
			while (@{ $mocked{$full_method} }) {
				my $prev = pop @{ $mocked{$full_method} };

				no warnings 'redefine';

				{
					## no critic (ProhibitNoStrict)  # symbolic reference required for restore
					no strict 'refs';
					*{$full_method} = $prev;
				}
			}
			delete $mocked{$full_method};
			delete $mock_meta{$full_method};
		}

		return;
	}

	# ------------------------------------------------------------------
	# Global restore: revert every mocked or injected method
	# ------------------------------------------------------------------
	for my $full_method (keys %mocked) {
		while (@{ $mocked{$full_method} }) {
			my $prev = pop @{ $mocked{$full_method} };

			no warnings 'redefine';

			{
				## no critic (ProhibitNoStrict)  # symbolic reference required for restore
				no strict 'refs';
				*{$full_method} = $prev;
			}
		}
	}

	# Clear all tracking
	%mocked    = ();
	%mock_meta = ();
}

=head2 mock_return

Mock a method so that it always returns a fixed value.

Takes a single target (either C<'Pkg::method'> or C<('Pkg','method')>) and
a value to return. Returns nothing. Side effects: installs a mock layer
using C<mock>.

=head3 API specification

=head4 Input

Params::Validate::Strict schema:

- C<target>: required, scalar, string; method target in shorthand or longhand form
- C<value>: required, any type; value to be returned by the mock

=head4 Output

Returns::Set schema:

- C<return>: undef

=cut

sub mock_return {
	my ($target, $value) = @_;

	# Entry: target must be defined, value may be any defined/undef scalar
	# Exit: mock layer installed for target, no return value
	# Side effects: modifies symbol table via mock()
	# Notes: uses existing mock() parsing and stacking semantics
	croak 'mock_return requires a target and a value' unless defined $target;

	my $code = sub { $value };

	local $Test::Mockingbird::TYPE = 'mock_return';

	# MUST use the shorthand form:
	return mock $target => $code;
}

=head2 mock_exception

Mock a method so that it always throws an exception.

Takes a single target (either C<'Pkg::method'> or C<('Pkg','method')>) and
an exception message. Returns nothing. Side effects: installs a mock layer
using C<mock>.

=head3 API specification

=head4 Input

Params::Validate::Strict schema:

- C<target>: required, scalar, string; method target in shorthand or longhand form
- C<message>: required, scalar, string; exception text to C<croak> with

=head4 Output

Returns::Set schema:

- C<return>: undef

=cut

sub mock_exception {
	my ($target, $message) = @_;

	# Entry: target and message must be defined scalars
	# Exit: mock layer installed for target, no return value
	# Side effects: modifies symbol table via mock()
	# Notes: exception is thrown with croak semantics from the mocked method

	croak 'mock_exception requires a target and an exception message'
		unless defined $target && defined $message;

	my $code = sub { croak $message };	# Throw on every call

	local $Test::Mockingbird::TYPE = 'mock_exception';

	return mock($target, $code);
}

=head2 mock_sequence

Mock a method so that it returns a sequence of values over successive calls.

Takes a single target (either C<'Pkg::method'> or C<('Pkg','method')>) and
one or more values. Returns nothing. Side effects: installs a mock layer
using C<mock>. When the sequence is exhausted, the last value is repeated.

=head3 API specification

=head4 Input

Params::Validate::Strict schema:

- C<target>: required, scalar, string; method target in shorthand or longhand form
- C<values>: required, array; one or more values to be returned in order

=head4 Output

Returns::Set schema:

- C<return>: undef

=cut

sub mock_sequence {
	my ($target, @values) = @_;

	# Entry: target defined, at least one value provided
	# Exit: mock layer installed for target, no return value
	# Side effects: modifies symbol table via mock()
	# Notes: last value is repeated once the sequence is exhausted

	croak 'mock_sequence requires a target and at least one value'
		unless defined $target && @values;

	my @queue = @values;	# Local copy of the sequence

	my $code = sub {
		# If only one value remains, repeat it
		return $queue[0] if @queue == 1;
		return shift @queue;
	};

	local $Test::Mockingbird::TYPE = 'mock_sequence';

	return mock($target, $code);
}

=head2 mock_once

Install a mock that is executed exactly once. After the first call, the
previous implementation is automatically restored. This is useful for
testing retry logic, fallback behaviour, and state transitions.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar, string; method target in shorthand or longhand form
- C<code>: required, coderef; mock implementation to run once

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub mock_once {
	my ($target, $code) = @_;

	# Entry criteria:
	# - target must be defined
	# - code must be a coderef
	croak 'mock_once requires a target and a coderef'
		unless defined $target && ref($code) eq 'CODE';

	# Parse target using existing logic
	my ($package, $method) = _parse_target($target);
	my $full_method = "${package}::$method";

	# Capture original implementation before installing the wrapper
	my $orig;
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		$orig = \&{$full_method};
	}

	# Install a wrapper that:
	# - runs the mock once
	# - restores the original
	# - delegates all subsequent calls to the original
	my $wrapper = sub {
		# Run the mock implementation
		my @result = $code->(@_);

		# Restore the previous implementation
		Test::Mockingbird::unmock($package, $method);

		# Return the mock's result
		return wantarray ? @result : $result[0];
	};

	local $Test::Mockingbird::TYPE = 'mock_once';

	# Install the wrapper as a mock layer
	return mock $target => $wrapper;
}

=head2 restore

Restore all mock layers for a single method target. This is similar to
C<restore_all>, but applies only to one method. If the method was never
mocked, this routine has no effect.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar, string; method target in shorthand or longhand form

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub restore {
	my $target = $_[0];

	# Entry criteria:
	# - target must be defined
	croak 'restore requires a target' unless defined $target;

	# Parse target using existing logic
	my ($package, $method) = _parse_target($target);
	my $full_method = "${package}::$method";

	# Exit early if nothing to restore
	return unless exists $mocked{$full_method};

	# Restore all layers for this method
	while (@{ $mocked{$full_method} }) {
		my $prev = pop @{ $mocked{$full_method} };

		if (defined $prev) {
			# Restore previous coderef
			no warnings 'redefine';
			{
				## no critic (ProhibitNoStrict)
				no strict 'refs';
				*{$full_method} = $prev;
			}
		} else {
			# Original method did not exist -- remove glob
			{
				## no critic (ProhibitNoStrict)
				no strict 'refs';
				delete ${"${package}::"}{$method};
			}
		}
	}

	# Clean up tracking
	delete $mocked{$full_method};
	delete $mock_meta{$full_method};

	return;
}

=head2 diagnose_mocks

Return a structured hashref describing all currently active mock layers.
This routine is purely observational and does not modify any state.

=head3 API specification

=head4 Input

Params::Validate::Strict schema:

- none

=head4 Output

Returns::Set schema:

- C<return>: hashref; keys are fully qualified method names, values are
  hashrefs containing:
  - C<depth>: integer; number of active mock layers
  - C<layers>: arrayref of hashrefs; each layer has:
      - C<type>: string
      - C<installed_at>: string
  - C<original_existed>: boolean

=cut

sub diagnose_mocks {
	# Entry: none
	# Exit: structured hashref describing all active mocks
	# Side effects: none
	# Notes: purely observational

	my %report;

	for my $full_method (sort keys %mocked) {
		$report{$full_method} = {
			depth            => scalar @{ $mocked{$full_method} },
			layers           => [ @{ $mock_meta{$full_method} // [] } ],
			original_existed => defined $mocked{$full_method}[0] ? 1 : 0,
		};
	}

	return \%report;
}

=head2 diagnose_mocks_pretty

Return a human-readable string describing all currently active mock layers.
This routine is purely observational and does not modify any state.

=head3 API specification

=head4 Input

Params::Validate::Strict schema:

- none

=head4 Output

Returns::Set schema:

- C<return>: scalar string; formatted multi-line description of all active
  mock layers, including:
  - fully qualified method name
  - depth (number of active layers)
  - whether the original method existed
  - each layer's type and installation location

=head3 Behaviour

=head4 Entry

- No arguments are accepted.

=head4 Exit

- Returns a formatted string describing the current mocking state.

=head4 Side effects

- None. This routine does not modify C<%mocked>, C<%mock_meta>, or any
  symbol table entries.

=head4 Notes

- This routine is intended for debugging and diagnostics. It is safe to
  call at any point during a test run.
- The output format is stable and suitable for human inspection, but not
  guaranteed to remain fixed for machine parsing.

=cut

sub diagnose_mocks_pretty {
	# Entry: none
	# Exit: formatted string
	# Side effects: none
	# Notes: uses diagnose_mocks() internally

	my $diag = diagnose_mocks();
	my @out;

	for my $full_method (sort keys %$diag) {
		my $entry = $diag->{$full_method};

		push @out, "$full_method:";
		push @out, "  depth: $entry->{depth}";
		push @out, "  original_existed: $entry->{original_existed}";

		for my $layer (@{ $entry->{layers} }) {
			push @out, sprintf(
				"  - type: %-14s installed_at: %s",
				$layer->{type},
				$layer->{installed_at},
			);
		}

		push @out, '';
	}

	return join "\n", @out;
}

sub _parse_target {
	my ($arg1, $arg2, $arg3) = @_;

	# Shorthand: a single 'Pkg::method' string with no second argument.
	# The original check used !defined $arg3, which was too permissive:
	# spy('A::B','method') has arg3 undef but arg2 defined, and must NOT
	# be treated as shorthand.  The correct discriminator is !defined $arg2.
	if (defined $arg1 && !defined $arg2 && $arg1 =~ /^(.*)::([^:]+)$/) {
		return ($1, $2);
	}

	# Longhand: ('Pkg','method') or any other multi-argument form
	return ($arg1, $arg2);
}

sub _get_prototype {
	my $full = $_[0];

	croak "Invalid fully-qualified name '$full'"
		unless $full =~ /^[A-Za-z_]\w*(?:::\w+)+$/;

	my ($pkg, $sub) = $full =~ /^(.*)::([^:]+)$/;

	my $code = $pkg->can($sub) or return;

	return prototype($code);
}

=head2 DESTROY

If C<Test::Mockingbird> goes out of scope, restore everything.

=cut

sub DESTROY
{
	restore_all();
}

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-test-mockingbird at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::Mockingbird

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<Test::Mockingbird::DeepMock>

=item * L<Test::Mockingbird::TimeTravel>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

=cut

1;

package Test::Mockingbird::Guard;

# ----------------------------------------------------------------------
# NAME
#     Test::Mockingbird::Guard
#
# PURPOSE
#     Guard object returned by mock_scoped.  Holds one or more fully
#     qualified method names and unmocks all of them when destroyed.
#
# NOTES
#     Constructor accepts a list so that a single mock_scoped call can
#     cover multiple methods while still returning one guard.
# ----------------------------------------------------------------------

sub new {
	my ($class, @full_methods) = @_;

	# Entry: at least one fully qualified method name required
	return bless { full_methods => \@full_methods }, $class;
}

sub DESTROY {
	my $self = $_[0];

	# Unmock every method this guard is responsible for
	Test::Mockingbird::unmock($_) for @{ $self->{full_methods} };
}

1;
