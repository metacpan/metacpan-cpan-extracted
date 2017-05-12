# XML::CAP::Area - class for XML::CAP <area> element classes
# Copyright 2009 by Ian Kluft
# This is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# parts derived from XML::Atom::Feed

package XML::CAP::Area;
use strict;
use warnings;
use base qw( XML::CAP::Base );
use XML::CAP;
use XML::CAP::Geocode;

# inherits initialize() from XML::CAP::Base

# get list of <geocode> elements
#sub geocodes
#{
#	my $self = shift;
#	my @res = $self->elem->getElementsByTagNameNS($self->ns, 'geocode')
#		or return;
#	my @geocodes;
#	for my $res (@res) {
#		my $geocode = XML::CAP::Info->new(Elem => $res->cloneNode(1));
#		push @geocodes, $geocode;
#	}
#	@geocodes;
#}

# add an <geocode> element
sub add_geocodes
{
	my $self = shift;
	my($geocode, $opt) = @_;

	# note included from corresponding code in XML::Atom::Feed...
	# When doing an insert, we try to insert before the first <entry> so
	# that we don't screw up any preamble.  If there are no existing
	# <entry>'s, then fall back to appending, which should be
	# semantically identical.
	$opt ||= {};
	my ($first_entry) = $self->elem->getChildrenByTagNameNS($geocode->ns,
		'geocode');
	if ($opt->{mode} && $opt->{mode} eq 'insert' && $first_entry) {
		$self->elem->insertBefore($geocode->elem, $first_entry);
	} else {
		$self->elem->appendChild($geocode->elem);
	}
}

sub element_name { 'area' }

# make accessors
__PACKAGE__->mk_elem_accessors(qw( areaDesc polygon circle altitude ceiling ));
__PACKAGE__->mk_object_list_accessor( 'geocode' => 'XML::CAP::Area',
	'geocodes' );

1;
