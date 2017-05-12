package WWW::SVT::Play::Video::Stream;

# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

WWW::SVT::Play::Video::Stream, base class representing a stream

=head1 SYNOPSIS

 use WWW::SVT::Play::Video;

 my $svtp = WWW::SVT::Play::Video->new($url);
 my $stream = $svtp->stream(protocol => 'HDS');


 use WWW::SVT::Play::Video::Stream;

 # get a flashvar json blob, JSON decode it and feed it to ->from_json:
 my $svtp_stream = WWW::SVT::Play::Video::Stream->from_json($json);

=head1 DESCRIPTION

This module is responsible for determining the type of stream
object that should be created for each stream.

=cut

use warnings FATAL => 'all';
use strict;

our $VERSION = 0.12;
use Carp;

use WWW::SVT::Play::Utils qw(playertype_map);
use URI;

use WWW::SVT::Play::Video::Stream::HLS;
use WWW::SVT::Play::Video::Stream::HDS;
use WWW::SVT::Play::Video::Stream::RTMP;
use WWW::SVT::Play::Video::Stream::HTTP;

use Data::Dumper;

$Data::Dumper::Indent = 1;

=head1 CONSTRUCTOR

=head2 new

Takes the following named parameters for setting attributes:

=over

=item * url

=item * type

=back

And in some cases, other protocol specific attributes..

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

=head2 from_json

Wrapper around the constructor; can be fed a videoReference
element of the SVT Play JSON blob and return an object
representing that stream.

=cut

sub from_json {
	my $class = shift;
	my $json = shift;

	my $uri = URI->new($json->{url});

	my $type;
	if (lc $uri->scheme eq 'rtmp') {
		$type = 'rtmp' if lc $uri->scheme =~ /^rtmpe?$/;
	} else {
		$type = playertype_map($json->{playerType}) // '';
	}

	if ($type eq 'rtmp') {
		return WWW::SVT::Play::Video::Stream::RTMP->new(
			type => $type,
			url => $json->{url},
			bitrate => $json->{bitrate},
		);
	}

	if ($type eq 'hls') {
		return WWW::SVT::Play::Video::Stream::HLS->new(
			type => $type,
			url => $json->{url},
		);
	}

	if ($type eq 'http') {
		if ($json->{url} =~ m#/manifest\.f4m$#) {
			return WWW::SVT::Play::Video::Stream::HDS->new(
				type => 'hds',
				url => $json->{url},
			);
		} else {
			return WWW::SVT::Play::Video::Stream::HTTP->new(
				type => $type,
				url => $json->{url},
			);
		}
	}

	return WWW::SVT::Play::Video::Stream->new(
		type => $json->{playerType},
		url => $json->{url},
	);
}

=head1 METHODS

=head2 url

Return the url of the stream.

=cut

sub url {
	my $self = shift;
	return $self->{url};
}

=head2 type

Return the protocol type of the stream (e.g. hds, hls, rtmp).

=cut

sub type {
	my $self = shift;
	return $self->{type};
}

=head2 is_hls

Is stream using HLS protocol? Should be overriden.

=cut

sub is_hls  { 0 }

=head2 is_hds

Is stream using HDS protocol? Should be overriden.

=cut

sub is_hds  { 0 }

=head2 is_rtmp

Is stream using RTMP protocol? Should be overriden.

=cut

sub is_rtmp { 0 }

=head2 is_http

Is stream using HTTP protocol? Should be overriden.

=cut

sub is_http { 0 }

=head2 stream

This is a default noop stream handler. This method is meant to be
called when the user wants to stream the stream using a media
player or similar. It should be overriden with a protocol capable
handler.

=cut

sub stream {
	my $self = shift;
	carp "No stream handler defined for the $self->{type} protocol.";
	carp "Can't play stream."
}

=head2 download

This is a default noop download handler. This method is meant to
be called when the user wants to download the stream. It should
be overriden with a protocol capable handler.

=cut

sub download {
	my $self = shift;
	carp "No download handler defined for the $self->{type} protocol.";
	carp "Can't download stream."
}

=head1 COPYRIGHT

Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
