#============================================================= -*-perl-*-
#
# XML::Schema::Particle::Element.pm
#
# DESCRIPTION
#   Subclassed particle to contain a reference to a element instead
#   of a simple particle.
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
#   $Id: Element.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Particle::Element;

use strict;
use base qw( XML::Schema::Particle );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
#$DEBUG   = 0 unless defined $DEBUG;
#$ERROR   = '';
$ETYPE   = 'ElementParticle';

*DEBUG = \$XML::Schema::Particle::DEBUG;
*ERROR = \$XML::Schema::Particle::ERROR;
#*DECLINED = \&XML::Schema::Particle::DECLINED;


#------------------------------------------------------------------------
# init()
#
# Called automatically by base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->TRACE("config => ", $config)	if $DEBUG;

    $self->{ type    } = 'element';
    $self->{ element } = $config->{ element } 
	|| return $self->error(ref $self, ': element not specified');
    $self->{ name } = $self->{ element }->name()
	|| return $self->error("unable to determine name for element '$self->{ element }'");

    $self->constrain($config)
	|| return;

    return $self;
}


sub element {
    my ($self, $name) = @_;
    my ($min, $max, $occurs, $ename) 
	= @$self{ qw( min max occurs name ) };
    $self->{ _ERROR } = '';

    # return element reference for reflective purposes when called 
    # without a name argument
    return $self->{ element }
        unless $name;

    $self->TRACE("name => $name") if $DEBUG;

    # if the element names don't match then the candidate element must
    # belong to the next particle in the content model; we must therefore
    # validate the current particle to ensure it has been satisfied
    unless ($name eq $ename) {
	
	return $self->error("unexpected <$name> found (min. $min <$ename> element",
			    $min > 1 ? 's' : '', " required)")
	    if $occurs < $min;

	return $self->decline("unexpected <$name> element found");
    }

    # at this point, we know the element names match, but we may have
    # exceeded our maxOccurs limit, in which case we decline hoping
    # that a subsequent particle can collect it
    return $self->decline("maximum of $max <$ename> element",
			  $max > 1 ? 's' : '', " exceeded")
	unless $occurs < $max;

    # OK, it looks like the particle can accept the element
    $self->{ occurs }++;

    return $self->{ element };
}


sub match {
    my ($self, $name) = @_;

    # true if names match
    return 1 if $self->{ name } eq $name;

    # false if names don't match but particle has minOccurs == 0
    return 0 if $self->{ min } == 0;

    # undef otherwise
    return undef;
}


sub ID {
    my $self = shift;
    return "$ETYPE\[$self->{ name }]";
}
    
1;


