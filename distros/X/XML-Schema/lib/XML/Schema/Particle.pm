#============================================================= -*-perl-*-
#
# XML::Schema::Particle.pm
#
# DESCRIPTION
#   A particle is an element within a content model optionally
#   specified with minOccurs and maxOccurs constraints.
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
#   $Id: Particle.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Particle;

use strict;
use XML::Schema;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE @MODELS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'particle';
@MODELS  = qw( element sequence choice model );


use constant DECLINED => 0;

# alias min() to minOccurs() and max() to maxOccurs()
*minOccurs = \&min;
*maxOccurs = \&max;


#------------------------------------------------------------------------
# init()
#
# Called automatically by base class new() method.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my $factory = $self->{ FACTORY } = $config->{ FACTORY } || $XML::Schema::FACTORY;
    my ($content, $model, $modtype);
    my $name = shift;

    # allow an element, sequence, choice or model object to be defined
    # as the 'content' item, copied to the appropriate entry in the 
    # $config hash
    if ($content = $config->{ content }) {
	my $found = 0;
	foreach $modtype (@MODELS) {
	    if ($factory->isa( $modtype => $content )) {
		$config->{ $modtype } = $content;
		$found++;
		last;
	    }
	}	
	return $self->error("cannot determine content type for [$content]")
	    unless $found;
    }

    # now look for an element, sequence, choice or model either
    # provided directly or copied from the 'content' item above
    foreach $modtype (@MODELS) {
	if ($model = $config->{ $modtype }) {
	    return $factory->adopt( "${modtype}_particle" => $self, $config )
		|| $self->error($factory->error());
	}
    }
    return $self->error("particle expects one of: ", join(', ', @MODELS));
}


sub constrain {
    my ($self, $config) = @_;
    my ($min, $max) = @$config{ qw( minOccurs maxOccurs ) };
    $min = $config->{ min } unless defined $min;
    $max = $config->{ max } unless defined $max;
    $min = 1 unless defined $min;
    $max = 1 unless defined $max;

    return $self->error("maxOccurs ($max) is less than minOccurs ($min)")
	if $max < $min;

    @$self{ qw( min max occurs ) } = ($min, $max, 0);
    $self->TRACE("min => $min, max => $max") if $DEBUG;

    return $self;
}


sub type {
    return $_[0]->{ type };
}


sub models {
    return @MODELS;
}


sub min {
    my $self = shift;
    if (@_) {
	my $newmin = shift;
	return $self->error("maxOccurs ($self->{ max }) is less than minOccurs ($newmin)")
	    if $self->{ max } < $newmin;
	return ($self->{ min } = $newmin);
    }
    return $self->{ min };
}


sub max {
    my $self = shift;
    if (@_) {
	my $newmax = shift;
	return $self->error("maxOccurs ($newmax) is less than minOccurs ($self->{ min })")
	    if $newmax < $self->{ min };
	return ($self->{ max } = $newmax);
    }
    return $self->{ max };
}


sub occurs {
    return $_[0]->{ occurs };
}


sub start {
    my $self = shift;
    $self->TRACE() if $DEBUG;
    $self->{ occurs } = 0;
    return 1;
}


sub element {
    my ($self, $name) = @_;
    return $self->error("element <$name> called in base class");
}


sub decline {
    my $self = shift;
    $self->error(@_);
    $self->TRACE() if $DEBUG;
    return DECLINED;
}

sub end {
    my $self = shift;
    my ($min, $max, $occurs, $name ) 
	= @$self{ qw( min max occurs name ) };

    $self->TRACE() if $DEBUG;

    $self->{ _ERROR } = '';

    return $self->error("minimum of $min <$name> element", 
			$min > 1 ? 's' : '', " expected")
	if $occurs < $min;

    return $self->error("maximum of $max <$name> element",
			$max > 1 ? 's' : '', " exceeded")
	if $occurs > $max;

    return 1;
}


1;

__END__

=head1 NAME

XML::Schema::Particle - content particle for XM::Schema

=head1 SYNOPSIS

    my $particle = XML::Schema::Element::Particle->new({
	element   => $element,
	minOccurs => 1,
	maxOccurs => 3,
    });

=head1 DESCRIPTION

TODO

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Particle module,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema>, L<XML::Schema::Element>.

