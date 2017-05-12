# XML::CAP::Info - class for XML::CAP <info> element classes
# Copyright 2009 by Ian Kluft
# This is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# parts derived from XML::Atom::Feed

package XML::CAP::Info;
use strict;
use warnings;
use base qw( XML::CAP::Base );
use XML::CAP;
use XML::CAP::Resource;
use XML::CAP::Area;

=head1 NAME

XML::CAP::Alert - XML Common Alerting Protocol "alert" element class

=head1 SYNOPSIS

    use XML::CAP::Info;

    # get Info object from contents of XML::CAP::Alert
    my @infos = $alert->infos;
    foreach $info ( @infos ) {
    	# use the $info object as shown in examples below
    }

    # create new object
    my $info = XML::CAP::Info->new();

    # read values
    $language = $info->language;
    $category = $info->category;
    $event = $info->event;
    $responseType = $info->responseType;
    $urgency = $info->urgency;
    $severity = $info->severity;
    $certainty = $info->certainty;
    $audience = $info->audience;
    $eventCode = $info->eventCode;
    $effective = $info->effective;
    $onset = $info->onset;
    $expires = $info->expires;
    $senderName = $info->senderName;
    $headline = $info->headline;
    $description = $info->description;
    $instruction = $info->instruction;
    $web = $info->web;
    $contact = $info->contact;
    $parameter = $info->parameter;

    # write values
    $info->language( $lang );
    $info->category( $cat );
    $info->event( $event );
    $info->responseType( $response_type );
    $info->urgency( $urgency );
    $info->severity( $severity );
    $info->certainty( $certainty );
    $info->audience( $audience );
    $info->eventCode( $event_code );
    $info->effective( $effective );
    $info->onset( $onset );
    $info->expires( $expires );
    $info->senderName( $sender_name );
    $info->headline( $headline );
    $info->description( $desc );
    $info->instruction( $instruction );
    $info->web( $url );
    $info->contact( $contact );

=cut

# inherits initialize() from XML::CAP::Base

sub element_name { 'info' }

# get list of <resource> elements
#sub resources
#{
#	my $self = shift;
#	my @res = $self->elem->getElementsByTagNameNS($self->ns, 'resource')
#		or return;
#	my @resources;
#	for my $res (@res) {
#		my $resource = XML::CAP::Info->new(Elem => $res->cloneNode(1));
#		push @resources, $resource;
#	}
#	@resources;
#}

# add an <resource> element
sub add_resources
{
	my $self = shift;
	my($resource, $opt) = @_;

	# note included from corresponding code in XML::Atom::Feed...
	# When doing an insert, we try to insert before the first <entry> so
	# that we don't screw up any preamble.  If there are no existing
	# <entry>'s, then fall back to appending, which should be
	# semantically identical.
	$opt ||= {};
	my ($first_entry) = $self->elem->getChildrenByTagNameNS($resource->ns,
		'resource');
	if ($opt->{mode} && $opt->{mode} eq 'insert' && $first_entry) {
		$self->elem->insertBefore($resource->elem, $first_entry);
	} else {
		$self->elem->appendChild($resource->elem);
	}
}

# get list of <area> elements
#sub areas
#{
#	my $self = shift;
#	my @res = $self->elem->getElementsByTagNameNS($self->ns, 'area')
#		or return;
#	my @areas;
#	for my $res (@res) {
#		my $area = XML::CAP::Info->new(Elem => $res->cloneNode(1));
#		push @areas, $area;
#	}
#	@areas;
#}

# add an <area> element
sub add_areas
{
	my $self = shift;
	my($area, $opt) = @_;

	# note included from corresponding code in XML::Atom::Feed...
	# When doing an insert, we try to insert before the first <entry> so
	# that we don't screw up any preamble.  If there are no existing
	# <entry>'s, then fall back to appending, which should be
	# semantically identical.
	$opt ||= {};
	my ($first_entry) = $self->elem->getChildrenByTagNameNS($area->ns,
		'area');
	if ($opt->{mode} && $opt->{mode} eq 'insert' && $first_entry) {
		$self->elem->insertBefore($area->elem, $first_entry);
	} else {
		$self->elem->appendChild($area->elem);
	}
}

# make accessors
__PACKAGE__->mk_elem_accessors(qw( language category event responseType urgency severity certainty audience eventCode effective onset expires senderName headline description instruction web contact parameter ));
__PACKAGE__->mk_object_list_accessor( 'resource' => 'XML::CAP::Resource',
	'resources' );
__PACKAGE__->mk_object_list_accessor( 'area' => 'XML::CAP::Area',
	'areas' );

1;
