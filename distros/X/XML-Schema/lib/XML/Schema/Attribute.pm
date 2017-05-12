#============================================================= -*-perl-*-
#
# XML::Schema::Attribute.pm
#
# DESCRIPTION
#   Module implementing a base class for XML Schema attributes.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Attribute.pm,v 1.3 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Attribute;

use strict;

use XML::Schema::Scoped;
use XML::Schema::Scheduler;
use XML::Schema::Constants qw( :attribs );

use base qw( XML::Schema::Scoped XML::Schema::Scheduler );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

# mandatory 'type' implied by XML::Schema::Scoped base class
@MANDATORY = qw( name ); 
# optional 'scope' implied by XML::Schema::Scoped base class
@OPTIONAL  = qw( namespace annotation );
@SCHEDULES = qw( instance );


#------------------------------------------------------------------------
# build regexen to match valid constraints values
#------------------------------------------------------------------------

my @constraints = ( FIXED, DEFAULT );
my $constraints_regex = join('|', @constraints);
   $constraints_regex = qr/^$constraints_regex$/;



#------------------------------------------------------------------------
# init()
#
# Initiliasation method called by base class new() constructor.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($value);

    # call base class (XML::Schema::Scoped) initialiser
    $self->SUPER::init($config)
	|| return;

    # call XML::Schema::Scheduler initialiser
    $self->init_scheduler($config)
	|| return;

    # set value constraint specified as any of the config
    # options: fixed, default or constraint
    $self->{ constraint } = [ ];

    # it easy to forget if it's 'constrain' or 'constraint'
    $self->{ constraint } ||= $self->{ constrain };

    if (defined ($value = $config->{ fixed })) {
	$self->fixed($value) || return;
    }
    elsif (defined ($value = $config->{ default })) {
	$self->default($value) || return;
    }
    elsif (defined ($value = $config->{ constraint })) {
	return $self->error('constraint value must be an array ref')
	    unless UNIVERSAL::isa($value, 'ARRAY');
	$self->constraint(@$value) || return;
    }

    return $self;
}


#------------------------------------------------------------------------
# name()
# 
# Simple accessor method to return name value.
#------------------------------------------------------------------------

sub name {
    my $self = shift;
    return $self->{ name };
}


#------------------------------------------------------------------------
# namespace( $namespace )
# 
# Simple accessor method to return existing namespace value or set new
# namespace when called with an argument.
#------------------------------------------------------------------------

sub namespace {
    my $self = shift;
    return @_ ? ($self->{ namespace } = shift) : $self->{ namespace };
}


#------------------------------------------------------------------------
# constrain( default => 'some_value'  )  # set default constraint
# constrain('default')                   # fetch default constraint
# constrain( fixed   => 'other_value' )  # set fixed value constraint
# constrain('fixed')                     # fetch fixed value constraint
# ($type, $value) = constraint()          # fetch current type/value
#
# Fetch or store a value constraint as a pair of ($type, $value) where 
# type must be one of 'fixed' or 'default'.
#------------------------------------------------------------------------

*constraint = \&constrain;	# use typos;   :-)

sub constrain {
    my $self = shift;

    if (@_) {
	my $type = lc shift;
	return $self->error_value('constraint type', $type, @constraints)
	    unless $type =~ $constraints_regex;
	$self->$type(@_);
    }
    else {
	return @{ $self->{ constraint } };
    }
}


#------------------------------------------------------------------------
# default()
# default($value)
#
# Get/set default value constraint.
#------------------------------------------------------------------------

sub default {
    my $self = shift;

    if (@_) {
	my $value = shift;
	return $self->error('no default value specified')
	    unless defined $value;
	$self->{ constraint } = [ default => $value ];
    }
    elsif ($self->{ constraint }->[0] eq DEFAULT) {
	return $self->{ constraint }->[1];
    }
    else {
	return $self->error('attribute does not define a default value');
    }
}


#------------------------------------------------------------------------
# fixed()
# fixed($value)
#
# Get/set fixed value constraint.
#------------------------------------------------------------------------

sub fixed {
    my $self = shift;

    if (@_) {
	my $value = shift;
	return $self->error('no fixed value specified')
	    unless defined $value;
	$self->{ constraint } = [ fixed => $value ];
    }
    elsif ($self->{ constraint }->[0] eq FIXED) {
	return $self->{ constraint }->[1];
    }
    else {
	return $self->error('attribute does not define a fixed value');
    }
}



#------------------------------------------------------------------------
# instance($value)
#------------------------------------------------------------------------

sub instance {
    my ($self, $value, $xml_instance) = @_;
    my $constraint = $self->{ constraint };
    my $result;

    # fetch type object via local scope
    my $type = $self->type()
	|| return;

    # accept DEFAULT or FIXED value if none was provided
    unless (defined $value) {
	if ($constraint->[0]) {
	    $value = $constraint->[1];
	}
	else {
	    # NOTE: it's important not to change this error message
	    # as the parent attribute group calling it looks for it
	    return $self->error('no value provided');
	}
    }

    # instantiate the type
    my $infoset = $type->instance($value, $xml_instance)
	|| return $self->error( $type->error() );

    # check any FIXED constraint against post-validation (but pre-activation) result
    if (@$constraint && $constraint->[0] eq FIXED) {
	return $self->error("value does not match FIXED value of ", $constraint->[1])
	    unless $infoset->{ value } eq $constraint->[1];
    }

    # TODO: what about ID and IDREF?
    $self->DEBUG("attribute magic: @{ $infoset->{ magic } }\n") 
	if $DEBUG && $infoset->{ magic };

    $self->activate_instance($infoset)
	|| return;
#	|| return if @{ $self->{ _SCHEDULE_instance } };


    return wantarray ? @$infoset{ qw( result magic ) }
	             :  $infoset->{ result };
	
}    



1;

__END__

