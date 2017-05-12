package WebService::Recruit::AkasuguUchiiwai::Item;

use strict;
use base qw( WebService::Recruit::AkasuguUchiiwai::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/uchiiwai/item/v1/'; }

sub query_class { 'WebService::Recruit::AkasuguUchiiwai::Item::Query'; }

sub query_fields { [
    'key', 'code', 'name', 'category', 'price_min', 'price_max', 'keyword', 'target', 'feature', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::AkasuguUchiiwai::Item::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'category' => ['code', 'name'],
    'error' => ['message'],
    'feature' => ['code', 'name'],
    'image' => ['pc_l', 'pc_m', 'pc_s', 'mobile_l', 'mobile_s'],
    'item' => ['code', 'brand', 'name', 'price', 'desc', 'spec', 'image', 'category', 'target', 'feature', 'start_date', 'end_date', 'urls'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'item', 'api_version', 'error'],
    'target' => ['code', 'name'],
    'urls' => ['mobile', 'pc', 'qr'],

}; }

sub force_array { [
    'item'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::AkasuguUchiiwai::Item::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::AkasuguUchiiwai::Item::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::AkasuguUchiiwai::Item::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::AkasuguUchiiwai::Item::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::AkasuguUchiiwai::Item::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::AkasuguUchiiwai::Item - AkasuguUchiiwai Web Service "item" API

=head1 SYNOPSIS

    use WebService::Recruit::AkasuguUchiiwai;
    
    my $service = WebService::Recruit::AkasuguUchiiwai->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'target' => '1',
    };
    my $res = $service->item( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "item: $data->item\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<item> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'code' => '9999-999',
        'name' => 'ガーゼケット　りす',
        'category' => '3695',
        'price_min' => '2000',
        'price_max' => '5400',
        'keyword' => '赤すぐオリジナル',
        'target' => '1',
        'feature' => '1',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->item( %$param );

C<$service> above is an instance of L<WebService::Recruit::AkasuguUchiiwai>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->item
    $root->item->[0]->code
    $root->item->[0]->brand
    $root->item->[0]->name
    $root->item->[0]->price
    $root->item->[0]->desc
    $root->item->[0]->spec
    $root->item->[0]->image
    $root->item->[0]->category
    $root->item->[0]->target
    $root->item->[0]->feature
    $root->item->[0]->start_date
    $root->item->[0]->end_date
    $root->item->[0]->urls
    $root->item->[0]->image->pc_l
    $root->item->[0]->image->pc_m
    $root->item->[0]->image->pc_s
    $root->item->[0]->image->mobile_l
    $root->item->[0]->image->mobile_s
    $root->item->[0]->category->code
    $root->item->[0]->category->name
    $root->item->[0]->target->code
    $root->item->[0]->target->name
    $root->item->[0]->feature->code
    $root->item->[0]->feature->name
    $root->item->[0]->urls->mobile
    $root->item->[0]->urls->pc
    $root->item->[0]->urls->qr


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

L<WebService::Recruit::AkasuguUchiiwai>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
