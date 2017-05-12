# $Id: VideoURI.pm,v 1.1 2007/08/29 17:35:11 gavin Exp $
# Copyright (c) Gavin Brown. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
package WWW::YouTube::VideoURI;
use Carp;
use HTTP::Request::Common;
use LWP;
use URI;
use URI::Escape;
use vars qw($VERSION);
use strict;

our $VERSION = '0.1';

sub new {
	my $self = bless({}, shift);
	$self->{ua} = LWP::UserAgent->new(
		agent => sprintf(
			'%s/%s, %s',
			ref($self),
			$VERSION,
			ucfirst($^O)
		),
		max_redirect => 0,
		requests_redirectable => [],
	);
	return $self;
}

sub get_video_uri {
	my ($self, $uri_s) = @_;
	my $uri = URI->new($uri_s);
	my %params = $uri->query_form;
	croak("Malformed URL or missing parameter") if ($params{v} eq '');

	my $new_uri = sprintf(
		'http://www.youtube.com/v/%s',
		uri_escape($params{v})
	);
	my $req = GET($new_uri);
	my $res = $self->{ua}->request($req);

	croak($res->status_line) if ($res->is_error);

	my $target = URI->new_abs($res->header('Location'), $new_uri);
	my %target_params = $target->query_form;

	return sprintf(
		'http://www.youtube.com/get_video.php?video_id=%s&t=%s',
		uri_escape($params{v}),
		uri_escape($target_params{t})
	);
}

1;

__END__

=pod

=head1 NAME

WWW::YouTube::VideoURI - a module to determine the URI of a Flash Video
file on YouTube.com

=head1 SYNOPSIS

	!/usr/bin/perl
	use WWW::YouTube::VideoURI;
	use LWP::Simple;
	
	my $yt = new WWW::YouTube::VideoURI;
	
	my $uri = 'http://www.youtube.com/watch?v=FMkJVXi7Rp8';
	
	my $video_uri = $yt->get_video_uri($uri);
	
	getstore($video_uri, "ze_frank.flv");

=head1 DESCRIPTION

L<http://www.youtube.com> is a wonderful service, but sometimes it is
not possible or desirable to watch the videos it offers online. Unlike
Google Video, YouTube does not offer a facility to download the videos
for offline viewing.

This module takes a standard YouTube.com URI and determines the URI of
the FLV file for a given video, which can then be retrieved for later
viewing.

=head1 USAGE

Apart from the constructor (which has no arguments) there is only one
method, C<get_video_uri>, which accepts a string containing a YouTube
URI. This method does minimal validation of the URI - it only requires
that there be a C<v> parameter in the query string. It then queries
the YouTube.com server for the other parameter required to generate a
valid video URI. You can then use another module such as L<LWP> to
retrieve this video.

If there is a problem with the URI supplied, or a network or HTTP error,
then this module will croak().

=head1 WARNING

C<WWW::YouTube::VideoURI> is not a "screen scraper" as such since it
does no HTML parsing: it merely scrutinises the HTTP headers returned by
the YouTube.com server. However, it is possible that the system used may
be changed by YouTube.com at any time and with no warning, so at some
time in the future, this module may stop functioning.

=head1 LICENSE AND COPYRIGHT

Copyright (c) Gavin Brown. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
