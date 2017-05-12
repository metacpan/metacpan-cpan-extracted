#============================================================= -*-perl-*-
#
# XML::Schema::Type::Simple
#
# DESCRIPTION
#   Module implementing a base class for simple XML Schema datatypes.
#   Simple types are those that cannot contain other elements and 
#   cannot carry attributes.
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
# TODO
#   * constrain() should accept lists of constraints, e.g.
#     constrain(minInclusive => 2, scale => 4);
#
#   * Fix strategy wrt defining 'name' and/or 'type' attributes.  'name'
#     should define name of type within schema (e.g. myMoneyType), and 
#     'type' or 'base' should define base?
#
# REVISION
#   $Id: Simple.pm,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

package XML::Schema::Type::Simple;

use strict;
use XML::Schema;
use XML::Schema::Type;
use XML::Schema::Type::List;
use XML::Schema::Type::Union;
use XML::Schema::Type::Builtin;
use XML::Schema::Facet::Builtin;
use XML::Schema::Scheduler;

use base qw( XML::Schema::Type XML::Schema::Scheduler );
use vars qw( $VERSION $DEBUG $ERROR @OPTIONAL @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@OPTIONAL  = qw( annotation );
@SCHEDULES = qw( instance );


    
#------------------------------------------------------------------------
# init()
#
# TODO: fundamentals(), merging user-supplied facets/actions into lists.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($base, $name, $value);
    my $class = ref $self;

    # if called as base class constructor method then look for 
    # 'base' item in config and delegate to that constructor.
    # e.g. XML::Schema::Type::Simple->new( base => 'string', ... );
    #  =>  XML::Schema::Type::string->new( ... );

    if ($class eq __PACKAGE__ && ($base = $config->{ base })) {
	if ($class = $self->builtin($base)) {
	    $self->DEBUG("base package, delegating to $base ($class)\n")
		if $DEBUG;
	    return $class->new($config);
	}
	else {
	    return $self->error("invalid base type: $base");
	}
    }

    my ($mand, $option, $facets) 
	= @{ $self->_baseargs( qw( @MANDATORY %OPTIONAL @FACETS ) ) };

    $self->_mandatory($mand, $config)
	|| return if @$mand;

    $self->_optional($option, $config)
	|| return;

    # default name to last element of package name
    $self->{ name } = $config->{ name } || $self->type();

    $self->{ _VARIETY } = 'atomic';

    # install facets
    $self->{ _FACET_LIST } = [ ];
    $self->{ _FACET_HASH } = { };

    while (@$facets) {
	$name  = shift(@$facets);
	$value = ref $name ? undef : shift(@$facets);
	$self->constrain($name, $value)
	    || return undef;
    }

    # need to know which facets were installed as inbuilt facets
    # and which get added subsequently by user
    $self->{ _FACET_ORIGIN } = @{ $self->{ _FACET_LIST } };

    # initialise scheduler
    $self->init_scheduler($config)
	|| return undef;

    return $self;
}


#------------------------------------------------------------------------
# type()
#
# Return a string giving the name of the type, e.g. 'string', 'date'.
# If called on the base class, 'anyType' is returned, otherwise the
# type name is taken as the last element in the class name, e.g.
# XML::Schema::Type::string => 'string'.
#------------------------------------------------------------------------

sub type {
    my $self = shift;
    my $class = ref $self;

    if ($class eq __PACKAGE__) {
	return 'anyType';
    }
    else {
	$class =~ /::(\w+)$/;
	return $1;
    }
}


#------------------------------------------------------------------------
# builtin($type)
#
# Returns a class name against which new() can be called if the 
# $type specified equates to a builtin type, e.g. string =>
# XML::Schema::Type::string, etc.  Otherwise returns undef.
#------------------------------------------------------------------------

sub builtin {
    my ($self, $type) = @_;
    my $class = ref $self || $self;

    # strip 'Simple' last element of XML::Schema::Type::Simple and 
    # replace with "$type" to get XML::Schema::Type::$type
    $class =~ s/::\w+$/::$type/;

    return UNIVERSAL::can($class, 'new') ? $class : undef;
}


#------------------------------------------------------------------------
# constrain($facet, $value)
#
# Add a new validation facet to the internal list.  
#------------------------------------------------------------------------

sub constrain {
    my ($self, $name, $value) = @_;
    my ($flist, $fhash) = @$self{ qw( _FACET_LIST _FACET_HASH ) };
    my $facet;

    # ($name, $value) can be:
    #    'name' => $facet_ref
    #    'name' => $code_ref
    #    $facet_ref,
    #    $code_ref

    if (ref ($name)) {
	$facet = $name;
	$name  = '';
    }
    else {
	$facet = $value;
    }

    if (ref $facet eq 'CODE') {
	$self->TRACE("CODE facet") if $DEBUG;
	push(@$flist, $facet);
	$fhash->{ $name } = $facet if $name;
	return $facet;		    # return if facet is a coderef
    }
    elsif (UNIVERSAL::isa($facet, 'XML::Schema::Facet')) {
	$name = $facet->name() unless $name;
	$self->TRACE("OBJECT facet") if $DEBUG;
    }
    else {
	my $pkg = "XML::Schema::Facet::$name";
	$self->TRACE("NEW $pkg facet") if $DEBUG;
	$value = { value => $value } unless ref $value;
	$facet = $pkg->new($value)
	    || return $self->error($pkg->error());
    }

    # at this point, we can assume $facet is a XML::Schema::Facet or 
    # subclass; we call its install method to let it inspect the 
    # existing facet list/table to check for conflicts
    # NOTE: facets don't do this yet, but should eventualy

    $facet->install($flist, $fhash)
	|| return $self->error($facet->error());

    return $facet;
}


#------------------------------------------------------------------------
# instance($text)
# instance($text, $xml_instance)
#
# Create a new instance of this type from a basic starting value (i.e.
# the input text read from the XML instance element).  Creates a
# scratchpad $infoset hash which is passed first to the
# validate_instance() method and then to the activate_instance() method
# implemented by the XML::Schema::Scheduler base class.  If called in
# the second form shown above then the second argument is assumed to 
# be a reference to an XML instance represented by an XML::Schema::Instance
# object. 
#------------------------------------------------------------------------

sub instance {
    my ($self, $text, $instance) = @_;
    $self->{ _ERROR } = '';

    # $infoset captures 3 stages in the life of an instance:
    #
    #   text   - unmodified input text
    #	value  - post-validated value
    #   result - post-scheduling result (default: value)
    #
    # validating facets modify 'value'
    # scheduled actions modify 'result'

    my $infoset = ref $text ? $text : { 
	instance => $instance,
	text     => $text,
	value    => $text,
    };

    $self->TRACE("infoset => ", $infoset) if $DEBUG;

    # if validation is successful then the 'value' is copied
    # to 'result', the instance schedule is activated and the 
    # infoset returned.

    return $self->validate_instance($infoset) 
	&& do { $infoset->{ result } = $infoset->{ value } }
	&& $self->activate_instance($infoset) 
        && $infoset;
}



#------------------------------------------------------------------------
# validate_instance(\%infoset)
#
# Calls the valid() method on all the validation facets for this type,
# passing the $infoset scratchpad hash and a self reference against 
# which the facet can make callbacks.  Returns true (1) if all facets
# validate the candidate instance data, or undef if not.
#------------------------------------------------------------------------

sub validate_instance {
    my ($self, $infoset) = @_;

    $self->TRACE("infoset => ", $infoset) if $DEBUG;

    foreach my $facet (@{ $self->{ _FACET_LIST } }) {
	if (ref $facet eq 'CODE') {
	    &$facet($infoset, $self)
		|| return undef;
	}
	else {
	    $facet->valid($infoset, $self) 
		|| return $self->error($facet->error());
	}
    }

    return 1;
}


#------------------------------------------------------------------------
# accessor methods
#------------------------------------------------------------------------

sub facet {
    my ($self, $name) = @_;
    return $self->{ _FACET_HASH }->{ $name };
}

sub variety {
    my ($self, $name) = @_;
    return $self->{ _VARIETY };
}

sub annotation {
    my $self = shift;
    return @_ ? ($self->{ annotation } = shift) : $self->{ annotation };
}

sub simple {
    return 1;
}

sub complex {
    return 0;
}

#------------------------------------------------------------------------
# visitor methods
#------------------------------------------------------------------------

sub visit_facets {
    my ($self, $visitor) = @_;
    my ($facets, $origin) = @$self{ qw( _FACET_LIST _FACET_ORIGIN ) };

    # we skip over the first n facets as determined by 
    # _FACET_ORIGIN because they're the builtin ones

    foreach my $facet (@$facets[$origin..$#$facets]) {
	$facet->accept($visitor)
	    || return $self->error($facet->error());
    }

    return 1;
}
    


#------------------------------------------------------------------------
# handler($instance, $element)
#
# Calls the simple_handler($self, $element) method on the $instance
# reference.
#
# TODO: we could optimise away this chain of method calls by having the
# instance Start() method unwrap the calls.
#------------------------------------------------------------------------

sub handler {
    my ($self, $instance, $element) = @_;
    return $instance->simple_handler($self, $element)
	|| $self->error($instance->error());
}

sub present {
    my ($self, $view) = @_;
    $view->view( simple => $self );
}


sub ID {
    my $self = shift;
    my $base = $self->{ base };
    $base = "-|>-$base" if $base;
    return "simpleType[$self->{ name }$base]";
}

1;

__END__

=head1 NAME

XML::Schema::Type::Simple - base class for simple XML Schema datatypes

=head1 SYNOPSIS

    package XML::Schema::Type::whatever;
    use base qw( XML::Schema::Type::Simple );
    use vars qw( @FACETS );

    @FACETS = (
	minLength  => 10,
	maxLength  => 30,
	otherFacet => { 
	    value  => $n, 
	    fixed  => 1, 
	    annotation => "a comment",
	}, 
    );

    package main;

    my $type = XML::Schema::Type::whatever->new()
        || die XML::Schema::Type::whatever->error();

    my $item = $type->instance('some instance value')
        || die $type->error();

    # NOTE: some issues still to resolve on the precise 
    # nature and structure of instances (currently hash ref).
    print $item->{ value };

=head1 DESCRIPTION

The XML::Schema::Type::Simple module is a base class for objects that 
represent XML Schema simple types.

=head1 TODO

=over 4

=item *

At the moment it's cumbersome to have to manually instantiate a type
object and then call instance() on it.  new() should probably become
class() and instance() should become new().  Calling new() as a class
method should automatically generate a prototype class object via
class() and call new() against that (and also cache the prototype in a
package variable for future invocations).

    my $pkg   = 'XML::Schema::Type::string';
    my $obj1  = $pkg->new();
    my $class = $pkg->class();
    my $obj2  = $class->new();

The only remaining issue is then which class we should bless the type
instance into, if any?  We don't want to bless it into the *::Type::*
class because it's not a type, it's an instance.  One possiblity is to
degrade the type system to work only at the class/package level,
i.e. types would be analogous to Perl packages.  Although this might
make more sense in the long run, at this point in time I suspect that
there are more benefits to be had from allowing types to be living,
breathing objects which can be cloned and specialised.  We _could_ do
this via Perl packages, but I'm wary about building lots of new Perl
packages and evaling them at runtime to allow user-definable types to
be created on-the-fly.  Another possibility is to bless it into a
corresponding *::Instance::* package.  A third, and the current
favourite, is to not bless it at all.  Leave it as a hash and then let
the caller bless it into an Element or Attribute.

=back

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.2 $ of the XML::Schema::Type::Simple,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type>.


