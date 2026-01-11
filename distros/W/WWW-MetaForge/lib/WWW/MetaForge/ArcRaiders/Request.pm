package WWW::MetaForge::ArcRaiders::Request;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: HTTP Request factory for MetaForge ARC Raiders API
our $VERSION = '0.002';

use Moo;
use HTTP::Request;
use URI;
use namespace::clean;


our $BASE_URL = 'https://metaforge.app/api/arc-raiders';
our $MAP_DATA_URL = 'https://metaforge.app/api/game-map-data';

has base_url => (
  is      => 'ro',
  default => sub { $BASE_URL },
);


has map_data_url => (
  is      => 'ro',
  default => sub { $MAP_DATA_URL },
);


sub _build_request {
  my ($self, $url, %params) = @_;
  my $uri = URI->new($url);
  $uri->query_form(%params) if %params;
  return HTTP::Request->new(GET => $uri->as_string);
}

sub items {
  my ($self, %params) = @_;
  return $self->_build_request($self->base_url . '/items', %params);
}


sub arcs {
  my ($self, %params) = @_;
  return $self->_build_request($self->base_url . '/arcs', %params);
}


sub quests {
  my ($self, %params) = @_;
  return $self->_build_request($self->base_url . '/quests', %params);
}


sub traders {
  my ($self, %params) = @_;
  return $self->_build_request($self->base_url . '/traders', %params);
}


sub event_timers {
  my ($self, %params) = @_;
  return $self->_build_request($self->base_url . '/events-schedule', %params);
}


sub map_data {
  my ($self, %params) = @_;
  return $self->_build_request($self->map_data_url, %params);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Request - HTTP Request factory for MetaForge ARC Raiders API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::MetaForge::ArcRaiders::Request;

    my $factory = WWW::MetaForge::ArcRaiders::Request->new;

    # Get HTTP::Request objects for async usage
    my $req = $factory->items(search => 'Ferro');
    my $req = $factory->event_timers(map => 'Dam');

=head1 DESCRIPTION

Factory for creating L<HTTP::Request> objects for the MetaForge API.
Use standalone for integration with async HTTP frameworks like L<WWW::Chain>.

=head2 base_url

Base URL for main API endpoints. Defaults to C<https://metaforge.app/api/arc-raiders>.

=head2 map_data_url

Base URL for map data endpoint. Defaults to C<https://metaforge.app/api/game-map-data>.

=head2 items

    my $req = $factory->items(search => 'Ferro', page => 1);

Returns L<HTTP::Request> for C</items> endpoint.

=head2 arcs

    my $req = $factory->arcs(includeLoot => 'true');

Returns L<HTTP::Request> for C</arcs> endpoint.

=head2 quests

    my $req = $factory->quests(type => 'StoryQuest');

Returns L<HTTP::Request> for C</quests> endpoint.

=head2 traders

    my $req = $factory->traders;

Returns L<HTTP::Request> for C</traders> endpoint.

=head2 event_timers

    my $req = $factory->event_timers(map => 'Dam');

Returns L<HTTP::Request> for C</events-schedule> endpoint.

=head2 map_data

    my $req = $factory->map_data(map => 'Spaceport');

Returns L<HTTP::Request> for C</game-map-data> endpoint.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-metaforge/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
