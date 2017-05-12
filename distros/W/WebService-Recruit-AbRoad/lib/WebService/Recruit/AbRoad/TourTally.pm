package WebService::Recruit::AbRoad::TourTally;

use strict;
use base qw( WebService::Recruit::AbRoad::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/ab-road/tour_tally/v1/'; }

sub query_class { 'WebService::Recruit::AbRoad::TourTally::Query'; }

sub query_fields { [
    'key', 'keyword', 'dept', 'ym', 'ymd', 'price_min', 'price_max', 'term_min', 'term_max', 'airline', 'kodaw', 'axis', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key', 'keyword'
]; }

sub elem_class { 'WebService::Recruit::AbRoad::TourTally::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'area' => ['code', 'name'],
    'country' => ['code', 'name'],
    'error' => ['message'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'tour_tally', 'api_version', 'error'],
    'tour_tally' => ['type', 'code', 'name', 'tour_count', 'lat', 'lng', 'area', 'country'],

}; }

sub force_array { [
    'tour_tally'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::AbRoad::TourTally::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::AbRoad::TourTally::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::AbRoad::TourTally::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::AbRoad::TourTally::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::AbRoad::TourTally::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::AbRoad::TourTally - AB-ROAD Web Service "tour_tally" API

=head1 SYNOPSIS

    use WebService::Recruit::AbRoad;
    
    my $service = WebService::Recruit::AbRoad->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '登山',
    };
    my $res = $service->tour_tally( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "tour_tally: $data->tour_tally\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<tour_tally> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'keyword' => '登山',
        'dept' => 'XXXXXXXX',
        'ym' => 'XXXXXXXX',
        'ymd' => 'XXXXXXXX',
        'price_min' => 'XXXXXXXX',
        'price_max' => 'XXXXXXXX',
        'term_min' => 'XXXXXXXX',
        'term_max' => 'XXXXXXXX',
        'airline' => 'XXXXXXXX',
        'kodaw' => 'XXXXXXXX',
        'axis' => 'XXXXXXXX',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->tour_tally( %$param );

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
    $root->tour_tally
    $root->tour_tally->[0]->type
    $root->tour_tally->[0]->code
    $root->tour_tally->[0]->name
    $root->tour_tally->[0]->tour_count
    $root->tour_tally->[0]->lat
    $root->tour_tally->[0]->lng
    $root->tour_tally->[0]->area
    $root->tour_tally->[0]->country
    $root->tour_tally->[0]->area->code
    $root->tour_tally->[0]->area->name
    $root->tour_tally->[0]->country->code
    $root->tour_tally->[0]->country->name


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
