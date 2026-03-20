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
	restore_all
	mock_return
	mock_exception
	mock_sequence
	mock_once
);

# Store mocked data
my %mocked;  # becomes: method => [ stack of backups ]

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

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
	}
	# ------------------------------------------------------------
	# Original syntax:
	#   inject('My::Module', 'Dependency', $mock_obj)
	# ------------------------------------------------------------
	else {
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

    # Install the wrapper as a mock layer
    return mock $target => $wrapper;
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
