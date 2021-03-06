package WebService::Recruit::Jalan::HotelSearchAdvance;
use strict;
use vars qw( $VERSION );
use base qw( WebService::Recruit::Jalan::Base );
$VERSION = '0.10';

sub url { 'http://jws.jalan.net/APIAdvance/HotelSearch/V1/'; }

sub query_class { 'WebService::Recruit::Jalan::HotelSearchAdvance::Query'; }
sub query_fields { [qw(
    key reg pref l_area s_area h_id o_area_id o_id x y range h_name
    h_type o_pool parking pub_bath onsen prv_bath v_bath sauna jacz
    mssg r_ski r_brd pet esthe p_pong limo room_b room_d prv_b prv_d
    early_in late_out no_smk net r_room high p_ok sp_room bath_to
    o_bath pour cloudy i_pool fitness gym p_field bbq hall 5_station
    5_beach 5_slope c_card c_jcb c_visa c_master c_amex c_uc c_dc
    c_nicos c_diners c_saison c_ufj cvs no_meal b_only d_only 2_meals
    sng_room twn_room dbl_room tri_room 4bed_room jpn_room j_w_room
    child_price c_bed_meal c_no_bed_meal c_meal_only c_bed_only
    pict_size picts order start count xml_ptn
)]; }
sub notnull_param { [qw( key )]; }

sub elem_class { 'WebService::Recruit::Jalan::HotelSearchAdvance::Element'; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults DisplayPerPage DisplayFrom APIVersion Hotel
    )],
    Hotel => [qw(
        HotelID HotelName PostCode HotelAddress Area HotelType
        HotelDetailURL HotelCatchCopy HotelCaption PictureURL
        PictureCaption AccessInformation CheckInTime CheckOutTime
        X Y SampleRateFrom LastUpdate OnsenName HotelNameKana
        CreditCard NumberOfRatings Rating Plan
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
    CreditCard => [qw(
        AMEX DC DINNERS ETC JCB MASTER MILLION  NICOS SAISON UC UFJ VISA _text
    )],
    Plan => [qw(
        PlanName RoomType RoomName PlanCheckIn PlanCheckOut PlanPictureURL
        PlanPictureCaption Meal PlanSampleRateFrom
    )],
}; }
sub force_array { [qw(
    Hotel PictureURL PictureCaption AccessInformation
    Plan RoomType PlanPictureURL PlanPictureCaption
)]; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Jalan::HotelSearchAdvance::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Jalan::HotelSearchAdvance::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Jalan::HotelSearchAdvance::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Jalan::HotelSearchAdvance::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Jalan::HotelSearchAdvance::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Jalan::HotelSearchAdvance - Jalan Web Service "HotelSearchAdvance" API

=head1 SYNOPSIS

    use WebService::Recruit::Jalan;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        s_area      =>  '162612',
        xml_ptn     =>  '2',
    };
    my $res = $jalan->HotelSearchAdvance( %$param );
    die "error!" if $res->is_error;

    my $list = $res->root->Hotel;
    foreach my $hotel ( @$list ) {
        print "HotelID: ",   $hotel->HotelID, "\n";
        print "HotelName: ", $hotel->HotelName, "\n";
    }

=head1 DESCRIPTION

This module is a interface for the C<HotelSearchAdvance> API.
It accepts following query parameters to make an request.

    my $param = {
        reg         =>  '10',
        pref        =>  '130000',
        l_area      =>  '136200',
        s_area      =>  '136202',
        h_id        =>  '324994',
        o_area_id   =>  '50024',
        o_id        =>  '0042',
        x           =>  '503037529',
        y           =>  '128366212',
        range       =>  '10',
        h_name      =>  'Hotel Name',
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
        room_b      =>  '0',
        room_d      =>  '0',
        prv_b       =>  '0',
        prv_d       =>  '0',
        early_in    =>  '0',
        late_out    =>  '0',
        no_smk      =>  '0',
        net         =>  '0',
        r_room      =>  '0',
        high        =>  '0',
        p_ok        =>  '0',
        sp_room     =>  '0',
        bath_to     =>  '0',
        o_bath      =>  '0',
        pour        =>  '0',
        cloudy      =>  '0',
        i_pool      =>  '0',
        fitness     =>  '0',
        gym         =>  '0',
        p_field     =>  '0',
        bbq         =>  '0',
        hall        =>  '0',
        5_station   =>  '0',
        5_beach     =>  '0',
        5_slope     =>  '0',
        c_card      =>  '0',
        c_jcb       =>  '0',
        c_visa      =>  '0',
        c_master    =>  '0',
        c_amex      =>  '0',
        c_uc        =>  '0',
        c_dc        =>  '0',
        c_nicos     =>  '0',
        c_diners    =>  '0',
        c_saison    =>  '0',
        c_ufj       =>  '0',
        cvs         =>  '0',
        no_meal     =>  '0',
        b_only      =>  '0',
        d_only      =>  '0',
        2_meals     =>  '0',
        sng_room    =>  '0',
        twn_room    =>  '0',
        dbl_room    =>  '0',
        tri_room    =>  '0',
        4bed_room   =>  '0',
        jpn_room    =>  '0',
        j_w_room    =>  '0',
        child_price =>  '0',
        c_bed_meal  =>  '0',
        c_no_bed_meal => '0',
        c_meal_only =>  '0',
        c_bed_only  =>  '0',
        pict_size   =>  '3',    # pictM
        picts       =>  '5',
        order       =>  '0',
        start       =>  '1',
        count       =>  '10',
        xml_ptn     =>  '2',
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
    $root->Hotel->[0]->PictureURL->[0];
    $root->Hotel->[0]->PictureCaption->[0];
    $root->Hotel->[0]->AccessInformation;
    $root->Hotel->[0]->AccessInformation->[0]->name;
    $root->Hotel->[0]->CheckInTime;
    $root->Hotel->[0]->CheckOutTime;
    $root->Hotel->[0]->X;
    $root->Hotel->[0]->Y;
    $root->Hotel->[0]->SampleRateFrom;
    $root->Hotel->[0]->LastUpdate;
    $root->Hotel->[0]->LastUpdate->day;
    $root->Hotel->[0]->LastUpdate->month;
    $root->Hotel->[0]->LastUpdate->year;
    $root->Hotel->[0]->OnsenName;
    $root->Hotel->[0]->HotelNameKana;
    $root->Hotel->[0]->CreditCard;
    $root->Hotel->[0]->CreditCard->AMEX;
    $root->Hotel->[0]->CreditCard->DC;
    $root->Hotel->[0]->CreditCard->DINNERS;
    $root->Hotel->[0]->CreditCard->ETC;
    $root->Hotel->[0]->CreditCard->JCB;
    $root->Hotel->[0]->CreditCard->MASTER;
    $root->Hotel->[0]->CreditCard->MILLION;
    $root->Hotel->[0]->CreditCard->NICOS;
    $root->Hotel->[0]->CreditCard->SAISON;
    $root->Hotel->[0]->CreditCard->UC;
    $root->Hotel->[0]->CreditCard->UFJ;
    $root->Hotel->[0]->CreditCard->VISA;
    $root->Hotel->[0]->NumberOfRatings;
    $root->Hotel->[0]->Rating;
    $root->Hotel->[0]->Plan;
    $root->Hotel->[0]->Plan->[0]->PlanName;
    $root->Hotel->[0]->Plan->[0]->RoomType->[0];
    $root->Hotel->[0]->Plan->[0]->RoomName;
    $root->Hotel->[0]->Plan->[0]->PlanCheckIn;
    $root->Hotel->[0]->Plan->[0]->PlanCheckOut;
    $root->Hotel->[0]->Plan->[0]->PlanPictureURL;
    $root->Hotel->[0]->Plan->[0]->PlanPictureCaption;
    $root->Hotel->[0]->Plan->[0]->Meal;
    $root->Hotel->[0]->Plan->[0]->PlanSampleRateFrom;

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
