=head1 NAME

WebService::SongLyrics - Retrieve song lyrics from www.songlyrics.com

=head1 SYNOPSIS

  use WebService::SongLyrics;

  my $wsl = WebService::SongLyrics->new;

  my $lyrics = $wsl->get_lyrics("Beyonce", "Crazy in love");

=head1 DESCRIPTION

The WebService::SongLyrics module attempts to scrape song lyrics from
http://www.songlyrics.com Due to the nature of screen scraping it's not
the most resilient of code.

Thanks to the sites search engine it's a little picky about the
phrasing of the song and artist. It especially doesn't like "Artist ft
other artist".

=head1 EXAMPLES

  use WebService::SongLyrics;

  my $wsl = WebService::SongLyrics->new;

  my $lyrics = $wsl->get_lyrics("Beyonce", "Crazy in love");

  print $lyrics, "\n" if $lyrics;

=cut

#######################################################################

package WebService::SongLyrics;
use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;
use vars qw($VERSION);

$VERSION = '0.01';
my $ua   = new LWP::UserAgent;

=head1 METHODS

=over 4

=item new ( chart => 'chart type' )

This is the constructor for a new WebService::SongLyrics object. It takes
no arguments and simply returns a new instance.

=back

=cut

sub new {
  my $class = shift;
  my $self = {};

  $self->{base_url} = 'http://www.songlyrics.com';

  bless ($self, $class);
  return $self;
}

#----------------------------------------#

=over 4

=item get_lyrics ( $artist, $song_title )

The C<get_lyrics> method requires both an artist and a song title and
returns the lyrics for the given combination. If it can find them.

It returns C<undef> if you fail to pass in either parameter or if it
can't find the lyrics. It C<die>s with a short message and the URL if
the server can't be found or it gets a HTTP status code that
indicates failure.

=back

=cut


sub get_lyrics {
  my $self = shift;
  my ($artist, $song_title) = @_;

  return unless ($artist && $song_title);

  my $artist_url  = _get_pages($artist, $song_title, $self->{base_url});
  my $lyrics_page = _get_lyrics_page($artist_url, $song_title, $self->{base_url});
  my $lyrics      = _get_lyrics($lyrics_page);

  return $lyrics;
}

#----------------------------------------#

sub _get {
  my $url      = shift;
  my $resource = $ua->get($url);

  if ( $resource->is_success ) {
    return $resource->content;
  } else {
    die "Failed to process '$url'";
  }
}

#----------------------------------------#

# get the results from the search and try and pull out the right page

sub _get_pages {
  my $artist    = shift;
  my $songtitle = shift;
  my $base_url  = shift;
  my @matches;

  my $search = uri_escape("$artist $songtitle");
  my $cruft  = qq!/search.php?key=$search&x=13&y=8&sb%5B0%5D=_author&sb%5B2%5D=_name!;

  my $content = _get("$base_url$cruft");

  if ($content) {
    if ($content =~ m!<a href="(/song-lyrics/.+?\.html)"!) {
      return $1;
    }
  }
}

#----------------------------------------#

# find the now we've got the search results find the link that matches the
# song title and pull it out.

sub _get_lyrics_page {
  my $lyrics_path = shift;
  my $song_title  = shift;
  my $base_url    = shift;
  my $lyrics_url = "$base_url$lyrics_path";

  my $content = _get($lyrics_url);

  if ($content) {
    if ($content =~ m!<a href="(/song-lyrics/.+?\.html)">$song_title</a>!i) {
      return "$base_url$1";
    }
  }
}

#----------------------------------------#

# get the page with the lyrics and extract them with a very fragile regex

sub _get_lyrics {
  my $lyrics_page = shift;

  my $content = _get($lyrics_page);

  if ($content) { # this regex is very fragile.
    if ($content =~ m!Ringtones</a>(.*?)<br><table align="right" border="0"><tr><td>!s) {
      my $lyrics = $1;
      $lyrics =~ s/<br>//g;
      return $lyrics;
    }
  }
}
#----------------------------------------#

1;

#######################################################################

=head1 NOTES

I originally planned to release this under the Lyrics::Fetch namespace but
after spending some time digging through the (very limited) docs and
descriptions I thought it'd be better to do it as a stand-alone module.

The namespace is a little pretentious but it does fit with the other
WebService::DomainName modules already on CPAN.

=head1 DEPENDENCIES

WebService::SongLyrics requires the following modules:

L<LWP::UserAgent>

L<URI::Escape>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 Dean Wilson.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com>

=cut
