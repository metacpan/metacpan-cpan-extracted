#============================================================= -*-perl-*-
#
# XML::Schema::Handler::Complex.pm
#
# DESCRIPTION
#   Module implementing a parser handler for complex content.
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
#   $Id: Complex.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Handler::Complex;

use strict;
use XML::Schema::Handler;
use base qw( XML::Schema::Handler );
use vars qw( $VERSION $DEBUG $ERROR @SCHEDULES @MANDATORY );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( type element );
@SCHEDULES = qw( start_element start_child end_child end_element text );


#------------------------------------------------------------------------
# init(\%config)
# 
# Initialiser method called by base class new() constructor.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    
    $self->SUPER::init($config)
	|| return;

    my ($type, $element) = @$self{ qw( type element ) };
    foreach my $schedule (@SCHEDULES) {
	my $name = "_SCHEDULE_$schedule";
	my @data = ( @{ $type->{ $name } }, @{ $element->{ $name } } );
	$self->{ $name } = \@data if @data;
    }

    $self->{ attributes } = $type->attributes();

    my $model = $self->{ model } = $type->content();

    if ($model) {
	$self->{ empty } = $model->empty();
	$self->{ mixed } = $model->mixed();
    }
    else {
	$self->{ empty } = 1;
	$self->{ mixed } = 0;
    }

    return $self;
}


#------------------------------------------------------------------------
# start_element($instance, $name, \%attr)
#
# Called at the start tag of a complex element.  The first argument 
# is a reference to the XML::Schema::Instance in effect.  The second
# argument provides the element name and the third, a reference to a 
# hash array of attributes.  The attributes are validated according to
# any attributes defined for the complex type of this element and then
# the content model is initialised ready for parsing element content
# by calling the start() method on the content particle.  Finally,
# any actions scheduled on the start_element list are activated.
#------------------------------------------------------------------------

sub start_element {
    my ($self, $instance, $name, $attribs) = @_;

    $self->TRACE("instance => $instance, name => $name, attribs => ", $attribs)
	if $DEBUG;

    my $attrgrp = $self->{ attributes }
	|| return $self->error("no attribute group");

    my $attributes = $attrgrp->validate($attribs)
	|| return $self->error($attrgrp->error());

    my @ids;
    my @idrefs;

    my $magic = $attributes->{ _MAGIC } || { };
    delete $attributes->{ _MAGIC };

    if (%$magic) {
	local $" = ', ';
	$self->DEBUG("zoweee!  some magic!\n") if $DEBUG;
	foreach my $mkey (keys %$magic) {
	    $self->DEBUG("magic: $mkey:\n") if $DEBUG;
	    foreach my $mitem (@{ $magic->{ $mkey } }) {
		$self->DEBUG("  [ @$mitem ]\n") if $DEBUG;
	    }
	}
    }
#
#    if ($tname eq 'ID') {
#	 $self->TRACE("found an ID attribute: ", $name) if $DEBUG;
#	 push(@ids, $attributes->{ $name });
#    }
#    elsif ($tname eq 'IDREF') {
#	 $self->TRACE("found an IDREF attribute: ", $attr) if $DEBUG;
#	 push(@idrefs, $name);
#    }

    $self->{ element } = {
	name       => $name,
	attributes => $attributes,
	content    => [ ],
    };
    $self->{ id_fix     } = $magic->{ ID };
    $self->{ idref_fix  } = $magic->{ IDREF };

    my $model = $self->{ model };
    my $particle;

    # fire up the content particle
    if (! $self->{ empty } && $model && ($particle = $model->particle())) {
	$self->{ particle } = $particle;
	$particle->start()
	    || return $self->error($particle->error());
    }

    # activate any scheduled actions for start of element 
    return $self->{ _SCHEDULE_start_element }
	 ? $self->activate_start_element($self)
	 : 1;
}


#------------------------------------------------------------------------
# end_element($instance, $name)
#
# Called at the end tag of a complex element.  The $instance and $name 
# arguments are as per start_element() above.  Triggers validation of 
# the intervening content model by calling end() on the active particle
# and then activates any actions scheduled on the end_element list.  
# The $self blessed hash object acts as the infoset for collecting
# attributes and content for the complex element instance.  It passes
# itself between the schedule callbacks, each of which is free to
# modify and/or supplement the internal data stored within it.  The
# possibly modified $self is then return to the the caller of
# end_element() to indicate success. 
#------------------------------------------------------------------------

sub end_element {
    my ($self, $instance, $name) = @_;

    my $element = $self->{ element };

    $self->throw($self->ID . " caught end of '$name' (expected $self->{ _NAME })")
	unless $name eq $element->{ name };

    $self->TRACE("instance => $instance, name => $name") if $DEBUG;

    if (my $particle = $self->{ particle }) {
	$particle->end($instance, $name) 
	    || return $self->error($particle->error());
    }

#    $self->{ result } = {
#	name       => $self->{ name },
#	attributes => $self->{ attributes },
#	content    => $self->{ content },
#    };

     my $result = $self->{ _SCHEDULE_end_element }
	  ? $self->activate_end_element($element)
	  : $element;

#    $element = $self->{ _SCHEDULE_end_element }
#	 ? $self->activate_end_element($element)
#	 : $element;

    # fixup ID 
    foreach my $id (@{ $self->{ id_fix } }) {
	my ($type, $name, $value) = @$id;
	$self->DEBUG("fixup ID for $type $name => $value\n") if $DEBUG;
	$instance->id($value, $result)
	    || return $self->error($instance->error());
    }

    # fixup IDREF (note, this doesn't lookahead - need to schedule at end

    foreach my $idref (@{ $self->{ idref_fix } }) {
	my ($type, $name, $value) = @$idref;
	$self->DEBUG("fixup IDREF for $type $name => $value\n") if $DEBUG;
	my $ref = $instance->idref($value)
	    || return $self->error($instance->error());
	if ($type eq 'attribute') {
	    $self->DEBUG("fixup IDREF attribute $name => ", $ref, "\n") if $DEBUG;
	    $result->{ attributes }->{ $name } = $ref;
	}
    }

#    $self->DEBUG("retuning element [$element] => { ", $self->_inspect($element), " }\n");
    return $result;
}


#------------------------------------------------------------------------
# start_child($instance, $name, $attr)
#
# Called against an outer (parent) element handler when an inner (child)
# element is detected.  Delegates the call to the current particle 
# representing the content model and then activates any actions scheduled
# for this point.
#------------------------------------------------------------------------

sub start_child {
    my ($self, $instance, $name, $attr) = @_;
    my ($particle, $element, $handler);

    $self->TRACE("instance => $instance, name => $name") if $DEBUG;

    return $self->error("empty content model cannot contain elements")
	if $self->{ empty };

    ($particle = $self->{ particle })
	|| return $self->error("no particle");

    ($element = $particle->element($name))
	|| return $self->error($particle->error());

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

    return $self->error("empty content model cannot contain elements")
	if $self->{ empty };

    $child = $self->activate_end_child($child)
	|| return
	    if $self->{ _SCHEDULE_end_child };

    # use 'result' entry in child or child as it is
    my $result = exists $child->{ result } ? $child->{ result } : $child;

    push(@{ $self->{ element }->{ content } }, $result)
	if defined $result;

    return $child;
}


#------------------------------------------------------------------------
# text($instance, $text)
#
# Called to store character content.
#------------------------------------------------------------------------

sub text {
    my ($self, $instance, $text) = @_;

    $self->TRACE($self->_text_snippet($text))
	if $DEBUG;

    return $self->error("empty content model cannot contain text")
	if $self->{ empty };

    return $self->error('non-mixed content model cannot contain text')
	unless $self->{ mixed } or $text =~ /^\s*$/;

    push(@{ $self->{ element }->{ content } }, $text) if $self->{ mixed };

    return 1
}


sub attributes {
    my $self = shift;
    return $self->{ element }->{ attributes };
}

sub attribute_group {
    my $self = shift;
    return $self->{ attributes };
}

sub content {
    my $self = shift;
    return $self->{ element }->{ content };
}



sub ID {
    my $self = shift;
    return "Complex_Handler[$self->{ name }]";
}

1;

__END__

