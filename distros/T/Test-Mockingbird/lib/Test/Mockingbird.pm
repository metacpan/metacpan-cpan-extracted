package Test::Mockingbird;

use strict;
use warnings;

# TODO: Look into Sub::Install

use Carp qw(croak);
use Exporter 'import';

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
my %mocked;  # becomes: method => [ stack of backups ]
my %mock_meta;   # full_method => [ { type => ..., installed_at => ... }, ... ]

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

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

=cut

sub mock {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $replacement);

	# ------------------------------------------------------------
	# New syntax:
	#   mock 'My::Module::method' => sub { ... }
	# ------------------------------------------------------------
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		$package = $1;
		$method = $2;
		$replacement = $arg2;
	} else {
		# ------------------------------------------------------------
		# Original syntax:
		#   mock('My::Module', 'method', sub { ... })
		# ------------------------------------------------------------
		($package, $method, $replacement) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and replacement are required for mocking' unless $package && $method && $replacement;

	my $full_method = "${package}::$method";

	# Backup original if not already mocked
	push @{ $mocked{$full_method} }, \&{$full_method};

	no warnings 'redefine';

	{
		## no critic (ProhibitNoStrict)  # symbolic reference required for mocking
		no strict 'refs';
		*{$full_method} = $replacement;
	}
	my $type = $Test::Mockingbird::TYPE // 'mock';

	push @{ $mock_meta{$full_method} }, {
		type => $type,   # 'mock', 'spy', 'inject', etc.
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
}

=head2 unmock($package, $method)

Restores the original method for a mocked method.
Supports two forms:

    unmock('My::Module', 'method');

or the shorthand:

    unmock 'My::Module::method';

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

Creates a scoped mock that is automatically restored when it goes out of scope.

This behaves like C<mock>, but instead of requiring an explicit call to
C<unmock> or C<restore_all>, the mock is reverted automatically when the
returned guard object is destroyed.

This is useful when you want a mock to apply only within a lexical block:

    {
        my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
        My::Module::method();   # returns 'mocked'
    }

    My::Module::method();       # original behaviour restored

Supports both the longhand and shorthand forms:

    my $g = mock_scoped('My::Module', 'method', sub { ... });

    my $g = mock_scoped 'My::Module::method' => sub { ... };

Returns a guard object whose destruction triggers automatic unmocking.

=cut

sub mock_scoped {
	my ($arg1, $arg2, $arg3) = @_;

	# Reuse mock() to install the mock
	mock($arg1, $arg2, $arg3);

	# Determine full method name using same parsing rules

	my ($package, $method) = _parse_target(@_);

	my $full_method = "${package}::$method";

	push @{ $mock_meta{$full_method} }, {
		type => 'mock_scoped',
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
	return Test::Mockingbird::Guard->new($full_method);
}

=head2 spy($package, $method)

Wraps a method so that all calls and arguments are recorded.
Supports two forms:

    spy('My::Module', 'method');

or the shorthand:

    spy 'My::Module::method';

Returns a coderef which, when invoked, returns the list of captured calls.
The original method is preserved and still executed.

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
		type     => 'spy',
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
		$package = $1;
		$dependency = $2;
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
		type     => 'inject',
		installed_at => (caller)[1] . ' line ' . (caller)[2],
	};
}

=head2 restore_all()

Restores mocked methods and injected dependencies.

Called with no arguments, it restores everything:

    restore_all();

You may also restore only a specific package:

    restore_all 'My::Module';

This restores all mocked methods whose fully qualified names begin with
C<My::Module::>.

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
	%mocked = ();
	%mock_meta = ();
}

=head2 mock_return

Mock a method so that it always returns a fixed value.

Takes a single target (either C<'Pkg::method'> or C<('Pkg','method')>) and
a value to return. Returns nothing. Side effects: installs a mock layer
using L</mock>.

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
using L</mock>.

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

	croak 'mock_exception requires a target and an exception message' unless defined $target && defined $message;

	my $code = sub { croak $message };  # Throw on every call

	local $Test::Mockingbird::TYPE = 'mock_exception';

	return mock($target, $code);
}

=head2 mock_sequence

Mock a method so that it returns a sequence of values over successive calls.

Takes a single target (either C<'Pkg::method'> or C<('Pkg','method')>) and
one or more values. Returns nothing. Side effects: installs a mock layer
using L</mock>. When the sequence is exhausted, the last value is repeated.

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

	croak 'mock_sequence requires a target and at least one value' unless defined $target && @values;

	my @queue = @values;  # Local copy of the sequence

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
	croak 'mock_once requires a target and a coderef' unless defined $target && ref($code) eq 'CODE';

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
			# Original method did not exist — remove glob
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
			depth        => scalar @{ $mocked{$full_method} },
			layers       => [ @{ $mock_meta{$full_method} // [] } ],
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

	# Shorthand: 'Pkg::method'
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		return ($1, $2);
	}

	# Longhand: ('Pkg','method')
	return ($arg1, $arg2);
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

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;

package Test::Mockingbird::Guard;

sub new {
	my ($class, $full_method) = @_;
	return bless { full_method => $full_method }, $class;
}

sub DESTROY {
	my $self = $_[0];

	Test::Mockingbird::unmock($self->{full_method});
}

1;
