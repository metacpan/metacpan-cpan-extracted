#line 1
package File::HomeDir::Unix;

# See POD at the end of the file for documentation

use 5.00503;
use strict;
use Carp                  ();
use File::HomeDir::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.00';
	@ISA     = 'File::HomeDir::Driver';
}





#####################################################################
# Current User Methods

sub my_home {
	my $class = shift;
	my $home  = $class->_my_home(@_);

	# On Unix in general, a non-existant home means "no home"
	# For example, "nobody"-like users might use /nonexistant
	if ( defined $home and ! -d $home ) {
		$home = undef;
	}

	return $home;
}

sub _my_home {
	my $class = shift;
	if ( exists $ENV{HOME} and defined $ENV{HOME} ) {
		return $ENV{HOME};
	}

	# This is from the original code, but I'm guessing
	# it means "login directory" and exists on some Unixes.
	if ( exists $ENV{LOGDIR} and $ENV{LOGDIR} ) {
		return $ENV{LOGDIR};
	}

	### More-desperate methods

	# Light desperation on any (Unixish) platform
	SCOPE: {
		my $home = (getpwuid($<))[7];
		return $home if $home and -d $home;
	}

	return undef;
}

# On unix by default, everything is under the same folder
sub my_desktop {
	shift->my_home;
}

sub my_documents {
	shift->my_home;
}

sub my_data {
	shift->my_home;
}

sub my_music {
	shift->my_home;
}

sub my_pictures {
	shift->my_home;
}

sub my_videos {
	shift->my_home;
}





#####################################################################
# General User Methods

sub users_home {
	my ($class, $name) = @_;

	# IF and only if we have getpwuid support, and the
	# name of the user is our own, shortcut to my_home.
	# This is needed to handle HOME environment settings.
	if ( $name eq getpwuid($<) ) {
		return $class->my_home;
	}

	SCOPE: {
		my $home = (getpwnam($name))[7];
		return $home if $home and -d $home;
	}

	return undef;
}

sub users_desktop {
	shift->users_home(@_);
}

sub users_documents {
	shift->users_home(@_);
}

sub users_data {
	shift->users_home(@_);
}

sub users_music {
	shift->users_home(@_);
}

sub users_pictures {
	shift->users_home(@_);
}

sub users_videos {
	shift->users_home(@_);
}

1;

#line 186
