#============================================================= -*-perl-*-
#
# XML::Schema::Type::Complex
#
# DESCRIPTION
#   Module implementing an object class for representing complex XML 
#   Schema datatypes.  Complex types are those that contain other 
#   elements and/or carry attributes.
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
#   $Id: Complex.pm,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

package XML::Schema::Type::Complex;

use strict;
use XML::Schema;
use XML::Schema::Type;
use XML::Schema::Scope;
use XML::Schema::Scheduler;
use base qw( XML::Schema::Scope XML::Schema::Type XML::Schema::Scheduler );
use vars qw( $VERSION $DEBUG $ERROR @OPTIONAL @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@OPTIONAL  = qw( annotation mixed scope );
@SCHEDULES = qw( start_element end_element start_child end_child text );


sub init {
    my ($self, $config) = @_;

    $self->SUPER::init($config)
	|| return;

    # set by base class (Scope) constructor
    my $factory = $self->{ _FACTORY };

    # tell attribute group to delegate to $self for types
    $config->{ scope } ||= $self;
    $config->{ name  } ||= 'anon';
    $config->{ name  }   = '_complex_type_$config->{ name }';

    # create attribute group to manage attributes
    $self->{ attributes } = $factory->create( attribute_group => $config )
	|| return $self->error($factory->error());

    # initialise scheduler
    $self->init_scheduler($config)
	|| return;

    # required ??
    $self->{ simple  } = 0;
    $self->{ complex } = 1;

    my $content;
    if ($content = $config->{ content }) {
	if ($factory->isa( content => $content )) {
	    return $content;
	}
	elsif ($content = $factory->create( content => $content )) {
	    $self->{ content } = $content;
	}
	else {
	    return $self->error($factory->error());
	}
    }
    else {
	# TODO: this is laborious, need to find a better way
	my $ctype = $factory->module('content')
	    || return $self->error($factory->error());
	$factory->load($ctype) 
	    || return $self->error($factory->error());

	my $ptype = $factory->module('particle')
	    || return $self->error($factory->error());
	$factory->load($ptype) 
	    || return $self->error($factory->error());

	my $regex = join('|', $ctype->args(), $ptype->models());
	if (grep(/^$regex$/, keys %$config)) {
	    # create content model
	    $self->{ content } = $factory->create( content => $config )
		|| return $self->error($factory->error());
	}
    }

    return $self;
}


#------------------------------------------------------------------------
# attribute( ... )
#
# Accessor method to fetch and update attributes.  Delegates to
# equivalent method of internal $self->{ attributes } attribute group
# object.
#------------------------------------------------------------------------

sub attribute {
    my $self = shift;
    my $agroup = $self->{ attributes };

    return $agroup->attribute(@_)
	|| $self->error($agroup->error());
}


#------------------------------------------------------------------------
# attributes( )
#
# Returns reference to the internal XML::Schema::Attribute::Group object
# which manages attributes.
#------------------------------------------------------------------------

sub attributes {
    my $self = shift;
    return $self->{ attributes };
}


#------------------------------------------------------------------------
# content()
#
# Return a reference to the current content model object.  Creates a 
# new content object via the current factory if called with 
# arguments.
#------------------------------------------------------------------------

sub content {
    my $self = shift;
    return $self->{ content } unless @_;

    my $factory = $self->{ _FACTORY }
        || return $self->error("no factory defined");

    $self->{ content } = $factory->create( content => @_ )
	|| return $self->error($factory->error());
}


#------------------------------------------------------------------------
# sequence( @items )
#
# Used to create a sequence content model, e.g.
#
# <complexType name="personType">
#   <sequence>		
#     <element name="name"  type="string"/>
#     <element name="email" type="string"/>
#   </sequence>
# </complextype>
#------------------------------------------------------------------------

sub sequence {
    my $self = shift;
    my $content = { };

    while (! ref $_[0]) {
	my $key = shift;
	$content->{ $key } = shift;
    }
    $content->{ sequence } = [ @_ ];

    $self->TRACE("content => ", $content) if $DEBUG;
    $self->content($content);
}



#------------------------------------------------------------------------
# choice( @items )
#
# Used to create a choice content model, e.g.
#
# <complexType name="personType">
#   <choice>		
#     <element name="employee" type="employeeType"/>
#     <element name="customer" type="customerType"/>
#   </choice>
# </complextype>
#------------------------------------------------------------------------

sub choice {
    my $self = shift;
    my $content = { };

    while (! ref $_[0]) {
	my $key = shift;
	$content->{ $key } = shift;
    }
    $content->{ choice } = [ @_ ];

    $self->TRACE("choice => ", $content) if $DEBUG;
    $self->content($content);
}


#------------------------------------------------------------------------
# simpleContent( @items )
#
# Used to create a simpleContent model for the complexType, e.g.
#
# <price currency="EUR">3.14</price>
#
# <element name="price" type="internationalPrice"/>
# <complexType name="internationalPrice">
#   <simpleContent>				<---- simpleContent()
#     <extension base="decimal">
#       <attribute name="currency" type="string"/>
#     </extension>
#   </simpleContent>
# </complexType>
#------------------------------------------------------------------------

sub simpleContent {
    my $self = shift;
    $self->throw('simpleContent() not yet implemented');
}


#------------------------------------------------------------------------
# complexContent( @items )
#
# Used to create a complexContent model for the complexType, e.g.
#
# <price currency="EUR" value="3.14"/>
# 
# <element name="price" type="internationalPrice"/>
# <complexType name="internationalPrice">
#   <complexContent>				<---- complexContent()
#     <restriction base="anyType">
#       <attribute name="currency" type="string"/>
#       <attribute name="value" type="decimal"/>
#     </restriction>
#   </complexContent>
# </complexType>
#------------------------------------------------------------------------

sub complexContent {
    my $self = shift;
    $self->throw('complexContent() not yet implemented');
}


#========================================================================
# misc accessor methods
#========================================================================

sub annotation {
    my $self = shift;
    return @_ ? ($self->{ annotation } = shift) : $self->{ annotation };
}

sub simple {
    return 0;
}

sub complex {
    return 1;
}

sub mixed {
    my $self = shift;
    my $content = $self->{ content } 
	|| return $self->error("no content defined");
    return $content->mixed(@_);
}

sub empty {
    my $self = shift;
    my $content = $self->{ content } 
	|| return $self->error("no content defined");
    return $content->empty(@_);
}

sub element_only {
    my $self = shift;
    my $content = $self->{ content } 
	|| return $self->error("no content defined");
    return $content->element_only(@_);
}

#========================================================================
# parser methods
#========================================================================

#------------------------------------------------------------------------
# handler($instance, $element)
#
# Calls the complex_handler($self, $element) method on the $instance
# reference.
#
# TODO: we could optimise away this chain of method calls by having the
# instance Start() method unwrap the calls.
#------------------------------------------------------------------------

sub handler {
    my ($self, $instance, $element) = @_;
    return $instance->complex_handler($self, $element)
	|| $self->error($instance->error());
}

sub present {
    my ($self, $view) = @_;
    $view->view( complex => $self );
}

sub ID {
    my $self = shift;
    return 'ComplexType';
}

1;

__END__

=head1 NAME

XML::Schema::Type::Complex - class for complex XML Schema datatypes

=head1 SYNOPSIS

    use XML::Schema::Type::Complex;

    my $complex = XML::Schema::Type::Complex->new(
	name       => 'MyComplexType',
	attributes => {
	    attr1  => XML::Schema::Attribute->new(@attr1_opts),
	    attr2  => \@attr2_opts,  # shorthand for above
	    ...
	}
	content    => [ ... ],
	# and more...
    );

    # add new attribute
    my @opts = ( name => 'foo', ... );
    my $attr = XML::Schema::Attribute->new(@opts);
    $complex->attribute($attr);          # calls $attr->name() to get 'foo'
    $complex->attribute($attr, $attr);
    $complex->attribute(name => $attr);
    $complex->attribute(name => \@opts); # creates attribute for you

    ...TODO...
    

=head1 DESCRIPTION

This module implements an object class for representing XML Schema
complex types.  A complex type is one which carries attributes and/or
contains other elements.

[ TODO: This documentation is incomplete and mainly contains early
design thoughts ]

=head2 Instantiating Objects of a Complex Type

The XML::Schema::Type::Simple base class module provides the
instance($value) method for instantiating objects of the type
(e.g. validating that the input is correct and then activating 
any scheduled actions).

The XML::Schema::Type::Complex module implements a similar method
which can be called as $complex->instance(\%attribs, \@content).
Underneath the surface, the process of creating an instantance of
an complex types (e.g. an object to represent an XML element) is a 
little more complicated.  Because this module is typically used
by an XML::Schema::Parser to instances from XML documents, 
the instantiation lifecycle closely follows the parser events:
start tag, content, end tag.

The three methods for instantiating an element of this class are
therefore:

    $complex->start(@attribs);
    $complex->content(@content);
    $complex->end();

Or something like that... (still in development)

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.2 $ of the XML::Schema::Type::Complex,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type>.


