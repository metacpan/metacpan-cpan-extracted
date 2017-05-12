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
use vars qw( $VERSION $DEBUG $ERROR @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@SCHEDULES = qw( instance );


#------------------------------------------------------------------------
# start_element($instance, $name, \%attr)
#
# Called at start tag.
#------------------------------------------------------------------------

sub start_element {
    my ($self, $instance, $name, $attr) = @_;
    return $self->error("simple element type cannot contain attributes")
	if $attr && %$attr;
    $self->{ _TEXT } = '';
    $self->{ _NAME } = $name;
    $self->DEBUG($self->ID, "->start($name)\n") if $DEBUG;
    return 1;
}


#------------------------------------------------------------------------
# start_child($instance, $name, $attr)
#
# Should not be called: simple content can have no elements.
#------------------------------------------------------------------------

sub start_child {
    my ($self, $instance, $name, $attr) = @_;
    $self->error("simple element type cannot contain child elements");
}


#------------------------------------------------------------------------
# end_child($instance, $name, $child)
#
# Should not be called: as above.
#------------------------------------------------------------------------

sub end_child {
    my $self = shift;
    $self->error("simple element type cannot contain child elements");
}


#------------------------------------------------------------------------
# text($instance, $text)
#
# Called to store character content.
#------------------------------------------------------------------------

sub text {
    my ($self, $instance, $text) = @_;
    $self->DEBUG($self->ID, "->text(", $self->_text_snippet($text), ")\n")
	if $DEBUG;
    $self->{ _TEXT } .= $text;
    return 1;
}


#------------------------------------------------------------------------
# end_element($instance, $name)
#
# Called at end tag.  Instantiates and returns a simple type instance.
#------------------------------------------------------------------------

sub end_element {
    my ($self, $instance, $name) = @_;
    my ($infoset, $result);

    $self->throw($self->ID . " caught end of '$name' (expected $self->{ _NAME })")
	unless $name eq $self->{ _NAME };

    my $type = $self->{ type };

    defined($infoset = $type->instance($instance, $self->{ _TEXT }))
	|| $self->error( $type->error() );

#    $infoset = $self->activate_instance($infoset)
#	|| return;

    $result = $instance->{ result };

    $self->DEBUG($self->ID, "->end($name) returns ['", $self->_text_snippet($result), "']\n")
	if $DEBUG;

    return $result;
}


sub ID {
    my $self = shift;
    return "Simple_Handler[$self->{ _NAME }]";
}

1;

__END__

