package VideoLAN::LibVLC::Media;
use strict;
use warnings;
use VideoLAN::LibVLC;
use Carp;

# ABSTRACT: Playable media stream
our $VERSION = '0.05'; # VERSION


sub path { shift->{path} }
sub location { shift->{location} }
sub fd { shift->{fd} }


sub metadata { $_[0]{metadata} ||= $_[0]->_build_metadata }


sub new {
	my $class= shift;
	my %args= (@_ == 1 && ref($_[0]) eq 'HASH')? { $_[0] }
		: (@_ & 1) == 0? @_
		: croak "Expected hashref or even length list";
	defined $args{libvlc} or croak "Missing required attribute 'libvlc'";
	1 == (defined $args{path}? 1 : 0) + (defined $args{location}? 1 : 0) + (defined $args{fd}? 1 : 0)
		or croak "You must supply exactly one of 'path','location','args'";
	my $self= defined $args{fd}? VideoLAN::LibVLC::libvlc_media_new_fd($args{libvlc}, fileno($args{fd}))
		: defined $args{path}? VideoLAN::LibVLC::libvlc_media_new_path($args{libvlc}, "$args{path}")
		: VideoLAN::LibVLC::libvlc_media_new_location($args{libvlc}, "$args{location}");
	%$self= %args;
	return $self;
}


sub parse {
	VideoLAN::LibVLC::libvlc_media_parse(shift);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VideoLAN::LibVLC::Media - Playable media stream

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This object wraps C<libvlc_media_t>, which is an open stream of playable media.
It can be created from a file descriptor, path, or URL (L</location>).
Specify one of those options to the constructor, and also a library instance
in the L</libvlc> attribute.

A quick and easy way to create media objects is with L<VideoLAN::LibVLC/new_media>,
which auto-detects the type of thing you are trying to open.

=head1 ATTRIBUTES

=head2 path

File name of media. One of 3 possible constructor parameters

=head2 location

URI of media.  Does not need to be a URI object.
One of 3 possible constructor parameters.

=head2 fd

File descriptor of media file.  Must be a "real" file handle with a defined
C<fileno>.

=head2 metadata

Hashref of metadata tags extracted from the media file.  These are not
available (undef) until after the media has been parsed, which is a blocking
operation that depends on the decoder thread.  See L</parse>.

Some tags are only supported by newer versions of libvlc.  The current
possible list is:

  Title
  Artist
  Genre
  Copyright
  Album
  TrackNumber
  Description
  Rating
  Date
  Setting
  URL
  Language
  NowPlaying
  Publisher
  EncodedBy
  ArtworkURL
  TrackID
  TrackTotal
  Director
  Season
  Episode
  ShowName
  Actors
  AlbumArtist
  DiscNumber
  DiscTotal

=head1 METHODS

=head2 new

  my $media= VideoLAN::LibVLC::Media->new(
    libvlc => $vlc,
    location => $url,      # 
    path     => $filename, # specify only one
    fd       => $handle,   # 
  );

=head2 parse

Parse the media stream

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
