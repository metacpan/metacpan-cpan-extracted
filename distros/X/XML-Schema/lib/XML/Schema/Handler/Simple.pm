#============================================================= -*-perl-*-
#
# XML::Schema::Handler::Simple.pm
#
# DESCRIPTION
#   Module implementing a parser handler for simple content.
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
#   $Id: Simple.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Handler::Simple;

use strict;
use XML::Schema::Handler;
use base qw( XML::Schema::Handler );
use vars qw( $VERSION $DEBUG $ERROR @SCHEDULES @MANDATORY );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( type );
@SCHEDULES = qw( instance );


#------------------------------------------------------------------------
# start_element($instance, $name, \%attr)
#
# Called at start tag.
#------------------------------------------------------------------------

sub start_element {
    my ($self, $instance, $name, $attr) = @_;

    $self->TRACE("<$name>") if $DEBUG;

    $self->{ instance } = $instance;
    $self->{ name     } = $name;
    $self->{ text     } = '';

    return $self->error("simple element type cannot contain attributes")
	if $attr && %$attr;

    return 1;
}


#------------------------------------------------------------------------
# start_child($instance, $name, $attr)
#
# Should not be called: simple content can have no elements.
#------------------------------------------------------------------------

sub start_child {
    my ($self, $instance, $name, $attr) = @_;
    $self->TRACE("<$self->{ name }> <$name>") if $DEBUG;
    $self->error("simple element type cannot contain child elements");
}


#------------------------------------------------------------------------
# end_child($instance, $name, $child)
#
# Should not be called: as above.
#------------------------------------------------------------------------

sub end_child {
    my ($self, $instance, $name) = @_;
    $self->TRACE("<$self->{ name }> </$name>") if $DEBUG;
    $self->error("simple element type cannot contain child elements");
}


#------------------------------------------------------------------------
# text($instance, $text)
#
# Called to store character content.
#------------------------------------------------------------------------

sub text {
    my ($self, $instance, $text) = @_;
    $self->TRACE("text => ", $self->_text_snippet($text)) if $DEBUG;
    $self->{ text } .= $text;
    return 1;
}


#------------------------------------------------------------------------
# end_element($instance, $name)
#
# Called at end tag.  Instantiates and returns a simple type instance.
#------------------------------------------------------------------------

sub end_element {
    my ($self, $instance, $name) = @_;

    $self->TRACE("instance => $instance, name => $name") if $DEBUG;

    $self->throw($self->ID . " caught end of '$name' (expected $self->{ name })")
	unless $name eq $self->{ name };

    my $type = $self->{ type };

    # copy 'text' to 'value' for validation to assert
    $self->{ value } = $self->{ text };

    $type->validate_instance($self)
	|| return $self->error($type->error());

    # copy 'value' to 'result' for scheduled actions to modify
    $self->{ result } = $self->{ value };

    # activate any type specific actions
    $type->activate_instance($self)
	|| return $self->error($type->error());

    # activate handler specific actions
    $self->activate_instance($self);
}


sub ID {
    my $self = shift;
    return "Simple_Handler[$self->{ name }]";
}

1;

__END__

