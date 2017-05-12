package WWW::SVT::Play::Video;

# Copyright (c) 2012, 2013 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

WWW::SVT::Play::Video, extract information about videos on SVT Play

=head1 SYNOPSIS

 use WWW::SVT::Play::Video;

 my $uri = 'http://www.svtplay.se/video/1014238/del-8';
 my $svtp = WWW::SVT::Play::Video->new($uri);
 say $svtp->title;

 if ($svtp->has_hls) {
         say $svtp->stream(protocol => 'HLS')->url;
 }

=head1 DESCRIPTION

=cut

use warnings FATAL => 'all';
use strict;

our $VERSION = 0.12;
use Carp;

use WWW::SVT::Play::Video::Stream;
use WWW::SVT::Play::Utils qw(playertype_map);

use LWP::UserAgent;
use List::Util qw/max/;
use Encode;
use JSON;
use URI;
use URI::QueryParam;
use URI::Escape;

use Data::Dumper;
$Data::Dumper::Indent = 1;

=head1 CONSTRUCTOR

=head2 WWW::SVT::Play::Video->new($uri)

Construct a WWW::SVT::Play::Video object by passing the URL to
the video you're interested in. A second argument consisting of a
hashref of options is reserved for future use.

=cut

sub new {
	my $class = shift;
	my $url = shift;
	my $self = bless {}, $class;

	my $uri = URI->new($url);
	$uri->query_form('output', 'json');

	my $json = _get("$uri");
	$self->{_json} = _get_json($json);

	my %streams;
	my %has; # what kind of streams does this video have?

	for my $stream (@{$self->{_json}->{video}->{videoReferences}}) {
		my $obj = WWW::SVT::Play::Video::Stream->from_json($stream);
		next unless defined $obj;

		if ($obj->is_rtmp) {
			$has{rtmp} = 1;
			$streams{rtmp}->{$obj->bitrate} = $obj;
		} else {
			$has{$obj->type} = 1;
			$streams{$obj->type} = $obj;
		}
	}

	my @subtitles = map {
		$_->{url}
	} grep { $_->{url} } @{$self->{_json}->{video}->{subtitleReferences}};

	$self->{url} = $url;
	$self->{streams} = \%streams;
	$self->{filename} = $self->_gen_filename;
	$self->{subtitles} = \@subtitles;
	$self->{duration} = $self->{_json}->{video}->{materialLength};
	$self->{title} = $self->{_json}->{context}->{title};

	$self->{has} = \%has;

	return $self;
}

=head2 url

 $svtp->url

Returns the URL to the video's web page after it has been,
postprocessed somewhat.

=cut

sub url {
	my $self = shift;
	return $self->{url};
}

=head2 stream

 $svtp->stream( protocol => 'HLS' )
 $svtp->stream( internal => 'ios' )
 $svtp->stream( protocol => 'RTMP', bitrate => '1400')

 my $url = $svtp->stream( protocol => 'HLS' )->url
     if $svtp->has_hls;

Returns the stream object matching the given requirement (or
undef if video does not have a matching stream). Takes either SVT
Play internal playerType name (named parameter: internal), or the
protocol name (named parameter: protocol).

Currently supported protocols: HLS, HDS and RTMP. If extracting
RTMP, an optional bitrate parameter can be supplied. If this
isn't supplied, a hash of bitrate url pairs is returned.

RTMP is deprecated and no longer in use by SVT Play. Support for
this may be dropped in the future.

=cut

sub stream {
	my $self = shift;
	my %args = @_;

	my $type = lc $args{protocol};
	$type  //= playertype_map($args{internal});

	my $bitrate = $args{bitrate};

	if ($bitrate and $type eq 'rtmp') {
		return $self->{streams}->{rtmp}->{$bitrate};
	}

	return $self->{streams}->{$type} if
		exists $args{protocol};
}

=head2 title

Returns a human readable title for the video.

=cut

sub title {
	my $self = shift;
	return $self->{title};
}

=head2 $svtp->filename($type)

Returns a filename suggestion for the video. If you give the
optional type argument, you also get a file extension.

=cut

sub filename {
	my $self = shift;
	my $type = shift;
	my $filename = $self->{filename};
	my $ext = $self->_ext_by_type($type) if $type;
	return $self->{filename} unless $ext;
	return sprintf "%s.%s", $filename, $ext;
}

=head2 $svtp->rtmp_bitrates

In list context, returns a list of available RTMP stream bitrates
for the video. In scalar context, the highest available bitrate
is returned.

B<Note:> Currently, we only support listing bitrates for RTMP
streams, since they are given to us directly in the JSON blob.

=cut

sub rtmp_bitrates {
	my $self = shift;
	my @streams;

	return unless $self->has_rtmp;
	return max keys %{$self->{streams}->{rtmp}} if not wantarray;
	return keys %{$self->{streams}->{rtmp}};
}

=head2 $svtp->format($bitrate)

Returns a "guess" of what the format is, by trying to extract a
file extension from the stream URL. Of course, the format depends
on what bitrate you want, so you have to supply that.

=cut

sub format {
	my $self = shift;
	my $bitrate = shift;

	my ($ext) = $self->{streams}->{$bitrate} =~ m#\.(\w+)$#;
	return $ext;
}

=head2 $svtp->subtitles

In list context, returns a list of URLs to subtitles. In scalar
context, returns the first URL in that list. If there are no
subtitles available for this video, returns an empty list (in
list context) or undef (in scalar context).

=cut

sub subtitles {
	my $self = shift;
	my @subtitles;
	push @subtitles, @{$self->{subtitles}};

	return @subtitles if wantarray;
	return $subtitles[0];
}

=head2 $svtp->duration

Returns the length of the video in seconds.

=cut

sub duration {
	my $self = shift;
	return $self->{duration};
}

=head2 $svtp->has_hls

=cut

sub has_hls {
	my $self = shift;
	return $self->{has}->{hls};
}

=head2 $svtp->has_hds

=cut

sub has_hds {
	my $self = shift;
	return $self->{has}->{hds};
}

=head2 $svtp->has_rtmp

=cut

sub has_rtmp {
	my $self = shift;
	return $self->{has}->{rtmp};
}

=head2 $svtp->has_http

=cut

sub has_http {
	my $self = shift;
	return $self->{has}->{http};
}

## INTERNAL SUBROUTINES
##  These are *not* easter eggs or something like that. Yes, I'm
##  looking at you, Woldrich!

sub _get {
	my $uri = shift;
	my $ua = LWP::UserAgent->new(
		agent => "WWW::SVT::Play/$VERSION",
	);
	$ua->env_proxy;
	my $resp = $ua->get($uri);

	return $resp->decoded_content if $resp->is_success;
	die "Failed to fetch $uri: ", $resp->status_line;
}

sub _get_json {
	my $json_blob = shift;

	# I have no idea what I'm doing and why I have to
	# encode $json_blob as UTF-8... I should probably
	# go read some perluniintro... :-(
	$json_blob = encode('UTF-8', $json_blob);
	return decode_json($json_blob);
}

sub _get_stream_by_protocol {
	my $self = shift;
	my $proto = lc(shift);

	my %type_map = (
		hds => 'flash',
		hls => 'ios',
	);

	my $internal = $type_map{$proto};
	if (not defined $internal) {
		carp "Unknown protocol $proto";
		return;
	}

	return $self->{streams}->{$internal};
}

sub _gen_filename {
	my $self = shift;

	my $stats_url = URI->new($self->{_json}->{statistics}->{statisticsUrl});
	return uri_unescape($stats_url->query);
}

sub _ext_by_type {
	my $self = shift;
	my $type = shift;

	return 'mp4' if $type eq 'hls';
	return 'flv' if $type eq 'hds';
	return $type; # better than nothing, i guess...
}

=head1 COPYRIGHT

Copyright (c) 2012, 2013 - Olof Johansson <olof@cpan.org>

All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
