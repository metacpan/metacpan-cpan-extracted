package WebService::Recruit::Shingaku::School;

use strict;
use base qw( WebService::Recruit::Shingaku::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://webservice.recruit.co.jp/shingaku/school/v1/'; }

sub query_class { 'WebService::Recruit::Shingaku::School::Query'; }

sub query_fields { [
    'key', 'code', 'name', 'kana', 'faculty', 'department', 'pref_cd', 'category_cd', 'address', 'lat', 'lng', 'range', 'datum', 'station', 'keyword', 'subject_cd', 'work_cd', 'order', 'start', 'count'
]; }

sub default_param { {
    'format' => 'xml'
}; }

sub notnull_param { [
    'key'
]; }

sub elem_class { 'WebService::Recruit::Shingaku::School::Element'; }

sub root_elem { 'results'; }

sub elem_fields { {
    'campus' => ['name', 'address', 'datum', 'latitude', 'longitude', 'station'],
    'category' => ['code', 'name'],
    'error' => ['message'],
    'faculty' => ['name', 'department'],
    'pref' => ['code', 'name'],
    'results' => ['api_version', 'results_available', 'results_returned', 'results_start', 'school', 'api_version', 'error'],
    'school' => ['code', 'name', 'kana', 'campus', 'category', 'faculty', 'pref', 'urls'],
    'urls' => ['mobile', 'pc', 'qr'],

}; }

sub force_array { [
    'campus', 'faculty', 'school'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Shingaku::School::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Shingaku::School::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Shingaku::School::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Shingaku::School::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Shingaku::School::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Shingaku::School - Recruit Shingaku net Web Service "school" API

=head1 SYNOPSIS

    use WebService::Recruit::Shingaku;
    
    my $service = WebService::Recruit::Shingaku->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
        'pref_cd' => '12',
    };
    my $res = $service->school( %$param );
    my $data = $res->root;
    print "api_version: $data->api_version\n";
    print "results_available: $data->results_available\n";
    print "results_returned: $data->results_returned\n";
    print "results_start: $data->results_start\n";
    print "school: $data->school\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<school> API.
It accepts following query parameters to make an request.

    my $param = {
        'key' => 'XXXXXXXX',
        'code' => 'SC999999',
        'name' => '銀座大学',
        'kana' => 'リクルート',
        'faculty' => '広告学部',
        'department' => 'メディア学科',
        'pref_cd' => '13',
        'category_cd' => '11',
        'address' => '東京都中央区銀座8',
        'lat' => '35.66922072646455',
        'lng' => '139.7614574432373',
        'range' => 'XXXXXXXX',
        'datum' => 'XXXXXXXX',
        'station' => '新橋',
        'keyword' => '東京 広告',
        'subject_cd' => 'a1010',
        'work_cd' => 'a2010',
        'order' => 'XXXXXXXX',
        'start' => 'XXXXXXXX',
        'count' => 'XXXXXXXX',
    };
    my $res = $service->school( %$param );

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
    $root->school
    $root->school->[0]->code
    $root->school->[0]->name
    $root->school->[0]->kana
    $root->school->[0]->campus
    $root->school->[0]->category
    $root->school->[0]->faculty
    $root->school->[0]->pref
    $root->school->[0]->urls
    $root->school->[0]->campus->[0]->name
    $root->school->[0]->campus->[0]->address
    $root->school->[0]->campus->[0]->datum
    $root->school->[0]->campus->[0]->latitude
    $root->school->[0]->campus->[0]->longitude
    $root->school->[0]->campus->[0]->station
    $root->school->[0]->category->code
    $root->school->[0]->category->name
    $root->school->[0]->faculty->[0]->name
    $root->school->[0]->faculty->[0]->department
    $root->school->[0]->pref->code
    $root->school->[0]->pref->name
    $root->school->[0]->urls->mobile
    $root->school->[0]->urls->pc
    $root->school->[0]->urls->qr


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
