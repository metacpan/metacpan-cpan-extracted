package WebService::Recruit::Shingaku::License;

use strict;
use base qw( WebService::Recruit::Shingaku::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/shingaku/license/v1/'; }

sub query_class { 'WebService::Recruit::Shingaku::License::Query'; }

sub query_fields { [
    'key', 'code', 'keyword', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::Shingaku::License::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'error' => ['message'],
    'license' => ['code', 'name', 'desc', 'subject', 'work', 'urls'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'license', 'api_version', 'error'],
    'subject' => ['code', 'name'],
    'urls' => ['mobile', 'pc', 'qr'],
    'work' => ['code', 'name'],

}; }

sub force_array { [
    'license', 'subject', 'work'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Shingaku::License::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Shingaku::License::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Shingaku::License::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Shingaku::License::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Shingaku::License::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Shingaku::License - Recruit Shingaku net Web Service "license" API

=head1 SYNOPSIS

    use WebService::Recruit::Shingaku;
    
    my $service = WebService::Recruit::Shingaku->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
    };
    my $res = $service->license( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "license: $data->license\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<license> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'code' => 'a1010',
        'keyword' => '東京 広告',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->license( %$param );

C<$service> above is an instance of L<WebService::Recruit::Shingaku>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->api_version
    $root->results_available
    $root->results_returned
    $root->results_start
    $root->license
    $root->license->[0]->code
    $root->license->[0]->name
    $root->license->[0]->desc
    $root->license->[0]->subject
    $root->license->[0]->work
    $root->license->[0]->urls
    $root->license->[0]->subject->[0]->code
    $root->license->[0]->subject->[0]->name
    $root->license->[0]->work->[0]->code
    $root->license->[0]->work->[0]->name
    $root->license->[0]->urls->mobile
    $root->license->[0]->urls->pc
    $root->license->[0]->urls->qr


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

L<WebService::Recruit::Shingaku>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
