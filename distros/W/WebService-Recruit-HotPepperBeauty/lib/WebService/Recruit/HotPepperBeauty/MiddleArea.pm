package WebService::Recruit::HotPepperBeauty::MiddleArea;

use strict;
use base qw( WebService::Recruit::HotPepperBeauty::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/beauty/middle_area/v1/'; }

sub query_class { 'WebService::Recruit::HotPepperBeauty::MiddleArea::Query'; }

sub query_fields { [
    'key', 'service_area', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::HotPepperBeauty::MiddleArea::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'error' => ['message'],
    'middle_area' => ['code', 'name', 'service_area'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'middle_area', 'api_version', 'error'],
    'service_area' => ['code', 'name'],

}; }

sub force_array { [
    'middle_area'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::HotPepperBeauty::MiddleArea::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::HotPepperBeauty::MiddleArea::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::HotPepperBeauty::MiddleArea::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::HotPepperBeauty::MiddleArea::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::HotPepperBeauty::MiddleArea::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::HotPepperBeauty::MiddleArea - HotPepperBeauty Web Service "middle_area" API

=head1 SYNOPSIS

    use WebService::Recruit::HotPepperBeauty;
    
    my $service = WebService::Recruit::HotPepperBeauty->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->middle_area( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "middle_area: $data->middle_area\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<middle_area> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'service_area' => 'SA',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->middle_area( %$param );

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
    $root->middle_area
    $root->middle_area->[0]->code
    $root->middle_area->[0]->name
    $root->middle_area->[0]->service_area
    $root->middle_area->[0]->service_area->code
    $root->middle_area->[0]->service_area->name


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
