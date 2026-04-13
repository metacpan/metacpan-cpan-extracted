#!/usr/bin/false
# ABSTRACT: Bugzilla Product object and service
# PODNAME: WebService::Bugzilla::Product

package WebService::Bugzilla::Product 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';
with 'WebService::Bugzilla::Role::Updatable';

sub _unwrap_key { 'products' }

has classification     => (is => 'ro', lazy => 1, builder => '_build_classification');
has components         => (is => 'ro', lazy => 1, builder => '_build_components');
has default_milestone  => (is => 'ro', lazy => 1, builder => '_build_default_milestone');
has description        => (is => 'ro', lazy => 1, builder => '_build_description');
has has_unconfirmed    => (is => 'ro', lazy => 1, builder => '_build_has_unconfirmed');
has is_active          => (is => 'ro', lazy => 1, builder => '_build_is_active');
has milestones         => (is => 'ro', lazy => 1, builder => '_build_milestones');
has name               => (is => 'ro', lazy => 1, builder => '_build_name');
has requires_component => (is => 'ro', lazy => 1, builder => '_build_requires_component');
has versions           => (is => 'ro', lazy => 1, builder => '_build_versions');

my @attrs = qw(
    classification
    components
    default_milestone
    description
    has_unconfirmed
    is_active
    milestones
    name
    requires_component
    versions
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            my $id_or_name = $self->_api_data->{name} // $self->id;
            $self->_fetch_full($self->_mkuri("product/$id_or_name"));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('product'), \%params);
    return $self->new(
        client => $self->client,
        _data  => { %params, id => $res->{id} },
    );
}

sub get {
    my ($self, $id_or_name) = @_;
    my $res = $self->client->get($self->_mkuri("product/$id_or_name"));
    return unless $res->{products} && @{ $res->{products} };
    return $self->new(
        client => $self->client,
        _data  => $res->{products}[0],
    );
}

sub search {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('product'), \%params);
    return [
        map {
            $self->new(
                client => $self->client,
                _data  => $_
            )
        }
        @{ $res->{products} // [] }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Product - Bugzilla Product object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $product = $bz->product->get('Firefox');
    say $product->name, ': ', $product->description;

    my $products = $bz->product->search(is_active => 1);

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Product API|https://bmo.readthedocs.io/en/latest/api/core/v1/product.html>.
Product objects represent Bugzilla products and expose attributes about the
product plus helpers to create, fetch, search, and update products.

=head1 ATTRIBUTES

All attributes are read-only and lazy.

=over 4

=item C<classification>

Classification name or object the product belongs to.

=item C<components>

Arrayref of component data hashes.

=item C<default_milestone>

Default milestone string for new bugs.

=item C<description>

Human-readable product description.

=item C<has_unconfirmed>

Boolean.  Whether the product accepts the UNCONFIRMED status.

=item C<is_active>

Boolean.  Whether the product is active.

=item C<milestones>

Arrayref of milestone data hashes.

=item C<name>

Product name.

=item C<requires_component>

Boolean.  Whether a component is required when filing bugs.

=item C<versions>

Arrayref of version data hashes.

=back

=head1 METHODS

=head2 create

    my $product = $bz->product->create(%params);

Create a new product.
See L<POST /rest/product|https://bmo.readthedocs.io/en/latest/api/core/v1/product.html#create-product>.

=head2 get

    my $product = $bz->product->get($id_or_name);

Fetch a product by numeric ID or name.
See L<GET /rest/product/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/product.html#get-product>.

Returns a L<WebService::Bugzilla::Product>, or C<undef> if not found.

=head2 search

    my $products = $bz->product->search(%params);

Search for products.
See L<GET /rest/product|https://bmo.readthedocs.io/en/latest/api/core/v1/product.html#list-products>.

Returns an arrayref of L<WebService::Bugzilla::Product> objects.

=head2 update

    my $updated = $product->update(%params);
    my $updated = $bz->product->update($id, %params);

Update an existing product.
See L<PUT /rest/product/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/product.html#update-product>.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Component> - component objects

L<WebService::Bugzilla::Classification> - classification objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/product.html> - Bugzilla Product REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
