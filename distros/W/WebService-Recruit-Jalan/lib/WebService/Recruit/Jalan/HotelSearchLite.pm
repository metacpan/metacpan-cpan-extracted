package WebService::Recruit::Jalan::HotelSearchLite;
use strict;
use vars qw( $VERSION );
use base qw( WebService::Recruit::Jalan::Base );
$VERSION = '0.10';

sub url { 'http://jws.jalan.net/APILite/HotelSearch/V1/'; }

sub query_class { 'WebService::Recruit::Jalan::HotelSearchLite::Query'; }
sub query_fields { [qw(
    key pref l_area s_area h_id h_type o_pool parking pub_bath onsen
    prv_bath v_bath sauna jacz mssg r_ski r_brd pet esthe p_pong limo
    late_out pict_size order start count
)]; }
sub notnull_param { [qw( key )]; }

sub elem_class { 'WebService::Recruit::Jalan::HotelSearchLite::Element'; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults DisplayPerPage DisplayFrom APIVersion Hotel
    )],
    Hotel => [qw(
        HotelID HotelName PostCode HotelAddress Area HotelType
        HotelDetailURL HotelCatchCopy HotelCaption PictureURL
        PictureCaption AccessInformation CheckInTime CheckOutTime
        X Y LastUpdate
    )],
    Area => [qw(
        Region Prefecture LargeArea SmallArea
    )],
    AccessInformation => [qw(
        name _text
    )],
    LastUpdate => [qw(
        day month year
    )],
}; }
sub force_array { [qw( Hotel AccessInformation )]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Jalan::HotelSearchLite::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Jalan::HotelSearchLite::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Jalan::HotelSearchLite::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Jalan::HotelSearchLite::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Jalan::HotelSearchLite::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Jalan::HotelSearchLite - Jalan Web Service "HotelSearchLite" API

=head1 SYNOPSIS

    use WebService::Recruit::Jalan;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        s_area  =>  '162612',
        h_type  =>  '1',
    };
    my $res = $jalan->HotelSearchLite( %$param );
    die "error!" if $res->is_error;

    my $list = $res->root->Hotel;
    foreach my $hotel ( @$list ) {
        print "HotelID: ",   $hotel->HotelID, "\n";
        print "HotelName: ", $hotel->HotelName, "\n";
    }

=head1 DESCRIPTION

This module is a interface for the C<HotelSearchLite> API.
It accepts following query parameters to make an request.

    my $param = {
        pref        =>  '130000',
        l_area      =>  '136200',
        s_area      =>  '136202',
        h_id        =>  '324994',
        h_type      =>  '0',
        o_pool      =>  '0',
        parking     =>  '0',
        pub_bath    =>  '0',
        onsen       =>  '0',
        prv_bath    =>  '0',
        v_bath      =>  '0',
        sauna       =>  '0',
        jacz        =>  '0',
        mssg        =>  '0',
        r_ski       =>  '0',
        r_brd       =>  '0',
        pet         =>  '0',
        esthe       =>  '0',
        p_pong      =>  '0',
        limo        =>  '0',
        late_out    =>  '0',
        pict_size   =>  '3',        # pictM
        order       =>  '0',
        start       =>  '1',
        count       =>  '10',
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
    $root->Hotel;
    $root->Hotel->[0]->HotelID;
    $root->Hotel->[0]->HotelName;
    $root->Hotel->[0]->PostCode;
    $root->Hotel->[0]->HotelAddress;
    $root->Hotel->[0]->Area;
    $root->Hotel->[0]->Area->Region;
    $root->Hotel->[0]->Area->Prefecture;
    $root->Hotel->[0]->Area->LargeArea;
    $root->Hotel->[0]->Area->SmallArea;
    $root->Hotel->[0]->HotelType;
    $root->Hotel->[0]->HotelDetailURL;
    $root->Hotel->[0]->HotelCatchCopy;
    $root->Hotel->[0]->HotelCaption;
    $root->Hotel->[0]->PictureURL;
    $root->Hotel->[0]->PictureCaption;
    $root->Hotel->[0]->AccessInformation;
    $root->Hotel->[0]->AccessInformation->[0]->name;
    $root->Hotel->[0]->CheckInTime;
    $root->Hotel->[0]->CheckOutTime;
    $root->Hotel->[0]->X;
    $root->Hotel->[0]->Y;
    $root->Hotel->[0]->LastUpdate;
    $root->Hotel->[0]->LastUpdate->day;
    $root->Hotel->[0]->LastUpdate->month;
    $root->Hotel->[0]->LastUpdate->year;

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
