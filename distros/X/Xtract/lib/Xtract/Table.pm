package Xtract::Table;

# Object that represents a single table in the destination database.

use 5.008005;
use strict;
use Params::Util   ();
use Xtract::Column ();

our $VERSION = '0.16';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( Params::Util::_IDENTIFIER($self->name) ) {
		my $name = $self->name;
		Carp::croak("Missing or invalid name '$name'");
	}
	unless ( $self->name eq lc $self->name ) {
		$self->{name} = lc $self->name;
	}
	unless ( Params::Util::_INSTANCE($self->scan, 'Xtract::Scan') ) {
		Carp::croak("Param 'scan' is not a 'Xtract::Scan' object");
	}

	# Capture column information
	my @columns = $self->columns;
	

	return $self;
}

sub name {
	$_[0]->{name};
}

sub scan {
	$_[0]->{scan};
}





######################################################################
# Introspection Methods

sub columns {
	
}





######################################################################
# SQL Generation

sub create {

}

1;
