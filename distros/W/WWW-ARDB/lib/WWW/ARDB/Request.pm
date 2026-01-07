package WWW::ARDB::Request;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: HTTP request factory for WWW::ARDB

use Moo;
use HTTP::Request;
use URI;
use namespace::clean;

our $VERSION = '0.001';

use constant BASE_URL => 'https://ardb.app/api';

sub items {
    my ($self, %params) = @_;
    return $self->_build_request('items', %params);
}

sub item {
    my ($self, $id, %params) = @_;
    return $self->_build_request("items/$id", %params);
}

sub quests {
    my ($self, %params) = @_;
    return $self->_build_request('quests', %params);
}

sub quest {
    my ($self, $id, %params) = @_;
    return $self->_build_request("quests/$id", %params);
}

sub arc_enemies {
    my ($self, %params) = @_;
    return $self->_build_request('arc-enemies', %params);
}

sub arc_enemy {
    my ($self, $id, %params) = @_;
    return $self->_build_request("arc-enemies/$id", %params);
}

sub _build_request {
    my ($self, $endpoint, %params) = @_;

    my $uri = URI->new(BASE_URL . '/' . $endpoint);
    $uri->query_form(%params) if %params;

    return HTTP::Request->new(
        GET => $uri->as_string,
        [
            'Accept' => 'application/json',
        ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::Request - HTTP request factory for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::ARDB::Request;

    my $request = WWW::ARDB::Request->new;

    # Get HTTP::Request objects for each endpoint
    my $http_request = $request->items;
    my $http_request = $request->item('acoustic_guitar');
    my $http_request = $request->quests;
    my $http_request = $request->quest('picking_up_the_pieces');
    my $http_request = $request->arc_enemies;
    my $http_request = $request->arc_enemy('wasp');

=head1 DESCRIPTION

This module creates L<HTTP::Request> objects for the ardb.app API endpoints.
It can be used standalone for async HTTP clients like L<WWW::Chain>.

=head1 NAME

WWW::ARDB::Request - HTTP request factory for WWW::ARDB

=head1 METHODS

=head2 items

Returns an HTTP::Request for GET /items.

=head2 item($id)

Returns an HTTP::Request for GET /items/{id}.

=head2 quests

Returns an HTTP::Request for GET /quests.

=head2 quest($id)

Returns an HTTP::Request for GET /quests/{id}.

=head2 arc_enemies

Returns an HTTP::Request for GET /arc-enemies.

=head2 arc_enemy($id)

Returns an HTTP::Request for GET /arc-enemies/{id}.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-ardb>

  git clone https://github.com/Getty/p5-www-ardb.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
