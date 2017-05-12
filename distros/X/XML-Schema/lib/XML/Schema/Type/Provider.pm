#============================================================= -*-perl-*-
#
# XML::Schema::Type::Provider
#
# DESCRIPTION
#   Module implementing a mixin object class for providing type
#   management facilities within a particular scope.
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
#   $Id: Provider.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Type::Provider;

use strict;
use XML::Schema;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';


@OPTIONAL  = qw( parent );


#------------------------------------------------------------------------
# init_types(\%config)
#
# Initialiser method called by base class new() constructor method.
#------------------------------------------------------------------------

sub init_types {
    my ($self, $config) = @_;
    my $types;

    $self->{ _FACTORY } = $config->{ FACTORY } 
	|| $XML::Schema::FACTORY;

    $self->{ _TYPES } = { };

    return $self;
}


#------------------------------------------------------------------------
# types()
# 
# Return reference to hash array of internal type definitions.
#------------------------------------------------------------------------

sub types {
    my $self = shift;
    return $self->{ _TYPES };
}


#------------------------------------------------------------------------
# type($name)
# type($name, $type_obj)
#
# Direct way to fetch/store types against names.
#------------------------------------------------------------------------

sub type {
    my $self = shift;
    my $name = shift;
    my ($type, $scope, $factory, $simple, $class);

    return ($self->{ _TYPES }->{ $name } = shift)
	if @_;

    return $type
	if ($type = $self->{ _TYPES }->{ $name });

    # delegate to any defined 'scope' if type not found
    if ($scope = $self->{ scope }) {
	$self->TRACE("delegating $name to $scope") if $DEBUG;
	return $scope->type($name)
	    || $self->error($scope->error());
    }

    # otherwise look for it as a builtin simple type
    $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    $simple = $factory->module('simple')
	|| return $self->error($factory->error());
    
    if ($class = $simple->builtin($name)) {
	return $class->new()
	    || $self->error($class->error());
    }
    else {
	return $self->error("no such type: $name");
    }
}



#------------------------------------------------------------------------
# simpleType(\%type_options)
#
# Method for creating a simpleType object and adding it to the internal
# type definition facility.
#------------------------------------------------------------------------

sub simpleType {
    my $self = shift;
    my $factory = $self->{ _FACTORY };
    my ($name, $args, $type);

    if (ref $_[0]) {
	# hash array or simple type object
	$args = shift;
    }
    elsif (scalar @_ == 1) {
	# name requesting specific type
	$name = shift;
	return $self->type($name);
    }
    else {
	$args = { @_ };
    }

    if ($factory->isa( simple => $args )) {
	$type = $args;
    }
    else {
	$type = $factory->create( simple => $args )
	    || return $self->error( $factory->error() );
    }
    defined ($name = $type->name())
	|| return $self->error('no name specified for simpleType');

    $self->TRACE("name => ", $type->ID) if $DEBUG;

    return $self->type($name => $type);
}


#------------------------------------------------------------------------
# complexType(\%type_options)
#
# Method for creating a complexType object and adding it to the internal
# type definition facility.
#------------------------------------------------------------------------

sub complexType {
    my $self = shift;
    my $factory = $self->{ _FACTORY };
    my ($name, $args, $type);

    if (ref $_[0]) {
	# hash array or complex type object
	$args = shift;
    }
    elsif (scalar @_ == 1) {
	# name requesting specific type
	$name = shift;
	return $self->type->{ $name };
    }
    else {
	$args = { @_ };
    }

    if ($factory->isa( complex => $args )) {
	$type = $args;
	# define scope of complex type unless already set
	$type->scope($self)
	    unless defined $type->scope();

    }
    else {
	# define scope of complex type unless already set
	$args->{ scope } = $self 
	    if UNIVERSAL::isa($args, 'HASH') 
		&& ! exists $args->{ scope };

	$type = $factory->create( complex => $args )
	    || return $self->error( $factory->error() );
    }
    defined ($name = $type->name())
	|| return $self->error('no name specified for complexType');

    $self->TRACE("name => ", $type->ID) if $DEBUG;

    return $self->type($name => $type);

}


1;

