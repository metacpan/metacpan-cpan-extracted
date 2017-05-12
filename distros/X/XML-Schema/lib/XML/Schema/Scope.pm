#============================================================= -*-perl-*-
#
# XML::Schema::Scope
#
# DESCRIPTION
#   Module implementing a mixin object class for providing type
#   management within a particular scope.
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
#   $Id: Scope.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Scope;

use strict;
use XML::Schema;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@OPTIONAL  = qw( scope );


#------------------------------------------------------------------------
# init(\%config)
#
# Initialiser method called by base class new() constructor method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->init_mandopt($config)
	|| return;

    $self->{ _FACTORY } ||= $XML::Schema::FACTORY;

    # need to think about instantiating objects for types?
    $self->{ _TYPES } = $config->{ types } || { };

    # ditto for attribute_groups?
    $self->{ _ATTRIBUTE_GROUPS } = { };

    return $self;
}



#========================================================================
# Type management methods
#
# * type($name)
#   type($type_obj)
#
# * types()
#
# * simpleType(\%type_options)
#
# * complexType(\%type_options)
#
#========================================================================

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
# types()
# 
# Return reference to hash array of internal type definitions.
#------------------------------------------------------------------------

sub types {
    my $self = shift;
    return $self->{ _TYPES };
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



#========================================================================
# Element management methods
#========================================================================

sub element {
    my $self = shift;
    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    if (@_) {
	if ($factory->isa( element => $_[0] )) {
	    $self->TRACE("returning element") if $DEBUG;
	    return shift;
	}
	else {
	    my $args = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
	    $args->{ scope } = $self unless exists $args->{ scope };
	    $self->TRACE("creating element") if $DEBUG;
	     return $factory->create( element => $args )
		 || $self->error($factory->error());
	}
    }
    else {
	return $self->error("no element arguments");
    }
}


#========================================================================
# Attribute Group management methods
#========================================================================


#------------------------------------------------------------------------
# attribute_group()
# attribute_group($new_group)
#------------------------------------------------------------------------

sub attribute_group {
    my ($self, $group) = @_;
    my $name;

    # return entire hash if called with no arguments
    return $self->{ _ATTRIBUTE_GROUPS }
        unless defined $group;

    # create and register new attribute group if group is a reference to 
    # a group object or hash of configuration options for an attribute
    # group, otherwise...

    if (ref $group) {
	my $factory = $self->factory();

	# coerce into attribute group object, if not already so
	$group = $factory->create( attribute_group => $group )
	    || return $self->error( $factory->error() )
		unless $factory->isa( attribute_group => $group );
	
	# by what name should we reference this group?
	$name = $group->name();

	return $self->error("no name specified for attribute group")
	    unless defined $name;

	# install it
	$self->{ _ATTRIBUTE_GROUPS }->{ $name } = $group;
    }
    else {
	$name = $group;
	$group = $self->{ _ATTRIBUTE_GROUPS }->{ $name }
	    || return $self->error("no such attribute group: $name");
    }

    return $group;
}



1;

__END__

