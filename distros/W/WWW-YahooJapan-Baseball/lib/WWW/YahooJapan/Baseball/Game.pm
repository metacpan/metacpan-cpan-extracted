package WWW::YahooJapan::Baseball::Game;

use URI;
use WWW::YahooJapan::Baseball::Parser;

sub new {
  my ($class, %self) = @_;
  for my $required (qw/uri/) {
    unless (defined $self{$required}) {
      return undef;
    }
  }
  ($self{id}) = $self{uri} =~ m/(20[0-9]{8})/;
  bless \%self, $class;
}

sub player_stats {
  my $self = shift;
  my $uri = $self->{uri}->clone;
  $uri->path($self->{uri}->path . 'stats');
  WWW::YahooJapan::Baseball::Parser::parse_game_stats_page(uri => $uri);
}

1;
