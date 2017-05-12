package WebService::Recruit::AbRoad::Hotel;

use strict;
use base qw( WebService::Recruit::AbRoad::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/ab-road/hotel/v1/'; }

sub query_class { 'WebService::Recruit::AbRoad::Hotel::Query'; }

sub query_fields { [
    'key', 'area', 'country', 'city', 'hotel', 'keyword', 'in_use', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::AbRoad::Hotel::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'area' => ['code', 'name'],
    'city' => ['code', 'name', 'name_en', 'area', 'country'],
    'country' => ['code', 'name', 'name_en'],
    'error' => ['message'],
    'hotel' => ['code', 'name', 'name_en', 'tour_count', 'city'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'hotel', 'api_version', 'error'],

}; }

sub force_array { [
    'hotel'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::AbRoad::Hotel::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::AbRoad::Hotel::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::AbRoad::Hotel::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::AbRoad::Hotel::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::AbRoad::Hotel::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::AbRoad::Hotel - AB-ROAD Web Service "hotel" API

=head1 SYNOPSIS

    use WebService::Recruit::AbRoad;
    
    my $service = WebService::Recruit::AbRoad->new();
    
    my $param = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->hotel( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "hotel: $data->hotel\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<hotel> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'area' => 'EUR',
        'country' => 'BE',
        'city' => 'NYC',
        'hotel' => '73393',
        'keyword' => 'グランド',
        'in_use' => 'XXXXXXXX',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->hotel( %$param );

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
    $root->hotel
    $root->hotel->[0]->code
    $root->hotel->[0]->name
    $root->hotel->[0]->name_en
    $root->hotel->[0]->tour_count
    $root->hotel->[0]->city
    $root->hotel->[0]->city->code
    $root->hotel->[0]->city->name
    $root->hotel->[0]->city->name_en
    $root->hotel->[0]->city->area
    $root->hotel->[0]->city->country
    $root->hotel->[0]->city->area->code
    $root->hotel->[0]->city->area->name
    $root->hotel->[0]->city->country->code
    $root->hotel->[0]->city->country->name
    $root->hotel->[0]->city->country->name_en


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
