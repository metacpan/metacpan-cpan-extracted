#============================================================= -*-perl-*-
#
# XML::Schema::Scoped
#
# DESCRIPTION
#   Module implementing a mixin/base class for providing type
#   management facilities by delegation to an enclosing scope.
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
#   $Id: Scoped.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Scoped;

use strict;
use XML::Schema;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( type );
@OPTIONAL  = qw( scope );


#------------------------------------------------------------------------
# init(\%config)
#
# Initialiser method called by base class new() constructor method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    my ($mand, $option) 
	= @{ $self->_baseargs( qw( @MANDATORY %OPTIONAL ) ) };

    $self->_mandatory($mand, $config)
	|| return if @$mand;

    $self->_optional($option, $config)
	|| return;

    $self->{ _FACTORY } = $config->{ FACTORY } 
	|| $XML::Schema::FACTORY;

    return $self;
}


#------------------------------------------------------------------------
# type($name)
#
# Return current type object, querying current scope to retrieve
# object against a name if necessary.  This effectively implements
# lazy evaluation of type names.  In other words, it allows an element
# to specify that it uses type 'fooType' before that type is defined.
# The type() method provides the automatic resolution of type names to
# type objects by querying the scope object, i.e. the containing schema
# or complexType in which the 'fooType' should be defined.
#------------------------------------------------------------------------

sub type {
    my ($self, $name) = @_;
    $name = $self->{ type } unless defined $name;

    $self->TRACE("name => ", $name) if $DEBUG;

    return $self->error('no type name specified')
	unless defined $name;

    # type may already be a type object
    return $name if ref $name;

    # delegate to any defined 'scope' if type not found
    if (my $scope = $self->{ scope }) {
	$self->TRACE("delegating $name to $scope\n") if $DEBUG;

	return $scope->type($name)
	    || $self->error($scope->error());
    }

    # otherwise look for it as a builtin simple type
    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    my $simple = $factory->module('simple')
	|| return $self->error($factory->error());
    
    if (my $class = $simple->builtin($name)) {
	return $class->new()
	    || $self->error($class->error());
    }
    else {
	return $self->error("no such type: $name");
    }

    # otherwise query scope    
#    my $scope = $self->{ scope }
#        || return $self->error("no type definition scope defined");

#    return $scope->type($name)
#	|| $self->error($scope->error());
}


#------------------------------------------------------------------------
# typename($name)
#
# Return name of current type object.  If the type is already an object
# reference then its name() method is called, otherwise the type name
# is returned intact.
#------------------------------------------------------------------------

sub typename {
    my ($self, $name) = @_;
    $name = $self->{ type } unless defined $name;

    return $self->error('no type specified')
	unless defined $name;

    # type may be an object ref
    $name = $name->name() if ref $name && UNIVERSAL::can($name, 'name');

    return $name;
}


#------------------------------------------------------------------------ 
# scope($newscope)
# 
# Accessor method to retrieve the current scope object (when called 
# without arguments) or to define a new scope object.  The scope should
# be a reference to an object derived from the XML::Schema::Scope base
# class, ensuring it implements the facility to store and retrieve
# type objects (definitions) against names.
#------------------------------------------------------------------------

sub scope {
    my $self = shift;
    return @_ ? ($self->{ scope } = shift) : $self->{ scope };
}


1;

__END__

