package WebService::Recruit::AbRoad::Spot;

use strict;
use base qw( WebService::Recruit::AbRoad::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/ab-road/spot/v1/'; }

sub query_class { 'WebService::Recruit::AbRoad::Spot::Query'; }

sub query_fields { [
    'key', 'spot', 'area', 'country', 'city', 'keyword', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::AbRoad::Spot::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'area' => ['code', 'name'],
    'city' => ['code', 'name'],
    'country' => ['code', 'name'],
    'error' => ['message'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'spot', 'api_version', 'error'],
    'spot' => ['code', 'name', 'name_en', 'title', 'description', 'lat', 'lng', 'map_scale', 'area', 'country', 'city', 'url'],

}; }

sub force_array { [
    'spot'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::AbRoad::Spot::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::AbRoad::Spot::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::AbRoad::Spot::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::AbRoad::Spot::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::AbRoad::Spot::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::AbRoad::Spot - AB-ROAD Web Service "spot" API

=head1 SYNOPSIS

    use WebService::Recruit::AbRoad;
    
    my $service = WebService::Recruit::AbRoad->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->spot( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "spot: $data->spot\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<spot> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'spot' => 'XXXXXXXX',
        'area' => 'EUR',
        'country' => 'BE',
        'city' => 'NYC',
        'keyword' => '教会',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->spot( %$param );

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
    $root->spot
    $root->spot->[0]->code
    $root->spot->[0]->name
    $root->spot->[0]->name_en
    $root->spot->[0]->title
    $root->spot->[0]->description
    $root->spot->[0]->lat
    $root->spot->[0]->lng
    $root->spot->[0]->map_scale
    $root->spot->[0]->area
    $root->spot->[0]->country
    $root->spot->[0]->city
    $root->spot->[0]->url
    $root->spot->[0]->area->code
    $root->spot->[0]->area->name
    $root->spot->[0]->country->code
    $root->spot->[0]->country->name
    $root->spot->[0]->city->code
    $root->spot->[0]->city->name


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
