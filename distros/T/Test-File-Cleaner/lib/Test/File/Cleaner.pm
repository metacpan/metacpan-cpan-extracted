package Test::File::Cleaner;

=pod

=head1 NAME

Test::File::Cleaner - Automatically clean up your filesystem after tests

=head1 SYNOPSIS

  # Create the cleaner
  my $Cleaner = Test::File::Cleaner->new( 'file_dmz' );
  
  # Do some tests that create files
  touch 'file_dmz/foo';
  
  # Cleaner cleans when it is DESTROYed
  exit();
  
  # Alternatively, force an immediate clean up
  $Cleaner->clean;

=head1 DESCRIPTION

When writing file-related testing code, it is common to end up with a number
of files scattered all over the testing directories. If you are running the
test scripts over and over these leftover files can interfere with subsequent
test runs, and so they need to be cleaned up.

This clean up code typically needs to be done at END-time, so that the files
are cleaned up even if you break out of the test script while it is running.
The code to do this can get long and is labourious to maintain.

Test::File::Cleaner attempts to solve this problem. When you create a
Cleaner object for a particular directory, the object scans and saves the
contents of the directory.

When the object is DESTROYed, it compares the current state to the original,
and removes any new files and directories created during the testing process.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp             ();
use File::Spec       ();
use File::Basename   ();
use File::Find::Rule ();

use vars qw{$VERSION $DEBUG};
BEGIN {
	$VERSION   = '0.03';
	$DEBUG   ||= 0;
}

use Test::File::Cleaner::State ();





#####################################################################
# Constructor

=pod

=head2 new $dir

Creates a new Test::File::Cleaner object, which will automatically clean
when it is destroyed. The cleaner is passed a directory within which it
will operate, which must exist.

Since this is intended to be used in test scripts, it will die on error.
You will not need to test the return value.

=cut

sub new {
	my $class  = ref $_[0] || $_[0];
	my $path   = -d $_[1] ? $_[1]
		: Carp::croak("Test::File::Cleaner->new was not passed a directory");

	# Create the basic object
	my $self = bless {
		alive  => 1,
		path   => $path,
		state  => {},
		}, $class;

	# Populate the state
	$self->reset;

	$self;
}

sub DESTROY {
	my $self = shift;
	return 1 unless $self->{alive};
	$self->clean;
	return delete $self->{alive};
}





#####################################################################
# Main Methods

=pod

=head2 path

The C<path> accessor returns the current root path for the object.
The root path cannot be changed once the Test::File::Cleaner object has
been created.

=cut

sub path {
	$_[0]->{path};
}

=pod

=head2 clean

Calling the C<clean> method forces a clean of the directory. The Cleaner
will scan it's directory, compare what it finds with it's original scan,
and then do whatever is needed to restore the directory to its original
state.

Returns true if the Cleaner fully restores the directory, or false
otherwise.

=cut

sub clean {
	my $self = shift;

	# Fetch the new file list
	my @files = File::Find::Rule->in( $self->path );

	# Sort appropriately.
	# In this case, we MUST do files first because we arn't going to
	# be doing recursive delete of directories, and they must be clear
	# of files first.
	# We also want to be working bottom up, to help reduce the logic
	# complexity of the tests below.
	foreach ( @files ) {
		my $dir = -d $_ ? $_ : File::Basename::dirname($_);
		$_ = [ $_, -d $_, scalar File::Spec->splitdir($dir) ];
	}
	@files = map { $_->[0] }
		sort {
			$a->[1] <=> $b->[1] # Files first
			or
			$b->[2] <=> $a->[2] # Depth first
			or
			$a->[0] cmp $b->[0] # Alphabetical otherwise
		}
		@files;

	# Iterate over the files
	foreach my $file ( @files ) {
		# If it existed before, restore it's state
		my $State = $self->{state}->{$file};
		if ( $State ) {
			$State->clean;
			next;
		}

		# Was this already deleted some other way within this loop?
		next unless -e $file;

		# This file didn't exist before, delete it.
		$State = Test::File::Cleaner::State->new( $file )
			or die "Failed to get a state handle for '$file'";
		$State->remove;
	}

	1;
}

=pod

=head2 reset

The C<reset> method assumes you want to keep any changes that have been
made, and will rescan the directory and store the new state instead.

Returns true of die on error

=cut

sub reset {
	my $self = shift;

	# Catalogue the existing files
	my %state = ();
	foreach my $file ( File::Find::Rule->in($self->path) ) {
		$state{$file} = Test::File::Cleaner::State->new($file)
			or die "Failed to create state object for '$file'";
	}
	$self->{state} = \%state;

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-File-Cleaner>

For other issues, or commercial enhancement or support, contact the author..

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Thank you to Phase N Australia ( L<http://phase-n.com/> ) for permitting
the open sourcing and release of this distribution as a spin-off from a
commercial project.

=head1 COPYRIGHT

Copyright 2004 - 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
