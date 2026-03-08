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
);

# Store mocked data
my %mocked;  # becomes: method => [ stack of backups ]

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

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
	}
	# ------------------------------------------------------------
	# Original syntax:
	#   mock('My::Module', 'method', sub { ... })
	# ------------------------------------------------------------
	else {
		($package, $method, $replacement) = ($arg1, $arg2, $arg3);
	}

	croak 'Package and method are required for mocking' unless $package && $method;

	no strict 'refs'; # Allow symbolic references
	my $full_method = "${package}::$method";

	# Backup original if not already mocked
	push @{ $mocked{$full_method} }, \&{$full_method};

	# Replace with mocked version
	no warnings 'redefine';
	*{$full_method} = $replacement || sub {};
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

	my ($package, $method) = _parse_target(@_);

	croak 'Package and method are required for unmocking' unless $package && $method;

	no strict 'refs';
	my $full_method = "${package}::$method";

	# Restore original method if backed up
	if (exists $mocked{$full_method} && @{ $mocked{$full_method} }) {
		my $prev = pop @{ $mocked{$full_method} };
		no warnings 'redefine';
		*{$full_method} = $prev;

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

	no strict 'refs';
	my $full_method = "${package}::$method";

	# Backup previous layer
	push @{ $mocked{$full_method} }, \&{$full_method};

	# Data
	my @calls;

	no warnings 'redefine';
	*{$full_method} = sub {
		push @calls, [ $full_method, @_ ];

		# Call previous layer
		my $prev = $mocked{$full_method}[-1];
		return $prev->(@_);
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
	}
	# ------------------------------------------------------------
	# Original syntax:
	#   inject('My::Module', 'Dependency', $mock_obj)
	# ------------------------------------------------------------
	else {
		($package, $dependency, $mock_object) = ($arg1, $arg2, $arg3);
	}

	croak 'Package and dependency are required for injection' unless $package && $dependency;

	no strict 'refs';
my $full_dependency = "${package}::$dependency";

	# Backup original if not already mocked
	push @{ $mocked{$full_dependency} }, \&{$full_dependency};

	no warnings 'redefine';

	# Replace with the mock object
	*{$full_dependency} = sub { $mock_object };
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

	no strict 'refs';
	no warnings 'redefine';

	if (defined $arg) {
		my $package = $arg;

		for my $full_method (keys %mocked) {
			next unless $full_method =~ /^\Q$package\E::/;

			while (@{ $mocked{$full_method} }) {
				my $prev = pop @{ $mocked{$full_method} };
				*{$full_method} = $prev;
			}

			delete $mocked{$full_method};
		}

		return;
	}

	# Global restore
	for my $full_method (keys %mocked) {
		while (@{ $mocked{$full_method} }) {
			my $prev = pop @{ $mocked{$full_method} };
			*{$full_method} = $prev;
		}
	}

	%mocked = ();
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
