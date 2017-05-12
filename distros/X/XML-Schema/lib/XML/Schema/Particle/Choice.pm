#============================================================= -*-perl-*-
#
# XML::Schema::Particle::Choice.pm
#
# DESCRIPTION
#   Subclassed particle to contain a choice of other particles
#   which can be matched in any order.
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
#   $Id: Choice.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Particle::Choice;

use strict;
use base qw( XML::Schema::Particle );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'ChoiceParticle';


#------------------------------------------------------------------------
# init()
#
# Called automatically by base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->TRACE("config => ", $config) if $DEBUG;

    my $choice = $config->{ choice }
        || return $self->error("no choice defined");

    return $self->error("choice expects an array ref")
	unless ref $choice eq 'ARRAY';

    my ($p, @particles);
    my $factory = $self->{ _FACTORY } = $config->{ FACTORY } 
	|| $XML::Schema::FACTORY;

    foreach $p (@$choice) {
	my $particle = $factory->create( particle => $p );
	unless (defined $particle) {
	    return $self->error("error in choice item ", scalar @particles, 
				': ', $factory->error());
	}
	
	push(@particles, $particle);
    }
    $self->{ particles } = \@particles;
    $self->{ type } = 'choice';

    $self->constrain($config)
	|| return;

    return $self;
}


sub particles {
    my $self = shift;
    return $self->{ particles }
	|| $self->error("empty particle choice");
}


sub start {
    my $self = shift;

    $self->TRACE() if $DEBUG;

    $self->{ occurs } = 0;
    $self->{ _pnow } = undef;

    return 1;
}


#------------------------------------------------------------------------
# element($name)
#
# Iterates through the list of particles to find one which can accept
# a <$name> element.  Each particle is started via a call to start()
# (e.g. to initialise a sequence particle) and then its element($name)
# method is called.  If it returns a true value (an element ref) then
# that particle is latched in as the current target particle (_pnow)
# and will be given first refusal on subsequent element() calls.  If
# the particle does not accept the element() call then its end()
# method is called and the process continues onto the next particle in
# the choice.
#------------------------------------------------------------------------

sub element {
    my ($self, $name) = @_;
    my $particles = $self->{ particles };
    my $pnow = $self->{ _pnow };
    my $element;

    $self->TRACE("name => ", $name) if $DEBUG;

    # if there is an active particle (i.e. one previously selected by
    # this element() method) then we first give it the opportunity to
    # handle this new element.  

    if ($pnow) {
	# true value returned indicates success
	return $element
	    if ($element = $pnow->element($name));

	# undefined value returned indicates error
	return $self->error($pnow->error())
	    unless defined $element;

	# defined but false value (0) indicates particle 
	# declined to accept element but was otherwise 
	# satisfied according to min/max constraints so
	# we move on to try the next particle
	$self->TRACE("ending $pnow because it declined");
	$pnow->end()
	    || return $self->error($pnow->error());

	my $occurs = ++$self->{ occurs };

	# if we've reached our max occurences then we must decline
	return $self->decline("unexpected <$name> element")
	    if $occurs >= $self->{ max };
    }

    # iterate through each particle to see if any can accept it
    foreach $pnow (@$particles) {
	$pnow->start() 
	    || return $self->error($pnow->error());

	if ($element = $pnow->element($name)) {
	    # save reference to active particle for next time
	    $self->{ _pnow } = $pnow;
	    return $element;
	}

	# ignore errors that are likely to be "min <whatever> expected"
	$pnow->end();
    }

    # didn't find anything to handle this element so we return an 
    # error or decline depending on us having any minimum occurence
    # requirements
    return $self->{ occurs } >= $self->{ min }
	? $self->decline("unexpected <$name> element")
	: $self->error("unexpected <$name> element");
}



#------------------------------------------------------------------------
# end()
#
# If we've got an active particle on the go then we call its end() method 
# to give it a chance to perform its own sanity check.  Then we go on
# to inspect our own min/max constraints and return an appropriate 
# true (ok) or false (not ok) value.
#------------------------------------------------------------------------

sub end {
    my $self = shift;
    my $pnow = $self->{ _pnow };

    $self->TRACE if $DEBUG;

    # if there is an active particle (i.e. one previously selected by
    # this element() method) then we must end() it and make sure it is
    # a happy particle
    if ($pnow) {
	$pnow->end()
	    || return $self->error($pnow->error());

	# chalk up another one
	++$self->{ occurs };
    }

    # make sure that we're a happy particle
    my ($min, $max, $occurs) = @$self{ qw( min max occurs ) };

    return $self->error("minimum of $min choice expected")
	if $occurs < $min;

    return $self->error("maximum of $max choice exceeded")
	if $occurs > $max;

    return 1;
}

    
1;






