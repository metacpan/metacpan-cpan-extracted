package WebService::Recruit::CarSensor::Catalog;

use strict;
use base qw( WebService::Recruit::CarSensor::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.2';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/carsensor/catalog/v1/'; }

sub query_class { 'WebService::Recruit::CarSensor::Catalog::Query'; }

sub query_fields { [
    'key', 'brand', 'model', 'country', 'body', 'person', 'year_old', 'year_new', 'welfare', 'series', 'keyword', 'width_max', 'height_max', 'length_max', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::CarSensor::Catalog::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'body' => ['code', 'name'],
    'brand' => ['code', 'name'],
    'catalog' => ['brand', 'model', 'grade', 'price', 'desc', 'body', 'person', 'period', 'series', 'width', 'height', 'length', 'photo', 'urls', 'desc'],
    'error' => ['message'],
    'front' => ['caption', 'l', 's'],
    'inpane' => ['caption', 'l', 's'],
    'photo' => ['front', 'rear', 'inpane'],
    'rear' => ['caption', 'l', 's'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'catalog', 'api_version', 'error'],
    'urls' => ['pc', 'mobile', 'qr'],

}; }

sub force_array { [
    'catalog'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::CarSensor::Catalog::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::CarSensor::Catalog::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::CarSensor::Catalog::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::CarSensor::Catalog::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::CarSensor::Catalog::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::CarSensor::Catalog - CarSensor.net Web Service "catalog" API

=head1 SYNOPSIS

    use WebService::Recruit::CarSensor;
    
    my $service = WebService::Recruit::CarSensor->new();
    
    my $param = {
        'country' => 'JPN',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->catalog( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "catalog: $data->catalog\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<catalog> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'brand' => 'SB',
        'model' => 'インプレッサ',
        'country' => 'JPN',
        'body' => 'S',
        'person' => '5',
        'year_old' => '1998',
        'year_new' => '1998',
        'welfare' => '1',
        'series' => 'GF-GF8',
        'keyword' => 'XXXXXXXX',
        'width_max' => '1700',
        'height_max' => '1500',
        'length_max' => '4500',
        'order' => '1',
        'start' => '1',
        'count' => '30',
    };
    my $res = $service->catalog( %$param );

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
    $root->catalog
    $root->catalog->[0]->brand
    $root->catalog->[0]->model
    $root->catalog->[0]->grade
    $root->catalog->[0]->price
    $root->catalog->[0]->desc
    $root->catalog->[0]->body
    $root->catalog->[0]->person
    $root->catalog->[0]->period
    $root->catalog->[0]->series
    $root->catalog->[0]->width
    $root->catalog->[0]->height
    $root->catalog->[0]->length
    $root->catalog->[0]->photo
    $root->catalog->[0]->urls
    $root->catalog->[0]->desc
    $root->catalog->[0]->brand->code
    $root->catalog->[0]->brand->name
    $root->catalog->[0]->body->code
    $root->catalog->[0]->body->name
    $root->catalog->[0]->photo->front
    $root->catalog->[0]->photo->rear
    $root->catalog->[0]->photo->inpane
    $root->catalog->[0]->urls->pc
    $root->catalog->[0]->urls->mobile
    $root->catalog->[0]->urls->qr
    $root->catalog->[0]->photo->front->caption
    $root->catalog->[0]->photo->front->l
    $root->catalog->[0]->photo->front->s
    $root->catalog->[0]->photo->rear->caption
    $root->catalog->[0]->photo->rear->l
    $root->catalog->[0]->photo->rear->s
    $root->catalog->[0]->photo->inpane->caption
    $root->catalog->[0]->photo->inpane->l
    $root->catalog->[0]->photo->inpane->s


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
