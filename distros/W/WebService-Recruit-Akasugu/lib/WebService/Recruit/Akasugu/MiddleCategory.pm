package WebService::Recruit::Akasugu::MiddleCategory;

use strict;
use base qw( WebService::Recruit::Akasugu::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/akasugu/middle_category/v1/'; }

sub query_class { 'WebService::Recruit::Akasugu::MiddleCategory::Query'; }

sub query_fields { [
    'key', 'large_code', 'middle_code', 'keyword'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::Akasugu::MiddleCategory::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'error' => ['message'],
    'large_category' => ['code', 'name'],
    'middle_category' => ['code', 'name', 'large_category'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'middle_category', 'api_version', 'error'],

}; }

sub force_array { [
    'middle_category'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Akasugu::MiddleCategory::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Akasugu::MiddleCategory::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Akasugu::MiddleCategory::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Akasugu::MiddleCategory::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Akasugu::MiddleCategory::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Akasugu::MiddleCategory - Akasugu.net Web Service "middle_category" API

=head1 SYNOPSIS

    use WebService::Recruit::Akasugu;
    
    my $service = WebService::Recruit::Akasugu->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->middle_category( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "middle_category: $data->middle_category\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<middle_category> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'large_code' => '2',
        'middle_code' => '211',
        'keyword' => 'ベビー',
    };
    my $res = $service->middle_category( %$param );

C<$service> above is an instance of L<WebService::Recruit::Akasugu>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->middle_category
    $root->middle_category->[0]->code
    $root->middle_category->[0]->name
    $root->middle_category->[0]->large_category
    $root->middle_category->[0]->large_category->code
    $root->middle_category->[0]->large_category->name


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

L<WebService::Recruit::Akasugu>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
