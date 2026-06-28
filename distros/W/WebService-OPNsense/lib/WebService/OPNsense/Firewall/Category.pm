#!/bin/false
# ABSTRACT: Firewall category controller
# PODNAME: WebService::OPNsense::Firewall::Category
use strictures 2;

package WebService::OPNsense::Firewall::Category;
$WebService::OPNsense::Firewall::Category::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/category';
}

with 'WebService::OPNsense::Role::ItemCrud';

sub set_category {
    my ( $self, $category_data ) = @_;
    my $uri = $self->_path('set');

    return $self->client->post( $uri, $category_data );
}

sub download {
    my ($self) = @_;
    my $uri = $self->_path('download');

    return $self->client->get($uri);
}

sub upload {
    my ( $self, $upload_data ) = @_;
    my $uri = $self->_path('upload');

    return $self->client->post( $uri, $upload_data );
}

sub get {
    my ($self) = @_;
    my $uri = $self->_path('get');

    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Category - Firewall category controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $category = $opn->firewall->category;

    my $results = $category->search_item;
    my $item    = $category->get_item($uuid);

=head1 DESCRIPTION

Manages firewall category items. Categories group firewall rules for
organizational purposes.

=head1 METHODS

=head2 set_category

    my $result = $category->set_category($category_data);

Sets global category settings.

=head2 download

    my $data = $category->download;

Downloads all category configuration.

=head2 upload

    my $result = $category->upload($upload_data);

Uploads category configuration.

=head2 get

    my $categories = $category->get;

Returns all category configuration.

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_item

    my $results = $ctrl->search_item( %params );

Searches for categories.

=head2 get_item

    my $category = $ctrl->get_item( $uuid );

Returns a single category by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_item

    my $result = $ctrl->add_item( $category_data );

Creates category.

=head2 set_item

    my $result = $ctrl->set_item( $uuid, $category_data );

Updates category.  Throws if C<$uuid> is not a valid UUID.

=head2 del_item

    my $result = $ctrl->del_item( $uuid );

Deletes a category by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Firewall::Filter>,
L<WebService::OPNsense::Firewall::Alias>,
L<WebService::OPNsense::Firewall::DNat>,
L<WebService::OPNsense::Firewall::OneToOne>,
L<WebService::OPNsense::Firewall::SourceNat>,
L<WebService::OPNsense::Firewall::Npt>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
