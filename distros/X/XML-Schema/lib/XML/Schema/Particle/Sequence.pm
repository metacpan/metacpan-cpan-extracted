#============================================================= -*-perl-*-
#
# XML::Schema::Particle::Sequence.pm
#
# DESCRIPTION
#   Subclassed particle to contain a sequence of other particles
#   which should be matched in order.
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
#   $Id: Sequence.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Particle::Sequence;

use strict;
use base qw( XML::Schema::Particle );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'SequenceParticle';

#*DEBUG = \$XML::Schema::Particle::DEBUG;
#*ERROR = \$XML::Schema::Particle::ERROR;
#*DECLINED = \&XML::Schema::Particle::DECLINED;


#------------------------------------------------------------------------
# init()
#
# Called automatically by base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->TRACE("config => ", $config) if $DEBUG;

    my $sequence = $config->{ sequence }
        || return $self->error("no sequence defined");

    return $self->error("sequence expects an array ref")
	unless ref $sequence eq 'ARRAY';

    my ($p, @particles);
    my $factory = $self->{ _FACTORY } = $config->{ FACTORY } 
	|| $XML::Schema::FACTORY;

    foreach $p (@$sequence) {
	my $particle = $factory->create( particle => $p );
	unless (defined $particle) {
	    return $self->error("error in sequence item ", scalar @particles, 
				': ', $factory->error());
	}
	
	push(@particles, $particle);
    }
    $self->{ particles } = \@particles;
    $self->{ type } = 'sequence';

    $self->constrain($config)
	|| return;

    return $self;
}


sub particles {
    my $self = shift;
    return $self->{ particles }
	|| $self->error("empty particle sequence");
}


sub start {
    my $self = shift;

    $self->TRACE() if $DEBUG;

    $self->{ occurs } = 0;
    $self->_start_sequence();
}


sub _start_sequence {
    my $self = shift;

    $self->TRACE() if $DEBUG;

    my $particles = $self->{ particles }
        || return $self->decline("empty particle sequence");

    $self->{ _PSET } = [ @$particles ];

    my $first = $particles->[0];

    return $first->start()
	|| $self->error($first->error());
}


sub end {
    my $self = shift;
    my ($min, $max, $occurs, $name) = @$self{ qw( min max occurs name ) };

    $self->TRACE() if $DEBUG;

    my $pset = $self->{ _PSET };

    if (@$pset) {
	my $pnow = shift @$pset;
	while ($pnow) {
	    $self->TRACE("clearing ", $pnow->ID);
	    $pnow->end()
		|| return $self->error($pnow->error());
	    if ($pnow = shift(@$pset)) {
		$pnow->start()
		    || return $self->error($pnow->error());
	    }
	}
	$occurs++;
    }

    return $self->error("minimum of $min $name element", 
			$min > 1 ? 's' : '', " expected")
	if $occurs < $min;

    return $self->error("maximum of $max $name element",
			$max > 1 ? 's' : '', " exceeded")
	if $occurs > $max;

    return 1;
}


sub element {
    my ($self, $name) = @_;
    my $pset = $self->{ _PSET };
    my $pnow = @$pset ? $pset->[0] : undef;
    my ($min, $max) = @$self{ qw( min max ) };
    my $element;
    my $restarted = 0;
    my $satisfied = 0;

    $self->TRACE("name => ", $name) if $DEBUG;

    while ($pnow) {
	# true value returned indicates success
	return $element
	    if ($element = $pnow->element($name));

	# undefined value returned indicates error
	unless (defined $element) {
	    $self->TRACE('DECLINED');
	    return $satisfied ? $self->decline("unexpected <$name> element")
			      : $self->error($pnow->error())
	}

	# defined but false value (0) indicates particle 
	# declined to accept element but was otherwise 
	# satisfied according to min/max constraints so
	# we move on to try the next particle
	$self->TRACE("ending $pnow because it declined");
	$pnow->end()
	    || return $self->error($pnow->error());

	shift(@$pset);

	if (@$pset) {
	    $pnow = $pset->[0];
	    $pnow->start() || return $self->error($pnow->error());
	}
	else {
	    # looks like we reached the end of the sequence...
	    my $occurs = ++$self->{ occurs };

	    # if we've reached our max occurences then we must decline
	    return $self->decline("unexpected <$name> element (max. $max sequences reached)")
		if $occurs >= $max;

	    # and if we've already restarted once then we shouldn't again
	    last if $restarted;

	    # otherwise restart the sequence
	    return unless $self->_start_sequence();
	    $pset = $self->{ _PSET };
	    $pnow = @$pset ? $pset->[0] : undef;

	    $restarted++;
	    $satisfied++ if $occurs >= $min;
	}
    }

    return $satisfied ? $self->decline("unexpected <$name> element")
		      : $self->error("unexpected <$name> element");

}


    
1;






