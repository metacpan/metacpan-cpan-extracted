package Text::Playlist::PLS;

use strict;
use warnings;

use base 'Text::Playlist';

our $VERSION = '0.02';

sub new {
  my ($class) = @_;

  return bless({ }, $class);
}

sub parse {
  my ($self, $text) = @_;

  my @lines = split /\r?\n/, $text;
  my @items = ();

  # safeguard
  return "Not looks like playlist"
    unless grep { $_ eq "[playlist]" } @lines;

  my $count = 0;
  foreach my $line (@lines) {
    if ($line =~ m/(File|Title|Length)(\d+)\s*=\s*(.*)/oi) {
      my ($key, $num, $value) = (lc($1), $2 - 1, $3);
      $value =~ s/(^\s*|\s*$)//og;
      $items[$num] //= {};
      $items[$num]->{$key} = $value;
      next;
    }
    if ($line =~ m/numberofentries\s*=\s*(\d+)/oi) {
      $count = $1;
      next;
    }
  }

  warn "Number of entries not matches parsed items"
    if ($count != scalar @items);

  return wantarray ? @items : [ @items ];
}

sub dump {
  my ($self, @items) = @_;
  my $count = 0;
  my @lines = ('[playlist]');

  foreach my $item (@items) {
    $count += 1;
    foreach my $key (qw(file title length)) {
      push @lines, sprintf("%s%d=%s", ucfirst($key), $count, $item->{$key});
    }
  }

  splice(@lines, 1, 0, sprintf("numberofentries=%d", $count));
  push @lines, "Version=2", "";
  return join("\n", @lines);
}

1;

__END__

=pod

=head1 NAME

Text::Playlist::PLS - parser for 'pls' format

=head1 SYNOPSIS

  my $pls = Text::Playlist::PLS->new;
  my @items = $pls->load('/path/to/playlist.pls');

  foreach my $item (@items) {
    # <work with playlist items>
  }

  $pls->save('/path/to/new-playlist.pls', @items);

=head1 DESCRIPTION

Lightweight parser and generator for pls playlists.
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
  * length   -- item duration in seconds, or -1 if unknown

=head1 AUTHORS

  * Alex 'AdUser' Z <aduser@cpan.org>

=cut
