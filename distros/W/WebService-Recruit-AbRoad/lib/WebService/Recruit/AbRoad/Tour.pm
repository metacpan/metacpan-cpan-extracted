package WebService::Recruit::AbRoad::Tour;

use strict;
use base qw( WebService::Recruit::AbRoad::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/ab-road/tour/v1/'; }

sub query_class { 'WebService::Recruit::AbRoad::Tour::Query'; }

sub query_fields { [
    'key', 'id', 'area', 'country', 'city', 'hotel', 'keyword', 'dept', 'ym', 'ymd', 'price_min', 'price_max', 'term_min', 'term_max', 'airline', 'kodaw', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::AbRoad::Tour::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'airline' => ['code', 'name'],
    'all_month' => ['min', 'max'],
    'area' => ['code', 'name'],
    'brand' => ['code', 'name'],
    'city' => ['code', 'name', 'code', 'name', 'lat', 'lng', 'area', 'country'],
    'country' => ['code', 'name'],
    'dept_city' => ['name', 'code'],
    'error' => ['message'],
    'hotel' => ['code', 'name', 'city'],
    'kodawari' => ['code', 'name'],
    'price' => ['all_month', 'min', 'max'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'tour', 'api_version', 'error'],
    'sche' => ['day', 'city'],
    'tour' => ['id', 'last_update', 'term', 'title', 'airline', 'airline_summary', 'brand', 'city_summary', 'dept_city', 'hotel', 'hotel_summary', 'kodawari', 'price', 'sche', 'urls'],
    'urls' => ['mobile', 'pc', 'qr'],

}; }

sub force_array { [
    'airline', 'hotel', 'kodawari', 'sche', 'tour'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::AbRoad::Tour::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::AbRoad::Tour::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::AbRoad::Tour::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::AbRoad::Tour::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::AbRoad::Tour::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::AbRoad::Tour - AB-ROAD Web Service "tour" API

=head1 SYNOPSIS

    use WebService::Recruit::AbRoad;
    
    my $service = WebService::Recruit::AbRoad->new();
    
    my $param = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->tour( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "tour: $data->tour\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<tour> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'id' => 'AB123456',
        'area' => 'EUR',
        'country' => 'BE',
        'city' => 'NYC',
        'hotel' => '73393',
        'keyword' => 'ベトナム　癒し',
        'dept' => 'XXXXXXXX',
        'ym' => '0708',
        'ymd' => '070812',
        'price_min' => '30000',
        'price_max' => '100000',
        'term_min' => '3',
        'term_max' => '10',
        'airline' => 'A0',
        'kodaw' => 'XXXXXXXX',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->tour( %$param );

C<$service> above is an instance of L<WebService::Recruit::AbRoad>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->tour
    $root->tour->[0]->id
    $root->tour->[0]->last_update
    $root->tour->[0]->term
    $root->tour->[0]->title
    $root->tour->[0]->airline
    $root->tour->[0]->airline_summary
    $root->tour->[0]->brand
    $root->tour->[0]->city_summary
    $root->tour->[0]->dept_city
    $root->tour->[0]->hotel
    $root->tour->[0]->hotel_summary
    $root->tour->[0]->kodawari
    $root->tour->[0]->price
    $root->tour->[0]->sche
    $root->tour->[0]->urls
    $root->tour->[0]->airline->[0]->code
    $root->tour->[0]->airline->[0]->name
    $root->tour->[0]->brand->code
    $root->tour->[0]->brand->name
    $root->tour->[0]->dept_city->name
    $root->tour->[0]->dept_city->code
    $root->tour->[0]->hotel->[0]->code
    $root->tour->[0]->hotel->[0]->name
    $root->tour->[0]->hotel->[0]->city
    $root->tour->[0]->kodawari->[0]->code
    $root->tour->[0]->kodawari->[0]->name
    $root->tour->[0]->price->all_month
    $root->tour->[0]->price->min
    $root->tour->[0]->price->max
    $root->tour->[0]->sche->[0]->day
    $root->tour->[0]->sche->[0]->city
    $root->tour->[0]->urls->mobile
    $root->tour->[0]->urls->pc
    $root->tour->[0]->urls->qr
    $root->tour->[0]->hotel->[0]->city->code
    $root->tour->[0]->hotel->[0]->city->name
    $root->tour->[0]->price->all_month->min
    $root->tour->[0]->price->all_month->max
    $root->tour->[0]->sche->[0]->city->code
    $root->tour->[0]->sche->[0]->city->name
    $root->tour->[0]->sche->[0]->city->lat
    $root->tour->[0]->sche->[0]->city->lng
    $root->tour->[0]->sche->[0]->city->area
    $root->tour->[0]->sche->[0]->city->country
    $root->tour->[0]->sche->[0]->city->area->code
    $root->tour->[0]->sche->[0]->city->area->name
    $root->tour->[0]->sche->[0]->city->country->code
    $root->tour->[0]->sche->[0]->city->country->name


=head2 xml

This returns the raw response context itself.

    print $res->xml, "\n";

=head2 code

This returns the response status code.

    my $code = $res->code; # usually "200" when succeeded

=head2 is_error

This returns true value when the response has an error.

    die 'error!' if $res->is_error;

=head1 SEE ALSO

L<WebService::Recruit::AbRoad>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
