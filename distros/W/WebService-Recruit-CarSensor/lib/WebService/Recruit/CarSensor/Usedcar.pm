package WebService::Recruit::CarSensor::Usedcar;

use strict;
use base qw( WebService::Recruit::CarSensor::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.2';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/carsensor/usedcar/v1/'; }

sub query_class { 'WebService::Recruit::CarSensor::Usedcar::Query'; }

sub query_fields { [
    'key', 'id', 'brand', 'model', 'country', 'large_area', 'pref', 'body', 'person', 'color', 'price_min', 'price_max', 'keyword', 'lat', 'lng', 'range', 'datum', 'mission', 'nonsmoking', 'leather', 'welfare', 'year_old', 'year_new', 'odd_min', 'odd_max', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::CarSensor::Usedcar::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'body' => ['code', 'name'],
    'brand' => ['code', 'name'],
    'error' => ['message'],
    'main' => ['l', 's'],
    'photo' => ['main', 'sub'],
    'pref' => ['code', 'name'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'usedcar', 'api_version', 'error'],
    'shop' => ['name', 'pref', 'lat', 'lng', 'datum'],
    'urls' => ['pc', 'mobile', 'qr'],
    'usedcar' => ['id', 'brand', 'model', 'grade', 'price', 'desc', 'body', 'odd', 'year', 'shop', 'color', 'photo', 'urls'],

}; }

sub force_array { [
    'sub', 'usedcar'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::CarSensor::Usedcar::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::CarSensor::Usedcar::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::CarSensor::Usedcar::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::CarSensor::Usedcar::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::CarSensor::Usedcar::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::CarSensor::Usedcar - CarSensor.net Web Service "usedcar" API

=head1 SYNOPSIS

    use WebService::Recruit::CarSensor;
    
    my $service = WebService::Recruit::CarSensor->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'pref' => '13',
    };
    my $res = $service->usedcar( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "usedcar: $data->usedcar\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<usedcar> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'id' => 'CH9999999999',
        'brand' => 'SB',
        'model' => 'インプレッサ',
        'country' => 'JPN',
        'large_area' => '1',
        'pref' => '13',
        'body' => 'S',
        'person' => '5',
        'color' => 'WT',
        'price_min' => '500000',
        'price_max' => '500000',
        'keyword' => 'XXXXXXXX',
        'lat' => '35.669220',
        'lng' => '139.761457',
        'range' => '100',
        'datum' => 'world',
        'mission' => '1',
        'nonsmoking' => '1',
        'leather' => '1',
        'welfare' => '1',
        'year_old' => '1998',
        'year_new' => '1998',
        'odd_min' => '50000',
        'odd_max' => '50000',
        'order' => '1',
        'start' => '1',
        'count' => '10',
    };
    my $res = $service->usedcar( %$param );

C<$service> above is an instance of L<WebService::Recruit::CarSensor>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->usedcar
    $root->usedcar->[0]->id
    $root->usedcar->[0]->brand
    $root->usedcar->[0]->model
    $root->usedcar->[0]->grade
    $root->usedcar->[0]->price
    $root->usedcar->[0]->desc
    $root->usedcar->[0]->body
    $root->usedcar->[0]->odd
    $root->usedcar->[0]->year
    $root->usedcar->[0]->shop
    $root->usedcar->[0]->color
    $root->usedcar->[0]->photo
    $root->usedcar->[0]->urls
    $root->usedcar->[0]->brand->code
    $root->usedcar->[0]->brand->name
    $root->usedcar->[0]->body->code
    $root->usedcar->[0]->body->name
    $root->usedcar->[0]->shop->name
    $root->usedcar->[0]->shop->pref
    $root->usedcar->[0]->shop->lat
    $root->usedcar->[0]->shop->lng
    $root->usedcar->[0]->shop->datum
    $root->usedcar->[0]->photo->main
    $root->usedcar->[0]->photo->sub
    $root->usedcar->[0]->urls->pc
    $root->usedcar->[0]->urls->mobile
    $root->usedcar->[0]->urls->qr
    $root->usedcar->[0]->shop->pref->code
    $root->usedcar->[0]->shop->pref->name
    $root->usedcar->[0]->photo->main->l
    $root->usedcar->[0]->photo->main->s


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

L<WebService::Recruit::CarSensor>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
