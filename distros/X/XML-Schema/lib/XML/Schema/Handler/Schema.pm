#============================================================= -*-perl-*-
#
# XML::Schema::Handler::Schema.pm
#
# DESCRIPTION
#   Module implementing a parser handler for the outermost schema content.
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
#   $Id: Schema.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Handler::Schema;

use strict;
use XML::Schema::Handler;
use base qw( XML::Schema::Handler );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( schema );
@SCHEDULES = qw( start_element start_child end_child end_element text );




#------------------------------------------------------------------------
# start_element($instance)
#
# Called at start of schema.
#------------------------------------------------------------------------

sub start_element {
    my ($self, $instance) = @_;

    $self->DEBUG($self->ID, "->start_element($instance)\n")
	if $DEBUG;

    $self->{ content } = '';

    my $schema = $self->{ schema }
        || return $self->error("no schema defined");

    my $element = $schema->element()
        || return $self->error("schema has no element defined");

    $self->{ element } = $element;

    return 1;
}


#------------------------------------------------------------------------
# end_element($instance)
#
# Called at end of schema.
#------------------------------------------------------------------------

sub end_element {
    my ($self, $instance) = @_;

    $self->DEBUG($self->ID, "->end($instance)\n")
	if $DEBUG;

    # TODO: validate content

    return $self->{ content };
}


#------------------------------------------------------------------------
# start_child($instance, $name, $attr)
#------------------------------------------------------------------------

sub start_child {
    my ($self, $instance, $name, $attr) = @_;
    my ($element, $handler);

    $self->TRACE("instance => $instance, name => $name") if $DEBUG;

    ($element = $self->{ element })
	|| return $self->error('no schema element defined');

    ($handler = $element->handler($instance))
	|| return $self->error($element->error());

    my $child = {
	name       => $name,
	attributes => $attr,
	element    => $element,
	handler    => $handler,
	skip       => 0,	    # TODO
	error      => undef,
    };

    return $self->{ _SCHEDULE_start_child }
	 ? $self->activate_start_child($child)
	 : $child;
}


#------------------------------------------------------------------------
# end_child()
#------------------------------------------------------------------------

sub end_child {
    my ($self, $instance, $name, $child) = @_;

    $self->TRACE("instance => $instance, name => $name, child => ", $child) if $DEBUG;

    $self->activate_end_child($child)
	|| return
	    if $self->{ _SCHEDULE_end_child };

    # use 'result' entry in child or child as it is
    my $result = exists $child->{ result } ? $child->{ result } : $child;

    $self->{ content } = $result;

    return $child;
}


#------------------------------------------------------------------------
# text($instance, $text)
#
# Called to store (or in this case, reject unless insignificant whitespace)
# character content.
#------------------------------------------------------------------------

sub text {
    my ($self, $instance, $text) = @_;
    return $self->error("schema cannot accept text")
	unless $text =~ /^\s*$/s;
    return 1
}


sub ID {
    my $self = shift;
    return "Schema_Handler[$self->{ _NAME }]";
}

1;

__END__

