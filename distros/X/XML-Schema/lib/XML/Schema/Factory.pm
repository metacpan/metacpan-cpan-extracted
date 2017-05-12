#============================================================= -*-perl-*-
#
# XML::Schema::Factory
#
# DESCRIPTION
#   Factory module for managing (e.g. loading and instantiating) other
#   modules in the XML::Schema set.
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
#   $Id: Factory.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Factory;

use strict;
use vars qw( $VERSION $AUTOLOAD $DEBUG $ERROR $ETYPE $MODULES );
use base qw( XML::Schema::Base );

$VERSION  = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG    = 0 unless defined $DEBUG;
$ETYPE    = 'Factory';
$ERROR    = '';
$MODULES  = {
    # root schema object
    schema          => 'XML::Schema',

    # core XML::Schema::* objects
    attribute       => 'XML::Schema::Attribute',
    attribute_group => 'XML::Schema::Attribute::Group',
    complex         => 'XML::Schema::Type::Complex',
    content         => 'XML::Schema::Content',
    element         => 'XML::Schema::Element',
    exception       => 'XML::Schema::Exception',
    instance        => 'XML::Schema::Instance',
    model           => 'XML::Schema::Model',
    parser          => 'XML::Schema::Parser',
    particle        => 'XML::Schema::Particle',
    wildcard        => 'XML::Schema::Wildcard',
    simple          => 'XML::Schema::Type::Simple',
    # particle objects
    element_particle  => 'XML::Schema::Particle::Element',
    sequence_particle => 'XML::Schema::Particle::Sequence',
    choice_particle   => 'XML::Schema::Particle::Choice',
    model_particle    => 'XML::Schema::Particle::Model',
    # parser handlers
    schema_handler    => 'XML::Schema::Handler::Schema',
    simple_handler    => 'XML::Schema::Handler::Simple',
    complex_handler   => 'XML::Schema::Handler::Complex',
};


#------------------------------------------------------------------------
# init(\%config)
#
# Initialiser method called by base class new() constructor.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my $class = ref $self;
    bless { %$MODULES, %$config }, $class;
}


#------------------------------------------------------------------------
# create($module_type)
#
# Look up module name for a given type in $MODULES hash if called as a 
# class method, or $self hash if called as an object method.  Load the 
# module via load() method and then instantiate an object via new()
#------------------------------------------------------------------------

sub create {
    my $self = shift;
    my $type = shift;

    $self->DEBUG($self->ID, "->create('$type')\n")
	if $DEBUG;

    my $module;
    if (ref $self) {
	$module = $self->{ $type };
    }
    else {
	$module = $MODULES->{ $type };
    }
    return $self->error("module not recognised: '$type'")
	unless $module;

    return undef unless $self->load($module);
    return $module->new(@_) 
	|| $self->error($module->error());
}


#------------------------------------------------------------------------
# adopt($module_type, $object, \@args)
#
# Look up module name for a given type in $MODULES hash if called as a 
# class method, or $self hash if called as an object method.  Load the 
# module via load() method, rebless $object into the new module class
# then call its new init() method passing a reference to an optional 
# hash reference of configuration options.
#------------------------------------------------------------------------

sub adopt {
    my ($self, $type, $object, $config) = @_;

    $self->DEBUG($self->ID, "->adopt('$type', $object)\n")
	if $DEBUG;

    my $module;
    if (ref $self) {
	$module = $self->{ $type };
    }
    else {
	$module = $MODULES->{ $type };
    }
    return $self->error("module not recognised: '$type'")
	unless $module;

    return undef unless $self->load($module);
    bless $object, $module;

    return $object->init($config)
	|| $self->error($object->error());
}


#------------------------------------------------------------------------
# load($module)
#
# Load a module via require().  Any occurences of '::' in the module name
# are be converted to '/' and '.pm' is appended.  Returns 1 on success
# or undef on error.  Use $class->error() to examine the error string.
#------------------------------------------------------------------------

sub load {
    my ($self, $module) = @_;
    $module =~ s[::][/]g;
    $module .= '.pm';
    $self->DEBUG($self->ID, "->require('$module')\n")
	if $DEBUG;
    eval {
	require $module;
    };
    return $@ ? $self->error("failed to load $module: $@") : 1;
}


#------------------------------------------------------------------------
# isa($type, $object)
#
# Look up class name for a given type in $MODULES hash if called as a 
# class method, or $self hash if called as an object method, and check
# that $object is of, or derived from that type.
#------------------------------------------------------------------------

sub isa {
    my ($self, $type, $object) = @_;

    $self->DEBUG($self->ID, "->isa($type => ", $object->ID, ")\n")
	if $DEBUG;

    my $class;
    if (ref $self) {
	$class = $self->{ $type };
    }
    else {
	$class = $MODULES->{ $type };
    }
    return $self->error("type not recognised: '$type'")
	unless $class;

    return UNIVERSAL::isa($object, $class);
}


#------------------------------------------------------------------------
# module($name)
#
# Look up module name for a given type in $MODULES hash if called as a 
# class method, or $self hash if called as an object method.
#------------------------------------------------------------------------

sub module {
    my ($self, $name) = @_;
    my $module;

    if (ref $self) {
	$module = $self->{ $name };
    }
    else {
	$module = $MODULES->{ $name };
    }
    return $self->error("module not recognised: '$name'")
	unless $module;

    return $module;
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Map method calls of the form $modules->parser(....) to
# $modules->create('parser', ...)
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    $self->create($item, @_);
}
	
1;

