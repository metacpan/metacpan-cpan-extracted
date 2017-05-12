package WebService::Recruit::HotPepperBeauty::Salon;

use strict;
use base qw( WebService::Recruit::HotPepperBeauty::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/beauty/salon/v1/'; }

sub query_class { 'WebService::Recruit::HotPepperBeauty::Salon::Query'; }

sub query_fields { [
    'key', 'id', 'name', 'name_kana', 'address', 'service_area', 'middle_area', 'small_area', 'keyword', 'lat', 'lng', 'range', 'datum', 'hair_image', 'hair_length', 'hair_ryou', 'hair_shitsu', 'hair_futosa', 'hair_kuse', 'hair_kaogata', 'kodawari', 'kodawari_setsubi', 'kodawari_menu', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::HotPepperBeauty::Salon::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'coupon_urls' => ['pc'],
    'error' => ['message'],
    'feature' => ['name', 'caption', 'description'],
    'main' => ['photo', 'caption'],
    'middle_area' => ['code', 'name'],
    'mood' => ['photo', 'caption'],
    'photo' => ['s', 'm', 'l'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'salon', 'api_version', 'error'],
    'salon' => ['id', 'last_update', 'name', 'name_kana', 'urls', 'coupon_urls', 'address', 'service_area', 'middle_area', 'small_area', 'open', 'close', 'credit_card', 'price', 'stylist_num', 'capacity', 'parking', 'note', 'kodawari', 'lat', 'lng', 'catch_copy', 'description', 'main', 'mood', 'feature'],
    'service_area' => ['code', 'name'],
    'small_area' => ['code', 'name'],
    'urls' => ['pc'],

}; }

sub force_array { [
    'feature', 'mood', 'salon'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::HotPepperBeauty::Salon::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::HotPepperBeauty::Salon::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::HotPepperBeauty::Salon::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::HotPepperBeauty::Salon::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::HotPepperBeauty::Salon::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::HotPepperBeauty::Salon - HotPepperBeauty Web Service "salon" API

=head1 SYNOPSIS

    use WebService::Recruit::HotPepperBeauty;
    
    my $service = WebService::Recruit::HotPepperBeauty->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'name' => 'サロン',
        'order' => '3',
    };
    my $res = $service->salon( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "salon: $data->salon\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<salon> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'id' => 'H0123456789',
        'name' => 'XXXXXXXX',
        'name_kana' => 'XXXXXXXX',
        'address' => 'XXXXXXXX',
        'service_area' => 'SA',
        'middle_area' => 'AAAA',
        'small_area' => 'X001',
        'keyword' => 'XXXXXXXX',
        'lat' => '35.669220',
        'lng' => '139.761457',
        'range' => 'XXXXXXXX',
        'datum' => 'world',
        'hair_image' => '2',
        'hair_length' => '5',
        'hair_ryou' => 'XXXXXXXX',
        'hair_shitsu' => 'XXXXXXXX',
        'hair_futosa' => 'XXXXXXXX',
        'hair_kuse' => 'XXXXXXXX',
        'hair_kaogata' => 'XXXXXXXX',
        'kodawari' => '4',
        'kodawari_setsubi' => '2',
        'kodawari_menu' => '3',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->salon( %$param );

C<$service> above is an instance of L<WebService::Recruit::HotPepperBeauty>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->salon
    $root->salon->[0]->id
    $root->salon->[0]->last_update
    $root->salon->[0]->name
    $root->salon->[0]->name_kana
    $root->salon->[0]->urls
    $root->salon->[0]->coupon_urls
    $root->salon->[0]->address
    $root->salon->[0]->service_area
    $root->salon->[0]->middle_area
    $root->salon->[0]->small_area
    $root->salon->[0]->open
    $root->salon->[0]->close
    $root->salon->[0]->credit_card
    $root->salon->[0]->price
    $root->salon->[0]->stylist_num
    $root->salon->[0]->capacity
    $root->salon->[0]->parking
    $root->salon->[0]->note
    $root->salon->[0]->kodawari
    $root->salon->[0]->lat
    $root->salon->[0]->lng
    $root->salon->[0]->catch_copy
    $root->salon->[0]->description
    $root->salon->[0]->main
    $root->salon->[0]->mood
    $root->salon->[0]->feature
    $root->salon->[0]->urls->pc
    $root->salon->[0]->coupon_urls->pc
    $root->salon->[0]->service_area->code
    $root->salon->[0]->service_area->name
    $root->salon->[0]->middle_area->code
    $root->salon->[0]->middle_area->name
    $root->salon->[0]->small_area->code
    $root->salon->[0]->small_area->name
    $root->salon->[0]->main->photo
    $root->salon->[0]->main->caption
    $root->salon->[0]->mood->[0]->photo
    $root->salon->[0]->mood->[0]->caption
    $root->salon->[0]->feature->[0]->name
    $root->salon->[0]->feature->[0]->caption
    $root->salon->[0]->feature->[0]->description
    $root->salon->[0]->main->photo->s
    $root->salon->[0]->main->photo->m
    $root->salon->[0]->main->photo->l


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

L<WebService::Recruit::HotPepperBeauty>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
