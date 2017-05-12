package WWW::Jirafe;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use LWP::UserAgent;
use JSON;
use Carp 'croak';
use URI::Escape qw/uri_escape/;
use HTTP::Request;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{site_id} or croak "site_id is required.";
    $args{access_token} or croak "access_token is required.";

    $args{ua} ||= LWP::UserAgent->new();
    $args{json} ||= JSON->new->allow_nonref->utf8;

    $args{API_BASE} ||= 'https://event.jirafe.com/v2/';

    bless \%args, $class;
}

sub batch {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/batch', $params);
}

sub cart {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/cart', $params);
}

sub category {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/category', $params);
}

sub customer {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/customer', $params);
}

sub employee {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/employee', $params);
}

sub order {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/order', $params);
}

sub product {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/product', $params);
}

sub cost {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/product.cost', $params);
}

sub inventory {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/inventory', $params);
}

sub heartbeat {
    my ($self, $params) = @_;
    return $self->request('POST', $self->{site_id} . '/heartbeat', $params);
}

sub request {
    my ($self, $method, $url, $params) = @_;

    my $req = HTTP::Request->new($method => $self->{API_BASE} . $url);
    $req->header('Authorization', 'Bearer ' . $self->{access_token});
    $req->header('Accept', 'application/json'); # JSON is better
    if ($params) {
        $req->content($self->{json}->encode($params));
    }
    my $res = $self->{ua}->request($req);
    if ($res->header('Content-Type') =~ m{application/json}) {
        return $self->{json}->decode($res->decoded_content);
    }
    # use Data::Dumper; print STDERR Dumper(\$res);
    return { error => $res->status_line };
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Jirafe - Jirafe API

=head1 SYNOPSIS

    use WWW::Jirafe;

    my $jirafe = WWW::Jirafe->new(
        site_id => 123,
        access_token => 'token_from_https://account.jirafe.com/accounts/settings/site/123/tokens/',
    );

    my $params = decode_json('{
        "id": "1234abc",
        "active_flag": true,
        "change_date": "2013-06-17T15:15:53.000Z",
        "create_date": "2013-06-17T15:15:53.000Z",
        "email": "john.doe@gmail.com",
        "first_name": "John",
        "last_name": "Doe",
        "name": "John Doe"
    }');
    my $res = $jirafe->customer($params);

=head1 DESCRIPTION

WWW::Jirafe is

=head2 METHODS

=head3 batch

L<http://docs.jirafe.com/api/batch_endpoint/>

=head3 cart

L<http://docs.jirafe.com/api/cart_endpoint/>

    my $params = decode_json('{
        "id": "8797436543019",
        "create_date": "2013-06-17T15:16:10.000Z",
        "change_date": "2013-06-17T15:16:15.000Z",
        "subtotal": 99.85,
        "total": 99.85,
        "total_tax": 4.75,
        "total_shipping": 0.0,
        "total_payment_cost": 0.0,
        "total_discounts": 0.0,
        "currency": "USD",
        "cookies": {},
        "items": [
            {
                "id": "8797371007020",
                "create_date": "2013-06-17T15:16:11.000Z",
                "change_date": "2013-06-17T15:16:11.000Z",
                "cart_item_number": "1",
                "quantity": 1,
                "price": 99.85,
                "discount_price": 0.0,
                "product": {
                    "id": "8796107014145",
                    "create_date": "2013-03-28T19:46:39.000Z",
                    "change_date": "2013-03-28T19:50:58.000Z",
                    "is_product": true,
                    "is_sku": true,
                    "catalog": {
                        "id": "electronicsProductCatalog",
                        "name": "Electronics Product Catalog"
                    },
                    "name": "PowerShot A480",
                    "code": "1934793",
                    "brand": "Canon",
                    "categories": [
                        {
                            "id": "8796098461838",
                            "name": "Digital Compacts"
                        },
                        {
                            "id": "8796099248270",
                            "name": "Canon"
                        }
                    ],
                    "images": [
                        {
                            "url": "http://yourstore.com/images/the_photo.jpg"
                        }
                    ]
                }
            }
        ],
        "previous_items": [
        ],
        "customer": {
            "id": "abc123",
            "create_date": "2013-06-17T15:16:11.000Z",
            "change_date": "2013-06-17T15:16:11.000Z",
            "email": "foo@example.com",
            "first_name": "Jane",
            "last_name": "Doe"
        },
        "visit": {
            "visit_id": "1234",
            "visitor_id": "4321",
            "pageview_id": "5678",
            "last_pageview_id": "8765"
        }
    }');

    my $res = $jirafe->cart($params);

=head3 category

L<http://docs.jirafe.com/api/category_endpoint/>

=head3 customer

L<http://docs.jirafe.com/api/customer_endpoint/>

    my $params = decode_json('{
        "id": "1234abc",
        "active_flag": true,
        "change_date": "2013-06-17T15:15:53.000Z",
        "create_date": "2013-06-17T15:15:53.000Z",
        "email": "john.doe@gmail.com",
        "first_name": "John",
        "last_name": "Doe",
        "name": "John Doe"
    }');

    my $res = $jirafe->customer($params);

=head3 employee

L<http://docs.jirafe.com/api/employee_endpoint/>

=head3 order

L<http://docs.jirafe.com/api/order_endpoint/>

    my $params = decode_json('{
        "order_number": "123456789",
        "cart_id": "123456789",
        "status": "placed",
        "order_date": "2013-06-17T15:16:10.000Z",
        "customer": {
            "id": "abc123",
            "create_date": "2013-06-17T15:16:11.000Z",
            "change_date": "2013-06-17T15:16:11.000Z",
            "email": "foo@example.com",
            "first_name": "Jane",
            "last_name": "Doe"
        },
        "visit": {
            "visit_id": "1234",
            "visitor_id": "4321",
            "pageview_id": "5678",
            "last_pageview_id": "8765"
        }
    }');

    my $res = $jirafe->order($params);

=head3 product

L<http://docs.jirafe.com/api/product_endpoint/>

    my $params = decode_json('{
        "id": "8796107014145",
        "create_date": "2013-03-28T19:46:39.000Z",
        "change_date": "2013-03-28T19:50:58.000Z",
        "is_product": true,
        "is_sku": true,
        "catalog": {
            "id": "electronicsProductCatalog",
            "name": "Electronics Product Catalog"
        },
        "name": "PowerShot A480",
        "code": "1934793",
        "brand": "Canon",
        "categories": [
            {
                "id": "8796098461838",
                "name": "Digital Compacts"
            },
            {
                "id": "8796099248270",
                "name": "Canon"
            }
        ],
        "images": [
            {
                "url": "http://yourstore.com/images/the_photo.jpg"
            }
        ]
    }');

    my $res = $jirafe->product($params);

=head3 cost

L<http://docs.jirafe.com/api/cost_endpoint/>

=head3 inventory

L<http://docs.jirafe.com/api/inventory_endpoint/>

=head3 heartbeat

L<http://docs.jirafe.com/api/heartbeat_endpoint/>

=head1 AUTHOR

Fayland Lam E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
