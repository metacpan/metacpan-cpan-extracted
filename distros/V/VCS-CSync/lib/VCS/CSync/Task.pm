package VCS::CSync::Task;

# Creates a single task

use strict;
use UNIVERSAL    'isa';
use Params::Util '_HASH';
use File::Spec   ();
use File::Flat   ();
use VCS::CSync   ();
use overload 'bool' => sub () { 1 },
             '""'   => 'dest';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $dest  = defined $_[0] ? shift : return undef;
	my $hash  = _HASH(shift) or return undef;

	# Some minor prep
	$dest =~ s/^\s+//;
	$dest =~ s/\s+$//;

	# Create the empty object
	my $self = bless {
		dest => $dest,
		}, $class;

	# Does the task need to be done as a specific user
	if ( $hash->{user} ) {
		unless ( defined scalar(getpwnam($hash->{user})) ) {
			# User does not exist on local system
			return error(
				"User '$hash->{user}' does not exist on this host"
				);
		}
		$self->{user} = $hash->{user};
	}

	# Get the driver for the task
	my $driver = lc $hash->{driver} or return error(
		"Missing configuration value 'driver'"
		);
	if ( $driver eq 'cvs' ) {
		return $self->cvs_init( $hash );
	} elsif ( $driver eq 'svn' ) {
		return $self->svn_init( $hash );
	}

	# Unsupported driver '$hash->{driver}'
	return error(
		"Unknown or unsupported driver '$hash->{driver}'"
		);
}

sub user   { $_[0]->{user}   }
sub dest   { $_[0]->{dest}   }
sub driver { $_[0]->{driver} }





#####################################################################
# Main Methods

sub run {
	my $self = shift;

	# Check the destination
	unless ( $self->dest_ok ) {
		return error("Task $self: Failed destination check");
	}
	unless ( $self->user_ok ) {
		return error("Task $self: Failed user check");
	}

	# Do the initial export
	unless ( $self->export ) {
		return error("Task $self: Failed to export from the repository");
	}

	# Overwrite to the destination
	unless ( $self->overwrite ) {
		return error("Task $self: Failed to move the export directory to the destination");
	}

	1;
}

sub export {
	my $self = shift;
	my $to   = $self->export_dest;

	if ( -e $to ) {
		trace( "Removing export directory '$to'" );
		File::Flat->remove( $to ) or return error(
			"Failed to remove existing export directory"
			);
	}

	if ( $self->driver eq 'cvs' ) {
		return $self->cvs_export($to);
	} elsif ( $self->driver eq 'svn' ) {
		return $self->svn_export($to);
	}

	die "VCS::CSync::Task->export called for unknown driver";
}

sub overwrite {
	my $self = shift;
	my $from = $self->export_dest;
	my $to   = $self->dest;

	# Remove the old version of the directory
	shell( "chmod -R u+w $to" ) or return '';
	File::Flat->remove( $to )
		or return error("Failed to remove existing directory '$to'" );

	# Move in the new version
	File::Flat->move( $from, $to )
		or return error("Failed to overwrite '$to' with '$from'");

	# Update the permissions to reflect the read-only nature of the files
	shell( "chmod -R a-w $to/*"  ) or return '';
	shell( "chmod -R a+rX $to" ) or return '';

	1;
}





#####################################################################
# Support Methods

# For now, only export to dests that already exist
sub dest_ok {
	my $self = shift;
	my $dest = $self->dest;
	unless ( -e $dest ) {
		return error("Destination directory '$dest' does not exist");
	}
	unless ( -d $dest ) {
		return error("A non-directory exists where expecting directory '$dest'");
	}
	unless ( (stat($dest))[4] == $< ) {
		return error("Current user does not own directory '$dest'");
	}
	return 1;
}

sub user_ok {
	my $self = shift;
	my $user = $self->{user} or return 1;
	my $uid  = getpwnam($user) or die "User '$user' does not exist";
	unless ( $< == $uid ) {
		return error("Task '$self' can only be run by user '$self->{user}'");
	}
	1;
}

# The directory to do the initial export to
sub export_dest {
	my $self = shift;
	$self->dest . '.new';
}

# Trace message.
# Pass it straight on to the main trace function
sub trace {
	# (works as function or method)
	shift if isa($_[0], __PACKAGE__);
	VCS::CSync::trace( @_ );
}

# Error message.
sub error {
	shift if isa($_[0], __PACKAGE__);
	VCS::CSync::error( @_ );
}

# Execute a shell command
sub shell {
	shift if isa($_[0], __PACKAGE__);
	VCS::CSync::shell( @_ );
}





#####################################################################
# CVS Support

sub cvs_init {
	my $self = shift;
	my $hash = _HASH(shift) or return undef;

	# They must have a CVSROOT
	$self->{cvsroot} = $hash->{cvsroot} or return error(
		"Missing configuration value 'cvsroot'"
		);

	# They must have a module
	$self->{cvspath} = $hash->{module} or return error(
		"Missing configuration value 'module'"
		);

	# They can optionally have a revision
	if ( $hash->{tag} ) {
		$self->{cvstag} = $hash->{tag};
	} else {
		$self->{cvstag} = 'HEAD';
	}

	$self->{driver} = 'cvs';

	$self;
}

sub cvs_export {
	my $self     = shift;
	my $to       = shift or die "No dir passed to ->cvs_export";
	my $CVSROOT  = $self->{cvsroot}   or die "cvsroot is missing";
	my $module   = $self->{cvspath}   or die "cvspath is missing";
	my $revision = $self->{cvstag}    or die "cvstag is missing";

	# Determine the command to execute
	my ($parent, $dir) = _split_dir( $to );
	-d $parent or die "Directory '$parent' does not exist";
	$dir or die "Do not have directory";
	my $quiet = $VCS::CSync::VERBOSE ? '-q' : '-Q';
	my $cmd   = "cd $parent; ";
	$cmd     .= "cvs -d $CVSROOT $quiet export -r $revision -d $dir $module";

	shell( $cmd, "Failed to export module '$module' to directory '$to'" ) or return undef;
	unless ( -d $to ) {
		return error("Export did not actually create directory $to");
	}

	1;
}

sub _split_dir {
	my $dir = shift;
	my @parts = File::Spec->splitdir( $dir );
	my $end = pop @parts;
	return ( File::Spec->catdir(@parts), $end );
}





#####################################################################
# Subversion Support

sub svn_init {
	my $self = shift;
	my $hash = _HASH(shift) or return undef;

	die "SVN driver is not yet implemented";

	# They must have a URL
	$self->{url} = $hash->{url} or return undef;

	$self->{driver} = 'svn';

	$self;
}

sub svn_export {
	my $self = shift;
	my $dir  = shift or die "No dir passed to ->svn_export";
	error("Export functionality for the SVN driver has not been implemented");
}

1;
