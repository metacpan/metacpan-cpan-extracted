#============================================================= -*-perl-*-
#
# XML::Schema::Attribute::Group.pm
#
# DESCRIPTION
#   Module implementing an attribute group which is used by the 
#   XML::Schema::Type::Complex module to store attributes for a
#   complex type, and also to define Attribute Groups within a 
#   schema to represent relocatable collections of attributes.
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
#   $Id: Group.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Attribute::Group;

use strict;

use XML::Schema::Scope;
use XML::Schema::Attribute;
use XML::Schema::Constants qw( :attribs );

use base qw( XML::Schema::Scope );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( name ); 
@OPTIONAL  = qw( namespace annotation );


#------------------------------------------------------------------------
# build regexen to match valid attribute usage and constraints values
#------------------------------------------------------------------------

my @USE_OPTS  = ( OPTIONAL, REQUIRED, PROHIBITED );
my $USE_REGEX = join('|', @USE_OPTS);
   $USE_REGEX = qr/^$USE_REGEX$/;



#------------------------------------------------------------------------
# init(\%config)
#
# Initiliasation method called by base class new() constructor.
# A reference to a hash array of configuration options can be specified
# as shown in this example:
#
# my $group = XML::Schema::Attribute::Group->new({
#     attributes => {
#         foo => XML::Schema::Attribute->new(...),
#         bar => { name => 'bar', type => 'string' }
#         baz => { type => 'string' },	      # name implied by key 'baz'
#         baz => { type => 'string', use => REQUIRED },
#         boz => { type => 'string', required => 1 },
#         wiz => 'string',
#     },
#     default_use => OPTIONAL,
#     use => {				 # either specify use for each
#         foo => REQUIRED,
#     },
#     required => [ qw( bar baz ) ],	 # or list each type
# }
#
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($name, $value);

    $self->SUPER::init($config)
	|| return;

    my $factory = $self->factory() || return;

    my $attribs  = $config->{ attributes } || { };

    # first look for a default_use option, otherwise go with OPTIONAL
    my $default_use = $self->{ default_use } = $config->{ default_use } || OPTIONAL;

    return $self->error_value('default_use', $default_use, @USE_OPTS)
	unless $default_use =~ $USE_REGEX;

    $self->DEBUG("set default_use to $default_use\n") if $DEBUG;

    # then look for a 'use' hash array...
    my $use = $config->{ use };
    $use = { } unless ref $use eq 'HASH';
    
    # ...and check each entry is valid
    foreach $name (keys %$use) {
	return $self->error("unknown attribute in use hash: '$name'")
	    unless $attribs->{ $name };

	$value = $use->{ $name };

	# allow 0 and 1 as shorthand for OPTIONAL and REQUIRED
	$value = ($value eq '1') ? REQUIRED 
               : ($value eq '0') ? OPTIONAL : $value;

	return $self->error_value("use for attribute '$name'", $value, @USE_OPTS)
	    unless $value =~ $USE_REGEX;

	$use->{ name } = $value;
    }

    # check for required => { }, optional => { } and prohibited => { } options
    foreach my $value (@USE_OPTS) {
	my $list = $config->{ $value } || next;
	$list = [ $list ] unless ref $list eq 'ARRAY';

	foreach $name (@$list) {
	    return $self->error("unknown attribute in $value list: '$name'")
		unless $attribs->{ $name };
	    $use->{ $name } = $value;
	}
    }	

    $self->{ use } = $use;

    # coerce attributes into objects if not already so
    $self->{ attributes } = {
	 map { 
	     my $a = $attribs->{ $_ };

	     if ($factory->isa( attribute => $a )) {
		 $name = $a->name();
	     }
	     else {
		 # if it's not already an attribute object then make it so
		 $a = { type => $a } unless ref $a eq 'HASH';
		 $a->{ name  } = $_ unless defined $a->{ name };
		 $a->{ scope } = $self unless defined $a->{ scope };

		 $name = $a->{ name };

		 # allow 'required => 1' to alias for 'use => REQUIRED'
		 foreach $value (@USE_OPTS) {
		     $a->{ use } = $value if $a->{ $value };
		 }

		 # look for 'use' option
		 if (defined ($value = $a->{ use })) {
		     return $self->error_value("attribute '$name' use", $value, @USE_OPTS)
			 unless $value =~ $USE_REGEX;
		     $use->{ $name } = $value;
		 }

		 $a = $factory->create( attribute => $a );
	     }
	     $use->{ $name } = $default_use
		 unless defined $use->{ $name };
	     $self->DEBUG("set use($name) to $use->{ $name }\n") if $DEBUG;
	     ($_, $a);
	 } keys %$attribs
    };

    # look for attribute group(s)
    $self->{ groups } = [ ];
    my $groups = $config->{ groups } || [ ];
    push(@$groups, $config->{ group }) if $config->{ group };

    foreach my $group (@$groups) {
	$self->group($group)
	    || return;
    }

    # see if a wildcard is defined or something that can be coerced into one
    foreach my $item (qw( any not )) {
	$config->{ wildcard } ||= { $item => $config->{ $item } } 
	    if $config->{ $item };
    }

    my $wildcard = $config->{ wildcard };
    if ($wildcard) {
	$wildcard = $factory->create( wildcard => $wildcard )
	    || return $self->error( $factory->error() )
		unless $factory->isa( wildcard => $wildcard );
	$self->{ wildcard } = $wildcard;
    }

    return $self;
}


#------------------------------------------------------------------------
# attribute( $name )		# return named attributed
# attribute( $attr )		# add attribute
# attribute( name => $name, type => $type, ... )    # create and add
#
# Used to retrieve an existing attribute when called with a single
# non-reference argument.  Used to define a new attribute when passed
# with a single reference to an attribute object or a hash reference
# or list of arguments which are used to create a new argument via the
# factory module.  
#
# <complexType name="personType">
#   <attribute name="id" type="string"/>		
#   ...
# </complextype>
#------------------------------------------------------------------------

sub attribute {
    my $self = shift;
    my ($name, $args, $attr, $required);

    my $factory = $self->factory() 
	|| return;

    if (ref $_[0]) {
	# hash array or attribute object
	$args = shift;
    }
    elsif (scalar @_ == 1) {
	# name requesting specific attribute
	$name = shift;
	return $self->{ attributes }->{ $name }
	    || $self->error("no such attribute: $name");
    }
    else {
	$args = { @_ };
    }

    if ($factory->isa( attribute => $args )) {
	$attr = $args;
	$args = ref $_[0] eq 'HASH' ? shift : { @_ };
	# define scope of attribute unless already set
	$attr->scope($self)
	    unless defined $attr->scope();
    }
    else {
	# define scope of attribute unless already set
	$args->{ scope } = $self 
	    if UNIVERSAL::isa($args, 'HASH') 
		&& ! exists $args->{ scope };

	$attr = $factory->create( attribute => $args )
	    || return $self->error( $factory->error() );
    }
    defined ($name = $attr->name())
	|| return $self->error('no name specified for attribute');

    $self->DEBUG($self->ID, "->attribute( $name => ", $attr->ID, " )\n")
	if $DEBUG;

    $self->{ attributes }->{ $name } = $attr;
    
    $self->DEBUG("setting use for $name\n") if $DEBUG;

    # allow 'required => 1' to alias for 'use => REQUIRED'
    foreach my $usage (@USE_OPTS) {
	$args->{ use } = $usage if $args->{ $usage };
    }

    # now set usage
    $self->use( $name => $args->{ use } || $self->{ default_use } )
	|| return;

    return $attr;
}


#------------------------------------------------------------------------
# attributes()
#
# Returns reference to a hash containing all current attributes defined,
# indexed by name.
#------------------------------------------------------------------------

sub attributes {
    my $self = shift;
    return $self->{ attributes };
}


#------------------------------------------------------------------------
# group($group)
#
# Add a new attribute group as a sub-group of this group.
#------------------------------------------------------------------------

sub group {
    my ($self, $group) = @_;
    my $name;

    if (ref $group) {
	# looks like a new attribute group definition so create and 
	# register it in the current scope
	$group = $self->attribute_group($group)
	    || return;

	$name = $group->name();
    }
    else {
	# it's the name of an attribute group 
	$name = $group;
    }

    # add group name to list of sub-groups defined
    push(@{ $self->{ groups } }, $name);

    # return reference to new group or group name
    return $group;
}
	


#------------------------------------------------------------------------
# groups()
#
# Returns a reference to a list containing the names of all attribute 
# groups defined as sub-groups of this group.  To fetch a reference to
# a hash of all attribute groups defined within the current scope, 
# call attribute_group() (inherited from XML::Schema::Scope) with no
# arguments.  Call same method to define new attribute groups within
# this scope, but not directly attach them to this group.
#------------------------------------------------------------------------

sub groups {
    my $self = shift;
    return $self->{ groups };
}



#------------------------------------------------------------------------
# validate(\%attributes)
#
#------------------------------------------------------------------------

sub validate {
    my ($self, $inbound, $outbound, $scope) = @_;
    my ($name, $attr, $value, $magic, $usage, $wildcard);

    # if $outbound is undefined then we're the parent group
    my $parent = $outbound ? 0 : 1;
    $outbound ||= { };

    # if we've been called as the sub-group of some higher attribute
    # group validation then we need to bind our scope to that which
    # it passed us
    $self->{ scope } = $scope if $scope;

    my $use = $self->{ use };
    my $attributes = $self->{ attributes }
	|| return $self->error("no attributes defined");


    # walk through each of our defined attributes seeing if it
    # appears in $inbound, validate and instantiate it and copy
    # into $outbound

    keys %$attributes;	    # reset iterator

    while (($name, $attr) = each %$attributes) {

	# check usage contraints
	$usage = $use->{ $name } || $self->{ default_use };

	$self->TRACE("testing attribute $name usage $usage\n") if $DEBUG;

	if (defined ($value = $inbound->{ $name })) {
	    return $self->error("attribute '$name' is prohibited")
		if $usage eq PROHIBITED;
	}
	else {
	    return $self->error("required attribute '$name' not defined")
		if $usage eq REQUIRED;

	    # don't give PROHIBITED attributes a chance to provide defaults
	    next if $usage eq PROHIBITED;

	    # must be OPTIONAL, so it's OK that the attribute is missing
	    # next;
	}

	# instantiate attribute
	($value, $magic) = $attr->instance($value);

	if (defined $value) {
	    $outbound->{ $name } = $value;
	}
	else {
	    my $error = $attr->error();
	    return $self->error("$name attribute: $error")
		unless $usage eq OPTIONAL && $error eq 'no value provided';
	}

	if ($magic) {
	    my $list = $outbound->{ _MAGIC }->{ $magic->[0] } ||= [ ];
	    push(@$list, [ attribute => $name, $magic->[1] ]);
	    $self->DEBUG("detected '$magic->[0]' magic valued '$magic->[1]' in $name attribute\n")
		if $DEBUG;
	}

	$self->TRACE("attribute $name => ", $outbound->{ $name }) if $DEBUG;

	# all is well so delete entry from inbound hash
	delete $inbound->{ $name };
    }

    # any attributes left in the $inbound hash are those that don't
    # correspond to an attribute defined within this group.

    if (%$inbound) {
	# try delegating to any defined sub-groups
	foreach $name (@{ $self->{ groups } }) {
	    $self->TRACE("testing sub-group: $name\n") if $DEBUG;

	    # fetch attribute object from group name
	    my $group = $self->attribute_group($name)
		|| return;
	    $group->validate($inbound, $outbound, $self)
		|| return $self->error($group->error());
	}
	    

	# look for a wildcard
	if ($wildcard = $self->{ wildcard }) {
	    $self->TRACE("testing wildcard: $wildcard\n") if $DEBUG;
	    keys %$inbound;  # reset iterator

	    while (($name, $value) = each %$inbound) {
		if ($wildcard->accept($name)) {
		    $self->TRACE("wildcard accepted $name => $value\n") if $DEBUG;
		    $outbound->{ $name } = $value;
		    delete $inbound->{ $name };
		}
	    }
	}
    }
	
    # raise error for any attributes we don't know about
    my @badguys = sort keys %$inbound;
    if ($parent && @badguys) {
	return $self->error("unexpected attribute",
			    @badguys > 1 ? 's: ' : ': ',
			    join(', ', @badguys));
    }

    return $outbound;
}



#------------------------------------------------------------------------
# wildcard()
# wildcard($new_wildcard)
#------------------------------------------------------------------------

sub wildcard {
    my $self = shift;
    my $wildcard;

    return $self->{ wildcard }
	|| $self->error("no wildcard defined")
	    unless @_;

    my $factory = $self->factory();

    if ($factory->isa( wildcard => $_[0] )) {
	$wildcard = shift;
    }
    else {
	$wildcard = $factory->create( wildcard => @_ )
	    || return $self->error( $factory->error() );
    }

    $self->{ wildcard } = $wildcard;

    return $wildcard;
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
# default_use($new_default)
#
# Accessor method to get (when called without arguments) or set (when 
# called with a single true/false value) the default usage value as
# one of the strings 'optional', 'required' or 'prohibited'.
#------------------------------------------------------------------------

sub default_use {
    my $self = shift;

    return $self->{ default_use } unless @_;

    my $use = shift;
    return $self->error_value('default_use() argument', $use, @USE_OPTS)
	unless $use =~ $USE_REGEX;

    $self->{ default_use } = $use;
}


#------------------------------------------------------------------------
# use($name, $new_use)
#
# Accessor method to get (when called without arguments) or set (when 
# called with a single true/false value) the default usage value as
# one of the strings 'optional', 'required' or 'prohibited'.
#------------------------------------------------------------------------

sub use {
    my ($self, $name, $use) = @_;

    $self->DEBUG("use($name, ", $use || '<undef>', ")\n") if $DEBUG;

    if (defined $name) {
	return $self->error("no such attribute: '$name'")
	    unless defined $self->{ attributes }->{ $name };

	if (defined $use) {
	    return $self->error_value("use for attribute '$name'", $use, @USE_OPTS)
		unless $use =~ $USE_REGEX;
	    return ($self->{ use }->{ $name } = $use) ? 1 : 0;
	}
	else {
	    return $self->{ use }->{ $name } || $self->error("no use");
	}
    }
    else {
	return $self->{ use } unless defined $name;
    }
}


#------------------------------------------------------------------------
# required($name, $value)
#
# When called without any arguments, this method returns a reference
# to the internal hash table indicating which attributes are required.
# When called with a single argument, $name, it returns a boolean
# value to indicate if the named argument is required or not.  When
# called with an additional argument, $value, the flag for the
# attribute is updated to the new value.  Returns undef with an error
# set if the attribute name is not recognised.
#------------------------------------------------------------------------

sub required {
    my ($self, $name, $value) = @_;

    $self->DEBUG("required(", $name || '<undef>', ", ", $value || '<undef>', ")\n") if $DEBUG;

    if (defined $name) {
	return $self->error("no such attribute: '$name'")
	    unless defined $self->{ attributes }->{ $name };

	if (defined $value) {
	    return $self->use( $name => $value ? REQUIRED : OPTIONAL );
	}
	else {
	    return $self->{ use }->{ $name } eq REQUIRED ? 1 : 0;
	}
    }
    else {
	my $use = $self->{ use };
	return [
	    map { $use->{ $_ } eq REQUIRED ? $_ : () }
	    keys %$use
	];
    }

    # not reached
}


#------------------------------------------------------------------------
# optional($name, $value)
#
# As per required() above, for OPTIONAL attributes.
#------------------------------------------------------------------------

sub optional {
    my ($self, $name, $value) = @_;

    $self->DEBUG("optional(", $name || '<undef>', ", ", $value || '<undef>', ")\n") if $DEBUG;

    if (defined $name) {
	return $self->error("no such attribute: '$name'")
	    unless defined $self->{ attributes }->{ $name };

	if (defined $value) {
	    return $self->use( $name => $value ? OPTIONAL : REQUIRED );
	}
	else {
	    return $self->{ use }->{ $name } eq OPTIONAL ? 1 : 0;
	}
    }
    else {
	my $use = $self->{ use };
	return [
	    map { $use->{ $_ } eq OPTIONAL ? $_ : () }
	    keys %$use
	];
    }

    # not reached
}


#------------------------------------------------------------------------
# prohibited($name, $value)
#
# As per required() above, for PROHIBITED attributes.
#------------------------------------------------------------------------

sub prohibited {
    my ($self, $name, $value) = @_;

    $self->DEBUG("prohibited(", $name || '<undef>', ", ", $value || '<undef>', ")\n") if $DEBUG;

    if (defined $name) {
	return $self->error("no such attribute: '$name'")
	    unless defined $self->{ attributes }->{ $name };

	if (defined $value) {
	    return $self->use( $name => $value ? PROHIBITED : OPTIONAL );
	}
	else {
	    return $self->{ use }->{ $name } eq PROHIBITED ? 1 : 0;
	}
    }
    else {
	my $use = $self->{ use };
	return [
	    map { $use->{ $_ } eq PROHIBITED ? $_ : () }
	    keys %$use
	];
    }

    # not reached
}



sub ID {
    my $self = shift;
    return $self->{ name };
}


1;

__END__

