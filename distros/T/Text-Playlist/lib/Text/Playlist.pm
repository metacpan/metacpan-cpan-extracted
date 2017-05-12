package Text::Playlist;

use strict;
use warnings;

our $VERSION = '0.02';

sub items {
  my ($self) = @_;

  return wantarray ? @{$self->{items}} : $self->{items};
}

sub parse { die("must be implemented by subclass\n") }
sub dump  { die("must be implemented by subclass\n") }

sub load {
  my ($self, $file) = @_;

  open(my $FH, "<", $file) or return $!;
  local $/ = undef;
  my $content = <$FH>;
  close($FH);

  return $self->parse($content);
}

sub save {
  my ($self, $file, @items) = @_;

  open(my $FH, ">", $file) or die $!;
  print $FH $self->dump(@items);
  close($FH);

  return 1;
}

1;

=pod

=head1 NAME

Text::Playlist -- base class for work with various playlist formats

=head1 DESCRIPTION

This module acts only as base class for specific parsers.

=head1 Methods

=head2 C<load>

  my @items = $pls->load('playlist.pls');

Simple helper for loading playlist from file. See also C<parse>.

=head2 C<parse>

  my @items = $pls->parse($text);

Takes playlist text and returns array of hashrefs with playlist items. In scalar content returns arrayref.

=head2 C<save>

  $pls->save('playlist.pls', @items);

Simple helper for saving playlist to file. See also C<dump>.

=head2 C<dump>

  my $text = $pls->dump(@items);

Takes array of hashrefs with playlist items and returns constructed playlist.

=head1 SEE ALSO

L<Text::Playlist::M3U>, L<Text::Playlist::PLS>, L<Text::Playlist::XSPF>

=head1 AUTHORS

  * Alex 'AdUser' Z <aduser@cpan.org>

=cut
