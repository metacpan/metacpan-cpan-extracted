package Text::Playlist::M3U;

use strict;
use warnings;

use base 'Text::Playlist';

our $VERSION = '0.02';

sub new {
  my ($class) = @_;

  return bless({ attrs => {}, }, $class);
}

sub parse {
  my ($self, $text) = @_;

  my @lines = split /\r?\n/, $text;
  my @items = ();

  # safeguard
  return "Not looks like playlist"
    unless grep { $_ =~ m/^#EXTM3U/o } @lines;

  my $item = undef;
  foreach my $line (@lines) {
    # header
    if ($line =~ m/#EXTM3U(\s+\S+?=\S+)*/oi) {
      return "Multiple EXTM3U lines found"
        if (scalar keys($self->{attrs}));
      $self->{attrs} = $self->_parse_attrs($1);
    }
    # standart tags
    if ($line =~ m/^\s*#EXTINF:(-?\d+(?:\.\d+)?)(\s+\S+?=\S+)*,\s*(.*)/oi) {
      $item //= {
        duration => $1,
        attrs    => $self->_parse_attrs($2),
        title    => $3,
      };
    }
    # extended tags
    if ($line =~ m/^\s*#EXT-X-\S+?:(\s*\S+?=\S+)/oi) {
      # ignore
    }
    # comments
    if ($line =~ m/^\s*#/) {
      next;
    }
    # path / url
    if ($line) {
      $item->{file} = $line;
      push @items, $item;
      undef $item;
    }
  }

  return wantarray ? @items : [ @items ];
}

sub _parse_attrs {
  my ($self, $str) = @_;

  return {} unless $str;
  my %attrs = ();
  $str =~ s/(^\s+|\s+$)//oi;
  foreach my $token (split /\s+/, $str) {
    my ($key, $value) = split("=", $token, 2);
    $attrs{$key} = $value;
  }

  return \%attrs;
}

sub _dump_attrs {
  my ($self, $attrs) = @_;
  my @parts = ('');

  while (my ($key, $value) = each %{$attrs}) {
    push @parts, sprintf("%s=%s", $key, $value);
  }
  return @parts ? join(" ", @parts) : "";
}

sub dump {
  my ($self, @items) = @_;
  my @lines = ();
  push @lines, sprintf('#EXTM3U%s', $self->_dump_attrs($self->{attrs}));

  foreach my $item (@items) {
    push @lines, sprintf("#EXTINF:%s%s,%s", $item->{duration},
         $self->_dump_attrs($item->{attrs}), $item->{title});
    push @lines, $item->{file};
  }

  push @lines, '';
  return join("\n", @lines);
}

1;

__END__

=pod

=head1 NAME

Text::Playlist::M3U - parser for 'm3u' format

=head1 SYNOPSIS

  my $m3u = Text::Playlist::M3U->new;
  my @items = $m3u->load('/path/to/playlist.m3u');

  foreach my $item (@items) {
    # <work with playlist items>
  }

  $m3u->save('/path/to/new-playlist.m3u', @items);

=head1 DESCRIPTION

Lightweight parser and generator for m3u playlists.
Will be usefull if you're just want to read playlist, or convert playlist
to another format, or change playlist items by some way.

=head1 Methods

=head2 C<load>

=head2 C<parse>

=head2 C<save>

=head2 C<dump>

For description of these methods see description in base class L<Text::Playlist>

=head1 Item format

Each parsed item has the following keys in hashref:

  * file     -- path or url, required
  * title    -- title for given item, required
  * duration -- item duration in seconds, or -1 if not unknown
  * attrs    -- hashref with attributes for given item, optional

=head1 SEE ALSO

L<MP3::M3U::Parser> -- full-featured parser

=head1 AUTHORS

  * Alex 'AdUser' Z <aduser@cpan.org>

=cut
