package Test::File::Cleaner::State;

=pod

=head1 NAME

Test::File::Cleaner::State - State information for Test::File::Cleaner

=head1 DESCRIPTION

A Test::File::Cleaner::State object stores the state information for a single
file or directory, and performs tasks to restore old states.

=head1 METHODS

=cut

use 5.005;
use strict;
use File::stat ();

use vars qw{$VERSION $DEBUG};
BEGIN {
	$VERSION = '0.03';
	*DEBUG   = *Test::File::Cleaner::DEBUG;
}

=pod

=head2 new $file

Creates a new State object for a given file name. The file or directory must
exist.

Returns a new Test::File::Cleaner::State object, or dies on error.

=cut

sub new {
	my $class = ref $_[0] || $_[0];
	my $path  = -e $_[1] ? $_[1]
		: die "Tried to create $class object for non-existant file '$_[1]'";
	my $Stat = File::stat::stat( $path )
		or die "Failed to get a stat on '$path'";

	# Create the basic object
	return bless {
		path => $path,
		dir  => -d $path,
		Stat => $Stat,
		}, $class;
}





#####################################################################
# Accessors

=pod

=head2 path

Returns the path of the file

=cut

sub path {
	$_[0]->{path};
}

=pod

=head2 dir

Returns true if the state object is a directory

=cut

sub dir {
	$_[0]->{dir};
}

=pod

=head2 Stat

Returns the L<File::stat> object for the file

=cut

sub Stat {
	$_[0]->{Stat};
}

=pod

=head2 mode

Returns the permissions mode for the file/directory

=cut

sub mode {
	my $mode = $_[0]->{Stat}->mode;
	return undef unless defined $mode;
	$mode & 07777;
}





#####################################################################
# Action Methods

=pod

=head2 clean

Cleans the state object, by examining the new state of the file, and
reverting it to the old one if possible.

=cut

sub clean {
	my $self = shift;
	my $term = $self->dir ? "directory" : "file";
	my $path = $self->{path};

	# Does the file/dir still exist
	unless ( -e $path ) {
		Carp::croak("The original $term '$path' no longer exists");
	}

	# Is it still a file/directory?
	my $dir = -d $path;
	unless ( $dir eq $self->dir ) {
		die "File/directory mismatch for '$path'";
	}

	# Do we care about modes
	my $mode = $self->mode;
	return 1 unless defined $mode;

	# Yes, has the mode changed?
	my $mode2 = File::stat::stat($path)->mode & 07777;
	unless ( $mode == $mode2 ) {
		# Revert the permissions to match the old one
		printf( "# chmod 0%lo %s\n", $mode, $path ) if $DEBUG;
		chmod $mode, $path or die "Failed to correct permissions mode for $term '$path'";
	}

	1;
}

=pod

=head2 remove

The C<remove> method deletes a file for which we are holding a state. The
reason we provide a special method for this is that in some situations, a
file permissions may not allow us to remove it, and thus we may need to
correct it's permissions first.

=cut

sub remove {
	my $self = shift;
	my $term = $self->dir ? "directory" : "file";
	my $path = $self->{path};

	# Already removed?
	return 1 unless -e $path;

	# Write permissions means delete permissions
	unless ( -w $path ) {
		# Try to give ourself write permissions
		if ( $self->dir ) {
			print( "# chmod 0777 $path\n" ) if $DEBUG;
			chmod 0777, $path or die "Failed to get enough permissions to delete $term '$path'";
		} else {
			print( "# chmod 0666 $path\n" ) if $DEBUG;
			chmod 0666, $path or die "Failed to get enough permissions to delete $term '$path'";
		}
	}

	# Now attempt to delete it
	if ( $self->dir ) {
		print( "# rmdir $path\n" ) if $DEBUG;
		rmdir $path or die "Failed to delete $term '$path'";
	} else {
		print( "# rm $path\n" ) if $DEBUG;
		unlink $path or die "Failed to delete $term '$path'";
	}

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-File-Cleaner>

For other issues, or commercial enhancement or support, contact the author.

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
