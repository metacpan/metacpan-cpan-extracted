package WWW::YahooJapan::Baseball;
use 5.008001;
use strict;
use warnings;
use utf8;

use WWW::YahooJapan::Baseball::Game;
use WWW::YahooJapan::Baseball::Parser;
use URI;

our $VERSION = "0.04";

sub new {
  my ($class, %self) = @_;
  for my $required (qw/date league/) {
    unless (defined $self{$required}) {
      return undef;
    }
  }
  unless (defined $self{prefix}) {
    $self{prefix} = 'http://baseball.yahoo.co.jp';
  }
  bless \%self, $class;
}

sub games {
  my $self = shift;
  my $uri = URI->new($self->{prefix} . '/npb/schedule/?date=' . $self->{date});
  my @game_uris = WWW::YahooJapan::Baseball::Parser::parse_games_page($self->{date}, $self->{league}, uri => $uri);
  map { WWW::YahooJapan::Baseball::Game->new(uri => $_) } @game_uris;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::YahooJapan::Baseball - Fetches Yahoo Japan's baseball stats

=head1 SYNOPSIS

    use WWW::YahooJapan::Baseball;
    use Data::Dumper;

    my $client = WWW::YahooJapan::Baseball->new(date => '20151001', league => 'NpbPl');
    for my $game ($client->games) {
      my %stats = $game->player_stats;
      print Dumper \%stats;
    }

=head1 DESCRIPTION

WWW::YahooJapan::Baseball provides a way to fetch Japanese baseball stats via Yahoo Japan's baseball service.

=head1 LICENSE

Copyright (C) Shun Takebayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shun Takebayashi E<lt>shun@takebayashi.asiaE<gt>

=cut

