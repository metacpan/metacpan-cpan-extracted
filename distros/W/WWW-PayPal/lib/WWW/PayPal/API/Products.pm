package WWW::PayPal::API::Products;

# ABSTRACT: PayPal Catalogs Products API (v1)

use Moo;
use Carp qw(croak);
use WWW::PayPal::Product;
use namespace::clean;

our $VERSION = '0.002';


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'catalogs.products.create' => { method => 'POST',  path => '/v1/catalogs/products' },
            'catalogs.products.list'   => { method => 'GET',   path => '/v1/catalogs/products' },
            'catalogs.products.get'    => { method => 'GET',   path => '/v1/catalogs/products/{id}' },
            'catalogs.products.patch'  => { method => 'PATCH', path => '/v1/catalogs/products/{id}' },
        };
    },
);

with 'WWW::PayPal::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::PayPal::Product->new(client => $self->client, data => $data);
}

sub create {
    my ($self, %args) = @_;
    croak 'name required' unless $args{name};
    croak 'type required' unless $args{type};

    my %body = (
        name => $args{name},
        type => $args{type},
    );
    for my $k (qw(description category image_url home_url id)) {
        $body{$k} = $args{$k} if defined $args{$k};
    }
    my $data = $self->call_operation('catalogs.products.create', body => \%body);
    return $self->_wrap($data);
}


sub get {
    my ($self, $id) = @_;
    croak 'product id required' unless $id;
    return $self->_wrap($self->call_operation('catalogs.products.get', path => { id => $id }));
}


sub list {
    my ($self, %args) = @_;
    my %query;
    for my $k (qw(page_size page total_required)) {
        $query{$k} = $args{$k} if defined $args{$k};
    }
    my $data = $self->call_operation('catalogs.products.list',
        (%query ? (query => \%query) : ()));
    return [ map { $self->_wrap($_) } @{ $data->{products} || [] } ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Products - PayPal Catalogs Products API (v1)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $product = $pp->products->create(
        name        => 'Monthly VIP membership',
        type        => 'SERVICE',     # or 'PHYSICAL' / 'DIGITAL'
        category    => 'SOFTWARE',    # optional
        description => 'Unlocks the VIP area',
    );

    my $same = $pp->products->get($product->id);

=head1 DESCRIPTION

Controller for PayPal's Catalogs Products API. A product is the abstract
thing you sell; plans and subscriptions reference it by ID. Typically you
create a product once at setup time and reuse it.

=head2 create

    my $product = $pp->products->create(
        name => 'Foo', type => 'SERVICE', category => 'SOFTWARE',
    );

Creates a product. C<type> is one of C<PHYSICAL>, C<DIGITAL>, C<SERVICE>.

=head2 get

    my $product = $pp->products->get($id);

=head2 list

    my $products = $pp->products->list(page_size => 20);

Returns an ArrayRef of L<WWW::PayPal::Product>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-paypal/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
