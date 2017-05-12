package Xtract::Column;

# Object that represents a single column in the destination database.

use 5.008005;
use strict;
use Carp         ();
use Params::Util ();

our $VERSION = '0.16';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	my $name = $self->name;
	unless ( Params::Util::_IDENTIFIER($name) ) {
		Carp::croak("Missing or invalid column name '$name'");
	}

	return $self;
}

1;
