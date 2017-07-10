package WWW::RiotGames::LeagueOfLegends;
use strict;
use warnings;
use Moo;
use LWP;
use JSON;
use URI;
use Sub::Name;
use Types::Standard qw(Str Int Enum InstanceOf Bool);
use Function::Parameters;

our $VERSION = 0.0001;
$VERSION = eval $VERSION;

=head1 NAME

WWW::RiotGames::LeagueOfLegends - Perl wrapper around the Riot Games League of Legends API

=head1 SYNOPSIS

  use strict;
  use warnings;
  use aliased 'WWW::RiotGames::LeagueOfLegends' => 'LoL';

  my $lol = LoL->new( api_key => $api_key );
  # defaults ( region => 'na', timeout => 5 )

  my $champions = $lol->champions;
  my $champion_static_data = $lol->static_data( type => 'champions', id => 1 );
  my $summoner = $lol->summoner( summoner_name => 'Bob' );

=head1 DESCRIPTION

WWW::RiotGames::LeagueOfLegends is a simple Perl wrapper around the Riot Games League of Legends API.

It is as simple as creating a new WWW::RiotGames::LeagueOfLegends object and calling ->method
Each key/value pair becomes part of a query string, for example:

  $lol->static_data( type => 'champions', id => 1 );

results in the query string

  https://na1.api.riotgames.com/lol/static-data/v3/champions/1
  # api_key is added on

=head1 AUTHOR

Justin Hunter <justin.d.hunter@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Justin Hunter

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

has api_key => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has region => (
  is => 'ro',
  isa => Enum[qw( na1 euw1 eun1 jp1 kr oc1 br1 la1 la2 ru tr1 pbe1 )],
  required => 1,
  default => sub { 'na1' },
);

has ua => (
  is => 'lazy',
  handles => [ qw(request) ],
);

has api_url => (
  is => 'lazy',
  isa => Str,
  default => sub { 'https://' . $_[0]->region . '.api.riotgames.com' },
);

has timeout => (
  is => 'rw',
  isa => Int,
  lazy => 1,
  default => sub { 5 },
);

has json => (
  isa => InstanceOf['JSON'],
  is => 'lazy',
  handles => [ qw(decode) ],
);

has debug => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => sub { 0 },
);

has _testing => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => sub { 0 },
);

my %region2platform = (
  na   => { id => 'NA1',  domain => 'spectator.na.lol.riotgames.com',   port => 80 },
  euw  => { id => 'EUW1', domain => 'spectator.euw1.lol.riotgames.com', port => 80 },
  eune => { id => 'EUN1', domain => 'spectator.eu.lol.riotgames.com',   port => 8088 },
  jp   => { id => 'JP1',  domain => 'spectator.jp1.lol.riotgames.com',  port => 80 },
  kr   => { id => 'KR',   domain => 'spectator.kr.lol.riotgames.com',   port => 80 },
  oce  => { id => 'OC1',  domain => 'spectator.oc1.lol.riotgames.com',  port => 80 },
  br   => { id => 'BR1',  domain => 'spectator.br.lol.riotgames.com',   port => 80 },
  lan  => { id => 'LA1',  domain => 'spectator.la1.lol.riotgames.com',  port => 80 },
  las  => { id => 'LA2',  domain => 'spectator.la2.lol.riotgames.com',  port => 80 },
  ru   => { id => 'RU',   domain => 'spectator.ru.lol.riotgames.com',   port => 80 },
  tr   => { id => 'TR1',  domain => 'spectator.tr.lol.riotgames.com',   port => 80 },
  pbe  => { id => 'PBE1', domain => 'spectator.pbe1.lol.riotgames.com', port => 8088 },
);

sub _build_ua {
  my $self = shift;
  my $ua = LWP::UserAgent->new( timeout => $self->timeout, agent => __PACKAGE__ . ' ' . $VERSION, ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 } );
}

sub _build_json { JSON->new->utf8->allow_nonref }

method champion_mastery( Int :$summoner_id, Int :$champion_id = 0, Str :$type = 'champion-masteries' ) {
  # /lol/champion-mastery/v3/champion-masteries/by-summoner/{summonerId}
  # /lol/champion-mastery/v3/champion-masteries/by-summoner/{summonerId}/by-champion/{championId}
  # /lol/champion-mastery/v3/scores/by-summoner/{summonerId}

  my $url = $champion_id ?
    sprintf '%s/lol/champion-mastery/v%d/champion-masteries/by-summoner/%d/by-champion/%d', $self->api_url, 3, $summoner_id, $champion_id :
    sprintf '%s/lol/champion-mastery/v%d/%s/by-summoner/%d', $self->api_url, 3, $type, $summoner_id;
  $self->_request( $url );
}

method champions( Int :$champion_id = 0 ) {
  # /lol/platform/v3/champions
  # /lol/platform/v3/champions/{id}

  my $url = $champion_id ?
    sprintf '%s/lol/platform/v%d/champions/%d', $self->api_url, 3, $champion_id :
    sprintf '%s/lol/platform/v%d/champions', $self->api_url, 3;
  $self->_request( $url );
}

method league( Str :$type = 'challengerleagues', Str :$queue = '', Int :$summoner_id = 0 ) {
  # /lol/league/v3/challengerleagues/by-queue/{queue}
  # /lol/league/v3/leagues/by-summoner/{summonerId}
  # /lol/league/v3/masterleagues/by-queue/{queue}
  # /lol/league/v3/positions/by-summoner/{summonerId}

  my $url;
  if ( $type eq 'challengerleagues' || $type eq 'masterleagues' ) {
    $url = sprintf '%s/lol/league/v%d/%s/by-queue/%s', $self->api_url, 3, $type, $queue;
  } elsif ( $type eq 'leagues' || $type eq 'positions' ) {
    $url = sprintf '%s/lol/league/v%d/%s/by-summoner/%s', $self->api_url, 3, $type, $summoner_id;
  }
  $self->_request( $url );
}

method static_data( Str :$type, Int :$id = 0 ) {
  # /lol/static-data/v3/champions
  # /lol/static-data/v3/champions/{id}
  # /lol/static-data/v3/items
  # /lol/static-data/v3/items/{id}
  # /lol/static-data/v3/language-strings
  # /lol/static-data/v3/languages
  # /lol/static-data/v3/maps
  # /lol/static-data/v3/masteries
  # /lol/static-data/v3/masteries/{id}
  # /lol/static-data/v3/profile-icons
  # /lol/static-data/v3/realms
  # /lol/static-data/v3/runes
  # /lol/static-data/v3/runes/{id}
  # /lol/static-data/v3/summoner-spells
  # /lol/static-data/v3/summoner-spells/{id}
  # /lol/static-data/v3/versions

  my $url = $id ?
    sprintf '%s/lol/static-data/v%d/%s/%d', $self->api_url, 3, $type, $id :
    sprintf '%s/lol/static-data/v%d/%s', $self->api_url, 3, $type;
  $self->_request( $url );
}

method status() {
  # /lol/status/v3/shard-data

  my $url = sprintf '%s/lol/status/v%d/shard-data', $self->api_url, 3;
  $self->_request( $url );
}

method masteries( Int :$summoner_id ) {
  # /lol/platform/v3/masteries/by-summoner/{summonerId}

  my $url = sprintf '%s/lol/platform/v%d/masteries/by-summoner/%d', $self->api_url, 3, $summoner_id;
  $self->_request( $url );
}

method match( Int :$match_id = 0, Str :$type = 'matches', Int :$account_id = 0, Str :$tournament_code = '', Bool :$recent = 0 ) {
  # /lol/match/v3/matches/{matchId}
  # /lol/match/v3/matchlists/by-account/{accountId}
  # /lol/match/v3/matchlists/by-account/{accountId}/recent
  # /lol/match/v3/timelines/by-match/{matchId}
  # /lol/match/v3/matches/by-tournament-code/{tournamentCode}/ids
  # /lol/match/v3/matches/{matchId}/by-tournament-code/{tournamentCode}

  $type = 'matchlists' if $account_id;

  my $url;
  if ( $type eq 'matches' ) {
    if ( $match_id ) {
      $url = $tournament_code ?
        sprintf '%s/lol/match/v%d/%s/%d/by-tournament-code/%s', $self->api_url, 3, $type, $match_id, $tournament_code :
        sprintf '%s/lol/match/v%d/%s/%d', $self->api_url, 3, $type, $match_id;
    } elsif ( $tournament_code ) {
      $url = sprintf '%s/lol/match/v%d/%s/by-tournament-code/%s/ids', $self->api_url, 3, $type, $tournament_code;
    }
  } elsif ( $type eq 'matchlists' ) {
    $url = $recent ? 
      sprintf '%s/lol/match/v%d/%s/by-account/%d/recent', $self->api_url, 3, $type, $account_id :
      sprintf '%s/lol/match/v%d/%s/by-account/%d', $self->api_url, 3, $type, $account_id;
  } elsif ( $type eq 'timelines' ) {
    $url = sprintf '%s/lol/match/v%d/%s/by-match/%d', $self->api_url, 3, $type, $match_id;
  }
  $self->_request( $url );
}

method runes( Int :$summoner_id ) {
  # /lol/platform/v3/runes/by-summoner/{summonerId}

  my $url = sprintf '%s/lol/platform/v%d/runes/by-summoner/%d', $self->api_url, 3, $summoner_id;
  $self->_request( $url );
}

method spectator( Int :$summoner_id = 0 ) {
  # /lol/spectator/v3/active-games/by-summoner/{summonerId}
  # /lol/spectator/v3/featured-games

  my $url = $summoner_id ?
    sprintf '%s/lol/spectator/v%d/active-games/by-summoner/%d', $self->api_url, 3, $summoner_id :
    sprintf '%s/lol/spectator/v%d/featured-games', $self->api_url, 3;
  $self->_request( $url );
}

method summoner( Int :$account_id = 0, Int :$summoner_id = 0, Str :$summoner_name = '' ) {
  # /lol/summoner/v3/summoners/by-account/{accountId}
  # /lol/summoner/v3/summoners/by-name/{summonerName}
  # /lol/summoner/v3/summoners/{summonerId}

  my $url;
  if ( $account_id ) {
    $url = sprintf '%s/lol/summoner/v%d/summoners/by-account/%d', $self->api_url, 3, $account_id;
  } elsif ( $summoner_id ) {
    $url = sprintf '%s/lol/summoner/v%d/summoners/%d', $self->api_url, 3, $summoner_id;
  } elsif ( $summoner_name ) {
    $url = sprintf '%s/lol/summoner/v%d/summoners/by-name/%s', $self->api_url, 3, $summoner_name;
  }
  $self->_request( $url );
}

method _request( Str $url ) {
  my $uri = URI->new( $url );
  $uri->query_form( api_key => $self->api_key );
  warn $uri->as_string if $self->debug;
  return $uri->as_string if $self->_testing;

  my $req = HTTP::Request->new('GET', $uri->as_string);
  my $response = $self->request( $req );
  return $response->is_success ? $self->decode($response->content) : $response->status_line;
}

1;
