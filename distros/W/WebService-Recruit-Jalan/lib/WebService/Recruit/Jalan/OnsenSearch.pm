package WebService::Recruit::Jalan::OnsenSearch;
use strict;
use vars qw( $VERSION );
use base qw( WebService::Recruit::Jalan::Base );
$VERSION = '0.10';

sub url { 'http://jws.jalan.net/APICommon/OnsenSearch/V1/'; }

sub query_class { 'WebService::Recruit::Jalan::OnsenSearch::Query'; }
sub query_fields { [qw(
    key reg pref l_area s_area onsen_q start count xml_ptn
)]; }
sub notnull_param { [qw( key )]; }

sub elem_class { 'WebService::Recruit::Jalan::OnsenSearch::Element'; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults DisplayPerPage DisplayFrom APIVersion Onsen
    )],
    Onsen => [qw(
        OnsenName OnsenNameKana OnsenID OnsenAddress Area NatureOfOnsen
        OnsenAreaName OnsenAreaNameKana OnsenAreaID OnsenAreaURL
        OnsenAreaCaption
    )],
    Area => [qw(
        Region Prefecture LargeArea SmallArea
    )],
}; }
sub force_array { [qw( Onsen )]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Jalan::OnsenSearch::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Jalan::OnsenSearch::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Jalan::OnsenSearch::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Jalan::OnsenSearch::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Jalan::OnsenSearch::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Jalan::OnsenSearch - Jalan Web Service "OnsenSearch" API

=head1 SYNOPSIS

    use WebService::Recruit::Jalan;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        s_area      =>  '141602',
    };
    my $res = $jalan->OnsenSearch( %$param );
    die "error!" if $res->is_error;

    my $list = $res->root->Onsen;
    foreach my $onsen ( @$list ) {
        print "OnsenID: ",   $onsen->OnsenID, "\n";
        print "OnsenName: ", $onsen->OnsenName, "\n";
    }

=head1 DESCRIPTION

This module is a interface for the C<OnsenSearch> API.
It accepts following query parameters to make an request.

    my $param = {
        reg         =>  '10',
        pref        =>  '130000',
        l_area      =>  '136200',
        s_area      =>  '136202',
        onsen_q     =>  '0',
        start       =>  '1',
        count       =>  '10',
        xml_ptn     =>  '0',
    };

C<$jalan> above is an instance of L<WebService::Recruit::Jalan>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->NumberOfResults;
    $root->DisplayPerPage;
    $root->DisplayFrom;
    $root->APIVersion;
    $root->Onsen;
    $root->Onsen->[0]->OnsenName;
    $root->Onsen->[0]->OnsenNameKana;
    $root->Onsen->[0]->OnsenID;
    $root->Onsen->[0]->OnsenAddress;
    $root->Onsen->[0]->Area;
    $root->Onsen->[0]->Area->Region;
    $root->Onsen->[0]->Area->Prefecture;
    $root->Onsen->[0]->Area->LargeArea;
    $root->Onsen->[0]->Area->SmallArea;
    $root->Onsen->[0]->NatureOfOnsen;
    $root->Onsen->[0]->OnsenAreaName;
    $root->Onsen->[0]->OnsenAreaNameKana;
    $root->Onsen->[0]->OnsenAreaID;
    $root->Onsen->[0]->OnsenAreaURL;
    $root->Onsen->[0]->OnsenAreaCaption;

=head2 xml

This returns the raw response context itself.

    print $res->xml, "\n";

=head2 code

This returns the response status code.

    my $code = $res->code; # usually "200" when succeeded

=head2 is_error

This returns true value when the response has an error.

    die 'error!' if $res->is_error;

=head2 page

This returns a L<Data::Page> instance.

    my $page = $res->page();
    print "Total: ", $page->total_entries, "\n";
    print "Page: ", $page->current_page, "\n";
    print "Last: ", $page->last_page, "\n";

=head2 pageset

This returns a L<Data::Pageset> instance.

    my $pageset = $res->pageset( 'fixed' );
    $pageset->pages_per_set($pages_per_set);
    my $set = $pageset->pages_in_set();
    foreach my $num ( @$set ) {
        print "$num ";
    }

=head2 page_param

This returns a hash to specify the page for the next request.

    my %hash = $res->page_param( $page->next_page );

=head2 page_query

This returns a query string to specify the page for the next request.

    my $query = $res->page_query( $page->prev_page );

=head1 SEE ALSO

L<WebService::Recruit::Jalan>

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

This module is unofficial and released by the author in person.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
