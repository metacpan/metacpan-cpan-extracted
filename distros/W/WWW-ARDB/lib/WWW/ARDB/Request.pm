package WWW::ARDB::Request;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: HTTP request factory for WWW::ARDB

use Moo;
use HTTP::Request;
use URI;
use namespace::clean;

our $VERSION = '0.002';

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

version 0.002

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

The base URL is C<https://ardb.app/api>.

=head2 items

    my $request = $factory->items;

Returns an L<HTTP::Request> for C<GET /items>.

=head2 item

    my $request = $factory->item('acoustic_guitar');

Returns an L<HTTP::Request> for C<GET /items/{id}>.

=head2 quests

    my $request = $factory->quests;

Returns an L<HTTP::Request> for C<GET /quests>.

=head2 quest

    my $request = $factory->quest('picking_up_the_pieces');

Returns an L<HTTP::Request> for C<GET /quests/{id}>.

=head2 arc_enemies

    my $request = $factory->arc_enemies;

Returns an L<HTTP::Request> for C<GET /arc-enemies>.

=head2 arc_enemy

    my $request = $factory->arc_enemy('wasp');

Returns an L<HTTP::Request> for C<GET /arc-enemies/{id}>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-ardb/issues>.

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
