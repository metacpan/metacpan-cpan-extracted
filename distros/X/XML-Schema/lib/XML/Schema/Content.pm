#============================================================= -*-perl-*-
#
# XML::Schema::Content.pm
#
# DESCRIPTION
#   Module implementing a class to represent a content model being either
#   'empty', having a 'simple' type, or a pair of particle and model type,
#   which can be one of 'mixed' or 'element-only'.
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
#   $Id: Content.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Content;

use strict;
use XML::Schema;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE @ARGS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'content';
@ARGS    = qw( type content particle mixed empty );

*FACTORY = \$XML::Schema::FACTORY;


# alias min() to minOccurs() and max() to maxOccurs()
*minOccurs = \&min;
*maxOccurs = \&max;


#------------------------------------------------------------------------
# init()
#
# Called automatically by base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($type, $content, $particle, $mixed);
    my $factory = $self->{ FACTORY } ||= $config->{ FACTORY } || $XML::Schema::FACTORY;

    $self->TRACE("config => ", $config) if $DEBUG;

    $self->{ type } = undef;
#    if ($type = $config->{ type }) {
#	# simple type content
#	$self->{ type } = $type;
#	$self->TRACE("set type to $type") if $DEBUG;
#    }    
#    elsif ($particle = $config->{ particle }) {
    if ($particle = $config->{ particle }) {
	# particle specified directly, mixed flag also allowed
	$self->{ particle } = $particle;
	$self->{ mixed } = $config->{ mixed } ? 1 : 0;
    }
    elsif (! $config->{ empty }) {
	if ($particle = $factory->create( particle => $config )) {
	    # have a bash at creating a particle anyway
	    $self->{ particle } = $particle;
	}
	else {
	    my $error = $factory->error();
	    # HACK: this might be an empty/text only content model so
	    # we ignore particle errors that report a missing particle
	    return $self->error($error)
		unless $error =~ /^particle expects one of:/;
	}
    }	

    $self->{ mixed } = $config->{ mixed } ? 1 : 0;

    return $self;
}

sub model {
    my $self = shift;
    return $self->{ type } 
        || $self->{ particle }
        || $self->error("no particle defined in content model");
}

sub type {
    return $_[0]->{ type };
}

sub particle {
    my $self = shift;
    return $self->{ particle }
        || $self->error("no particle defined in content model");
}

sub args {
    return @ARGS;
}

#------------------------------------------------------------------------
# mixed($flag)
#
# Used to set (if called with an argument) or get the current value
# for the 'mixed' flag indicating if the complexType accepts mixed
# content.
#------------------------------------------------------------------------

sub mixed {
    my $self = shift;
    return @_ ? ($self->{ mixed } = shift) : $self->{ mixed };
}


#------------------------------------------------------------------------
# element_only($flag)
#
# The inverse of mixed().  Returns true if mixed is false and vice
# verse.  Can also be used to update the mixed flag wih the correct
# truth inversion performed.
#------------------------------------------------------------------------

sub element_only {
    my $self = shift;
    return @_ ? ! ($self->{ mixed } = ! shift) : ! $self->{ mixed };
}


#------------------------------------------------------------------------
# empty()
#
# Returns true if the content model is empty.
#------------------------------------------------------------------------

sub empty {
    return ($_[0]->{ type } || $_[0]->{ particle }) ? 0 : 1;
}


sub ID {
    return 'Content';
}

1;


