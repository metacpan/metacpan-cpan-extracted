#============================================================= -*-perl-*-
#
# XML::Schema::Instance
#
# DESCRIPTION
#   Module implementing an object for representing instance documents.
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
#   $Id: Instance.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Instance;

use strict;
use XML::Schema;
use vars qw( $VERSION $DEBUG $ERROR $ETYPE @MANDATORY );
use base qw( XML::Schema::Base );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'Instance';

@MANDATORY = qw( schema );


#------------------------------------------------------------------------
# init(\%config)
#
# Initialiser method called by the base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->TRACE("config => ", $config) if $DEBUG;

    my ($mand) = @{ $self->_baseargs( qw( @MANDATORY ) ) };
    $self->_mandatory($mand, $config)
	|| return;

    $self->{ _ID } = { };
    $self->{ _SCHEMA_STACK } = [ ];
    $self->{ _FACTORY } = $config->{ FACTORY } || $XML::Schema::FACTORY;
    $self->{ content } = [ ];
    

    return $self;
}


#------------------------------------------------------------------------
# id($id, $value)
#
# Stores the specified value as an ID within the instance document, 
# indexed by $id.
#------------------------------------------------------------------------

sub id {
    my ($self, $id, $ref) = @_;

    $self->TRACE("ID: ", $id, " => ", $ref) if $DEBUG;

    return $self->error("no value defined, did you mean to call idref()?")
	unless defined $ref;

    return $self->error("an element is already defined with id '$id'")
	if defined $self->{ _ID }->{ $id };

    $self->{ _ID }->{ $id } = $ref;

    return 1;
}


#------------------------------------------------------------------------
# idref($id)
#
# Returns the value of an ID previously specified via a call to id()
# or undef if the ID isn't defined, with an appropriate error message
# being set.
#------------------------------------------------------------------------

sub idref {
    my ($self, $idref) = @_;
    $self->TRACE("IDREF: ", $idref) if $DEBUG;
    return $self->{ _ID }->{ $idref }
        || $self->error("no such id: $idref");
}

#------------------------------------------------------------------------
# TODO:
#   also need to implement entity and notation handlers... 
#   (see comments in XML::Schema::Type::Builtin header)
#------------------------------------------------------------------------


#------------------------------------------------------------------------
# schema_handler(...)
# 
# Return a parser handler for parsing the top-level of the schema.
#------------------------------------------------------------------------

sub schema_handler {
    my $self = shift;
    $self->TRACE() if $DEBUG;
    my $schema = $self->{ schema };
    return $schema->handler(@_)
	|| $self->error($schema->error());
}

#------------------------------------------------------------------------
# simple_handler(...)
# 
# Return a parser handler for parsing a simple element.
#------------------------------------------------------------------------

sub simple_handler {
    my ($self, $type, $element) = @_;

    if ($DEBUG) {
	my $tid = ref($type) && UNIVERSAL::can($type, 'ID') 
	    ? $type->ID : ($type || '<undef>');
	my $eid = ref($element) && UNIVERSAL::can($element, 'ID') 
	    ? $element->ID : ($element || '<undef>');
	$self->TRACE("type => $tid, element => $eid");
    }

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return $factory->create( simple_handler => { 
	type    => $type,
	element => $element,
    }) || $self->error($factory->error());
}


#------------------------------------------------------------------------
# complex_handler($type, $element)
# 
# Return a parser handler for parsing a complex element.
#------------------------------------------------------------------------

sub complex_handler {
    my ($self, $type, $element) = @_;

    $self->TRACE("type => ", $type->ID, ", element => ", $element->ID) if $DEBUG;

    my $factory = $self->{ _FACTORY }
	|| return $self->error("no factory defined");

    return $factory->create( complex_handler => { 
	type    => $type,
	element => $element,
    }) || $self->error($factory->error());
}


#------------------------------------------------------------------------
# schema_push($handler)
# 
# Push a parser handler onto the top of the internal schema stack, 
# making it the target for all subsequent parse events until masked
# by another handler pushed on top of it, or popped off the stack
# by a call to schema_pop() (e.g. at the element end tag)
#------------------------------------------------------------------------

sub schema_push {
    my ($self, $node) = @_;
    push(@{ $self->{ _SCHEMA_STACK } }, $node);
}


#------------------------------------------------------------------------
# schema_pop()
# 
# Pop the top parser handler from the internal schema stack and return it.
#------------------------------------------------------------------------

sub schema_pop {
    pop(@{ $_[0]->{ _SCHEMA_STACK } });
}


#------------------------------------------------------------------------
# schema_top()
#
# Return the top item on the internal schema stack.
#------------------------------------------------------------------------

sub schema_top {
    $_[0]->{ _SCHEMA_STACK }->[-1];
}


#------------------------------------------------------------------------
# expat_handlers()
#
# Returns a hash array for configuring XML::Parser to correctly use
# this schema instance as a recipient of parse events.  May return a 
# hash ref as { Init => ..., Start => ..., etc. } in which case the 
# instance class is automatically used by the caller as the 'Style'
# value leading to this class receiving parse events.  Alternately, a
# hash of the form { Style => 'MyClass', Handlers => { Start => ... } }
# may be passed to explicitly denote the intended recipient.
#------------------------------------------------------------------------

sub expat_handlers {
    my $self = shift;
    my $schema = $self->{ schema };

    my $handler = $self->schema_handler()
	|| return;

    $handler->start_element($self)
	|| return $self->error($handler->error());

    return {
	Init => sub { 
	    $self->DEBUG($self->ID, "->[Init] $self\n") if $DEBUG;
	    my $expat = shift;
	    $expat->{ _SCHEMA_INSTANCE } = $self;
	    $expat->{ _SCHEMA_TEXT } = '';
	    $self->{ _SCHEMA_STACK } = [ $handler ];
	    $self->{ _SCHEMA_EXPAT } = $expat;
	},
    };
}


#========================================================================
# XML::Parser::Expat callbacks
#========================================================================

#------------------------------------------------------------------------
# Start($expat, $name, %attr)
#------------------------------------------------------------------------

sub Start {
    my ($expat, $name, %attr) = @_;
    my $self   = $expat->{ _SCHEMA_INSTANCE };
    my $stack  = $self->{ _SCHEMA_STACK };
    my $parent = $stack->[-1];
    my $text;

    if ($DEBUG) {
	my $attr = join(' ', map { "$_=\"$attr{$_}\"" } keys %attr);
	$attr = " $attr" if $attr;
	$self->TRACE("[Start]  <$name$attr>");
    }

    # flush any character content
    if (length ($text = $expat->{ _SCHEMA_TEXT })) {
	$self->TRACE("flushing text: '", $self->_text_snippet($text), "'") if $DEBUG;
	$parent->text($self, $text)
	    || $self->parse_error($parent->error());
	$expat->{ _SCHEMA_TEXT } = '';
    }

    my $child = $parent->start_child($self, $name, \%attr)
	|| return $self->parse_error($parent->error());

    my $handler = $child->{ handler }
	|| return $self->parse_error($child->{ error } || 
				     "no child handler defined");

    $handler->start_element($self, @$child{ qw( name attributes ) })
	|| $self->parse_error($handler->error());
	
    push(@$stack, $handler);
}


#------------------------------------------------------------------------
# End($expat, $name)
#------------------------------------------------------------------------

sub End {
    my ($expat, $name) = @_;
    my $self    = $expat->{ _SCHEMA_INSTANCE };
    my $stack   = $self->{ _SCHEMA_STACK };
    my $element = pop( @$stack );
    my $text;

    $self->TRACE("[End] </$name>") if $DEBUG;

    # flush any character content
    if (length ($text = $expat->{ _SCHEMA_TEXT })) {
	$self->TRACE("flushing text: '", $self->_text_snippet($text), "'") if $DEBUG;
	$element->text($self, $text)
	    || $self->parse_error($element->error());
	$expat->{ _SCHEMA_TEXT } = '';
    }

    my $child = $element->end_element($self, $name)
	|| return $self->parse_error($element->error());

    my $parent = $stack->[-1]
	|| $self->parse_error("no parent element for $name");

    return $parent->end_child($self, $name, $child)
	|| $self->error($parent->error());
}


#------------------------------------------------------------------------
# Char($expat, $char)
#------------------------------------------------------------------------

sub Char {
    my ($expat, $char) = @_;

#    $self->TRACE("[Char] '$char'") if $DEBUG;

    # push character content onto buffer
    $expat->{ _SCHEMA_TEXT } .= $char;
}


#------------------------------------------------------------------------
# Final($expat)
#------------------------------------------------------------------------

sub Final {
    my $expat   = shift;
    my $self    = $expat->{ _SCHEMA_INSTANCE };
    my $stack   = $self->{ _SCHEMA_STACK };
    my $element = pop( @$stack );

    $self->TRACE("[Final] calling $element->end()\n") if $DEBUG;

    # TODO: may need to flush text?

    delete $expat->{ _SCHEMA_INSTANCE };
    delete $expat->{ _SCHEMA_TEXT     };
    delete  $self->{ _SCHEMA_EXPAT    };
    delete  $self->{ _SCHEMA_STACK    };


    my $result = $element->end_element($self)
	|| $self->parse_error($element->error());

#    $self->throw("instance finally popped off foreign handler (got $element not $self")
#	unless $element == $self;

    return $result;
}


sub parse_error {
    my $self  = shift;
    my $msg   = join('', @_);
    my $expat = $self->{ _SCHEMA_EXPAT };
    die "?? lost expat instance ??\n" unless $expat;
    die $expat->position_in_context(4), "\n$msg\n";
#    $expat->xpcroak($msg);
}

1;

