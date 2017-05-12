package WebService::Zoopla::API;
use Moose;
use Net::HTTP::Spore;
our $AUTOLOAD;
our $VERSION = '0.001';
use List::Util qw(first);

# ABSTRACT: Perl interface to the Zoopla API

has api_key => (is => 'ro', isa => 'Str', required => 1);
has specification => (
    is      => 'ro',
    isa     => 'Str',
    default => '{
                        "name" : "Zoopla",
                        "meta" : {
                            "documentation" : "http://developer.zoopla.com/docs"
                        },
                        "base_url" : "http://api.zoopla.co.uk/api/v1",
                        "version" : "1",
                        "methods" : {
                            "zed_index" : {
                                "required_params" : [
                                    "api_key",
                                    "output_type"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude"
                                ],
                                "path" : "/zed_index.js",
                                "method" : "GET"
                            },
                            "area_value_graphs" : {
                                "required_params" : [
                                    "api_key"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "size",
                                    "output_type"
                                ],
                                "path":"/area_value_graphs.js",
                                "method" : "GET"
                            },
                            "richlist" : {
                                "required_params" : [
                                    "api_key",
                                    "output_type",
                                    "area_type"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude"
                                ],
                                "path":"/richlist.js",
                                "method" : "GET"
                            },
                            "average_area_sold_price" : {
                                "required_params" : [
                                    "api_key",
                                    "output_type"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude"
                                ],
                                "path":"/average_area_sold_price.js",
                                "method" : "GET"
                            },
                            "zed_indices" : {
                                "required_params" : [
                                    "api_key",
                                    "output_type",
                                    "area_type"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "ordering",
                                    "page_number",
                                    "page_size"
                                ],
                                "path":"/zed_indices.js",
                                "method" : "GET"
                            },
                            "zoopla_estimates" : {
                                "required_params" : [
                                    "api_key"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "property_id",
                                    "order_by",
                                    "ordering",
                                    "page_number",
                                    "page_size",
                                    "output_type"
                                ],
                                "path":"/zoopla_estimates.js",
                                "method" : "GET"
                            },
                            "property_listings" : {
                                "required_params" : [
                                    "api_key"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "property_type",
                                    "radius",
                                    "order_by",
                                    "ordering",
                                    "page_number",
                                    "page_size",
                                    "output_type",
                                    "listing_status",
                                    "include_sold",
                                    "include_rented",
                                    "minimum_price",
                                    "maximum_price",
                                    "minimum_beds",
                                    "maximum_beds",
                                    "furnished",
                                    "keywords",
                                    "listing_id"
                                ],
                                "path":"/property_listings.js",
                                "method" : "GET"
                            },
                            "get_session_id" : {
                                "required_params" : [
                                    "api_key"
                                ],
                                "path":"/get_session_id.js",
                                "method" : "GET"
                            },
                            "refine_estimate" : {
                                "required_params" : [
                                    "api_key",
                                    "property_id",
                                    "property_type",
                                    "tenure",
                                    "num_bedrooms",
                                    "num_bathrooms",
                                    "num_receptions",
                                    "session_id"
                                ],
                                "optional_params" : [
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "output_type"
                                ],
                                "path":"/refine_estimate.js",
                                "method" : "GET"
                            },
                            "arrange_viewing" : {
                                "required_params" : [
                                    "api_key",
                                    "listing_id",
                                    "name",
                                    "email",
                                    "phone",
                                    "phone_type",
                                    "best_time_to_call",
                                    "message",
                                    "session_id"
                                ],
                                "path":"/arrange_viewing.js",
                                "method" : "GET"
                            },
                            "average_sold_prices" : {
                                "required_params" : [
                                    "api_key"
                                ],
                                "optional_params" : [
                                    "session_id",
                                    "area",
                                    "street",
                                    "town",
                                    "postcode",
                                    "county",
                                    "latitude",
                                    "longitude",
                                    "area_type",
                                    "page_number",
                                    "page_size",
                                    "ordering",
                                    "output_type"
                                ],
                                "path":"/zoopla_estimates.js",
                                "method" : "GET"
                            }
                        },
                        "formats" : [
                            "json",
                            "xml"
                        ]
                     }'
);

has api => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Object',
    default => sub {
        my $self = shift;
        Net::HTTP::Spore->new_from_strings($self->specification)
          ->enable('Format::JSON')->enable('Runtime');
    }
);

has session_id => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Str',
    default => sub {
        my $self = shift;
        $self->_call('get_session_id', @_)->{'session_id'};
    }
);

__PACKAGE__->meta->make_immutable;

sub _call {
    my $self   = shift;
    my $method = shift;
    my $attrs  = shift;
    $attrs->{api_key}    = $self->api_key;
    $attrs->{format}     = 'json';
    $attrs->{session_id} = $self->session_id
      if ($self->_need_session($method));
    return $self->api->$method(%{$attrs})->body;
}

sub _need_session {
    my $self   = shift;
    my $method = shift;
    return first { $_ eq 'session_id' } (
        @{  $self->api->meta->{methods}->{$method}
              ->get_original_method->meta->{optional_params}
          },
        @{  $self->api->meta->{methods}->{$method}
              ->get_original_method->meta->{required_params}
          }
    );
}

sub AUTOLOAD {
    my $self = shift;
    ref($self) || die "$self is not an object";
    my $method = $AUTOLOAD;
    $method =~ s/.*://;
    die "Can't call $method()"
      unless grep { $_ eq $method } @{$self->api->meta->local_spore_methods};
    return $self->_call($method, @_);
}

1;


=pod

=head1 NAME

WebService::Zoopla::API - Perl interface to the Zoopla API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

use WebService::Zoopla::API;

my $zoopla = WebService::Zoopla::API->new(
            api_key         => 'xxxxxx');

my $result = $zoopla->zed_index({area=>'SE4', output_type=>"outcode"});

=head1 Constructor

=head2 new()

Creates and returns a new WebService::Zoopla::API object

    my $zoopla = WebService::Zoopla::API->new(
                api_key         => 'xxxxxx');

=over 4

=item * C<< api_key => 'xxxxx' >>

Set the api key. This can be set up at:
http://developer.zoopla.com

=back

=head1 METHODS

=head2 arrange_viewing

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< listing_id >>

=item * C<< name >>

=item * C<< email >>

=item * C<< phone >>

=item * C<< phone_type >>

=item * C<< best_time_to_call >>

=item * C<< message >>

=item * C<< session_id >>

=back

=back

=head2 average_area_sold_price

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< output_type >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=back

=back

=head2 richlist

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< output_type >>

=item * C<< area_type >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=back

=back

=head2 property_listings

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< property_type >>

=item * C<< radius >>

=item * C<< order_by >>

=item * C<< ordering >>

=item * C<< page_number >>

=item * C<< page_size >>

=item * C<< output_type >>

=item * C<< listing_status >>

=item * C<< include_sold >>

=item * C<< include_rented >>

=item * C<< minimum_price >>

=item * C<< maximum_price >>

=item * C<< minimum_beds >>

=item * C<< maximum_beds >>

=item * C<< furnished >>

=item * C<< keywords >>

=item * C<< listing_id >>

=back

=back

=head2 area_value_graphs

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< size >>

=item * C<< output_type >>

=back

=back

=head2 zed_index

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< output_type >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=back

=back

=head2 get_session_id

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=back

=back

=head2 zoopla_estimates

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< property_id >>

=item * C<< order_by >>

=item * C<< ordering >>

=item * C<< page_number >>

=item * C<< page_size >>

=item * C<< output_type >>

=back

=back

=head2 average_sold_prices

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< area_type >>

=item * C<< page_number >>

=item * C<< page_size >>

=item * C<< ordering >>

=item * C<< output_type >>

=back

=back

=head2 refine_estimate

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< property_id >>

=item * C<< property_type >>

=item * C<< tenure >>

=item * C<< num_bedrooms >>

=item * C<< num_bathrooms >>

=item * C<< num_receptions >>

=item * C<< session_id >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< output_type >>

=back

=back

=head2 zed_indices

=over 4

Required Parameters

=over 4

=item * C<< api_key >>

=item * C<< output_type >>

=item * C<< area_type >>

=back

=back

=over 4

Optional Parameters

=over 4

=item * C<< session_id >>

=item * C<< area >>

=item * C<< street >>

=item * C<< town >>

=item * C<< postcode >>

=item * C<< county >>

=item * C<< latitude >>

=item * C<< longitude >>

=item * C<< ordering >>

=item * C<< page_number >>

=item * C<< page_size >>

=back

=back

=head1 SEE ALSO

L<Net::HTTP::Spore>

=head1 INTERNAL METHODS

=head2 _call($args)

General method for calling the methods on the api
You don't need to call this directly

=head2 _need_session($method)

Internal method to check if a method needs a session id

=head1 AUTHOR

Willem Basson <willem.basson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Willem Basson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
