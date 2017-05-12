package WebService::Recruit::FromA::JobSearch;

use strict;
use base qw( WebService::Recruit::FromA::Base );
use vars qw( $VERSION );
use Class::Accessor::Fast;
use Class::Accessor::Children::Fast;

$VERSION = '0.0.1';

sub http_method { 'GET'; }

sub url { 'http://xml.froma.yahoo.co.jp/s/r/jobSearch.jsp'; }

sub query_class { 'WebService::Recruit::FromA::JobSearch::Query'; }

sub query_fields { [
    'api_key', 'ksjcd', 'edition_cd', 'xml_block', 'm_area_cd', 's_area_cd', 'nv_jb_type_cd', 'shrt_indx_cd', 'wrk_dy_num_ctgry_cd', 'hours_ctgry_cd', 'regu_indx_s_class_cd', 'emp_ed_m_area_cd', 'employ_frm_ctgry_cd', 'pull_sal_cd', 'no_exp_ok_f'
]; }

sub default_param { {
    
}; }

sub notnull_param { [
    'api_key', 'ksjcd'
]; }

sub elem_class { 'WebService::Recruit::FromA::JobSearch::Element'; }

sub root_elem_list { [
    'OfferList',
    'Error',
]; }

sub elem_fields { {
    'Error' => ['Code', 'Message'],
    'GeoPointList' => ['GeoPoint'],
    'Offer' => ['Catch', 'OfferId', 'Url', 'OfferStartDate', 'OfferEndDate', 'Zipcode', 'Prefecture', 'City', 'VisualIndices', 'TimeIndices', 'MinimumWorkDays', 'ShortIndex', 'CorporateName', 'TransPortation', 'JobTypeDetail', 'PayText', 'OfferConditionList', 'GeoPointList'],
    'OfferCondition' => ['TypeOfEmployment'],
    'OfferConditionList' => ['OfferCondition'],
    'OfferList' => ['Code', 'TotalOfferAvailable', 'TotalOfferReturned', 'PageNumber', 'EditionName', 'Offer'],
    'TimeIndices' => ['TimeIndex'],
    'VisualIndex' => ['VisualSize', 'VisualName', 'VisualImageUrl'],
    'VisualIndices' => ['VisualIndex'],

}; }

sub force_array { [
    'GeoPoint', 'Offer', 'OfferCondition', 'TimeIndex', 'VisualIndex'
]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::FromA::JobSearch::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::FromA::JobSearch::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::FromA::JobSearch::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::FromA::JobSearch::Element->mk_ro_accessors( @{root_elem_list()} );
WebService::Recruit::FromA::JobSearch::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::FromA::JobSearch - FromA Navi Web Service "jobSearch" API

=head1 SYNOPSIS

    use WebService::Recruit::FromA;
    
    my $service = WebService::Recruit::FromA->new();
    
    my $param = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'ksjcd' => '04',
        'shrt_indx_cd' => '1001',
    };
    my $res = $service->jobSearch( %$param );
    my $data = $res->root;
    print "Code: $data->Code\n";
    print "TotalOfferAvailable: $data->TotalOfferAvailable\n";
    print "TotalOfferReturned: $data->TotalOfferReturned\n";
    print "PageNumber: $data->PageNumber\n";
    print "EditionName: $data->EditionName\n";
    print "...\n";

=head1 DESCRIPTION

This module is a interface for the C<jobSearch> API.
It accepts following query parameters to make an request.

    my $param = {
        'api_key' => 'XXXXXXXX',
        'ksjcd' => '04',
        'edition_cd' => '1',
        'xml_block' => '1',
        'm_area_cd' => 'i1',
        's_area_cd' => '1i1001',
        'nv_jb_type_cd' => '101',
        'shrt_indx_cd' => '1001',
        'wrk_dy_num_ctgry_cd' => '01',
        'hours_ctgry_cd' => '01',
        'regu_indx_s_class_cd' => '1101',
        'emp_ed_m_area_cd' => 'i1',
        'employ_frm_ctgry_cd' => '01',
        'pull_sal_cd' => '01',
        'no_exp_ok_f' => '1',
    };
    my $res = $service->jobSearch( %$param );

C<$service> above is an instance of L<WebService::Recruit::FromA>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->Code
    $root->TotalOfferAvailable
    $root->TotalOfferReturned
    $root->PageNumber
    $root->EditionName
    $root->Offer
    $root->Offer->[0]->Catch
    $root->Offer->[0]->OfferId
    $root->Offer->[0]->Url
    $root->Offer->[0]->OfferStartDate
    $root->Offer->[0]->OfferEndDate
    $root->Offer->[0]->Zipcode
    $root->Offer->[0]->Prefecture
    $root->Offer->[0]->City
    $root->Offer->[0]->VisualIndices
    $root->Offer->[0]->TimeIndices
    $root->Offer->[0]->MinimumWorkDays
    $root->Offer->[0]->ShortIndex
    $root->Offer->[0]->CorporateName
    $root->Offer->[0]->TransPortation
    $root->Offer->[0]->JobTypeDetail
    $root->Offer->[0]->PayText
    $root->Offer->[0]->OfferConditionList
    $root->Offer->[0]->GeoPointList
    $root->Offer->[0]->VisualIndices->VisualIndex
    $root->Offer->[0]->TimeIndices->TimeIndex
    $root->Offer->[0]->OfferConditionList->OfferCondition
    $root->Offer->[0]->GeoPointList->GeoPoint
    $root->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualSize
    $root->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualName
    $root->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualImageUrl
    $root->Offer->[0]->OfferConditionList->OfferCondition->[0]->TypeOfEmployment


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

L<WebService::Recruit::FromA>

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
