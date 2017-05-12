#============================================================= -*-perl-*-
#
# XML::Schema
#
# DESCRIPTION
#   Modules for representing, constucting and utilising XML Schemata
#   in Perl.
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
#   $Id: Schema.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema;

use strict;
use XML::Schema::Element;
use XML::Schema::Factory;
use XML::Schema::Scope;
use XML::Schema::Type;
use base qw( XML::Schema::Scope );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE $FACTORY @OPTIONAL );

$VERSION  = 0.07;
$DEBUG    = 0 unless defined $DEBUG;
$ERROR    = '';
$ETYPE    = 'Schema';
$FACTORY  = 'XML::Schema::Factory';
@OPTIONAL = qw( element );


sub init {
    my ($self, $config) = @_;

    $self->SUPER::init($config)
	|| return;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    # allow (but don't enfore) content model to be created by specifying
    # 'type', 'particle' or 'content' in config
#    $self->{ content } = $FACTORY->content($config);
#	|| return $self->error($FACTORY->error());
#
#    $self->TRACE("content => ", $self->{ content }) if $DEBUG;

    return $self;
}


sub element {
    my $self = shift;
    if (@_) {
	return ($self->{ element } = $self->SUPER::element(@_));
    }
    else {
	return $self->{ element }
	    || $self->error("no element defined");
    }
}

sub old_element {
    my $self = shift;
    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    $self->TRACE() if $DEBUG;

    if (@_) {
	if ($factory->isa( element => $_[0] )) {
	    $self->TRACE("adding element") if $DEBUG;
	    $self->{ element } = shift;
	}
	else {
	    my $args = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
	    $args->{ scope } = $self unless exists $args->{ scope };
	    $self->TRACE("creating element") if $DEBUG;
	    $self->{ element } = $factory->create( element => $args )
		|| return $self->error($factory->error());
	}
    }
    else {
	return $self->{ element }
	    || $self->error("no element defined");
    }
}


#------------------------------------------------------------------------
# content()
# content($item)
#
# Return the current content model for the schema (if any) when called
# without any args.  Sets the content model (converting it to a Content
# object if necessary) when called with an argument.
#------------------------------------------------------------------------

sub content {
    my $self = shift;

    return ($self->{ content }
	|| $self->error('schema has no content model'))
	unless @_;

    $self->TRACE("content: ", @_) if $DEBUG;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return ($self->{ content } = $factory->create( content => @_ ))
	|| $self->error($factory->error());
}


#------------------------------------------------------------------------
# parser(@args)
#
# Create a parser object (XML::Schema::Parser by default) primed for
# validation against this schema.  Arguments are folded into a hash
# reference, if not already provided as such, and the 'schema' item is
# added, containing a reference to the $self schema object.
#------------------------------------------------------------------------

sub parser {
    my $self = shift;
    my $args = $_[0] && ref($_[0]) eq 'HASH' ? shift : { @_ };

    $args->{ schema } = $self;

    $self->TRACE("args => ", $args) if $DEBUG;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return $factory->create( parser => $args )
	|| $self->error($factory->error());
}   


#------------------------------------------------------------------------
# instance(@args)
#
# Create an instance object (XML::Schema::Instance by default) for 
# representing the generated content created by parsing an instance
# document of this schema.  Arguments are folded into a hash
# reference, if not already provided as such, and the 'schema' item is
# added, containing a reference to the $self schema object.
#------------------------------------------------------------------------

sub instance {
    my $self = shift;
    my $args = $_[0] && ref($_[0]) eq 'HASH' ? shift : { @_ };

    $args->{ schema } = $self;

    $self->TRACE("args => ", $args) if $DEBUG;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return $factory->create( instance => $args )
	|| $self->error($factory->error());
}


#------------------------------------------------------------------------
# handler(@args)
#
# Create a parser object (XML::Schema::Parser by default) for parsing
# instance documents according to the current schema.  Arguments are
# folded into a hash reference, if not already provided as such, and
# the 'schema' item is added, containing a reference to the $self
# schema object.
#------------------------------------------------------------------------

sub handler {
    my $self = shift;
    my $args = $_[0] && ref($_[0]) eq 'HASH' ? shift : { @_ };

    $args->{ schema } = $self;

    $self->TRACE("args => ", $args) if $DEBUG;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return $factory->create( schema_handler => $args )
	|| $self->error($factory->error());
}


sub present {
    my ($self, $view) = @_;
    $view->view( schema => $self );
}

1;

__END__

=head1 NAME

XML::Schema - XML Schema modules for Perl

=head1 SYNOPSIS

    use XML::Schema;

    # see html docs for details

=head1 DESCRIPTION

The XML::Schema module set implements the necessary functionality to
construct, represent and utilise XML Schemata in Perl.  It aims to be
fully conformant with the W3C XML Schema specification, although at
present it is a work-in-progress and will initially strive to be
minimally conformant (see the specification if you're interested in
the precise definitions of those terms).

See the HTML documentation (in the 'html' sub-directory of the distribution)
for further details.

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

=head1 VERSION

This is version 0.07.

=head1 COPYRIGHT

Copyright (C) 2001-2003 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For the latest version of the W3C XML Schema specification, see
http://www.w3c.org/TR/xmlschema-0/

