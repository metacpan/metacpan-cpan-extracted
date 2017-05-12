package WebService::Recruit::HotPepper::GourmetSearch;
use strict;
use base qw( WebService::Recruit::HotPepper::Base );
use vars qw( $VERSION );
$VERSION = '0.02';

sub url { 'http://api.hotpepper.jp/GourmetSearch/V110'; }
sub force_array { [qw( Shop Error )]; }
sub elem_class  { 'WebService::Recruit::HotPepper::GourmetSearch::Element'; }
sub query_class { 'WebService::Recruit::HotPepper::GourmetSearch::Query'; }

sub query_fields { [qw(
    ShopIdFront ShopNameKana ShopName ShopTel ShopAddress
    LargeServiceAreaCD ServiceAreaCD LargeAreaCD MiddleAreaCD
    SmallAreaCD Keyword Latitude Longitude Range Datum KtaiCoupon
    GenreCD FoodCD BudgetCD PartyCapacity Wedding Course FreeDrink
    FreeFood PrivateRoom Horigotatsu Tatami Cocktail Shochu
    Sake Wine Card NonSmoking Charter Ktai Parking BarrierFree
    Sommelier NightView OpenAir Show Equipment Karaoke Band
    Tv Lunch Midnight MidnightMeal English Pet Child
    key Order Start Count
)]; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults DisplayPerPage DisplayFrom APIVersion
        Shop
    )],
    Shop => [qw(
        ShopIdFront ShopNameKana ShopName ShopAddress StationName
        KtaiCoupon LargeServiceAreaCD LargeServiceAreaName
        ServiceAreaCD ServiceAreaName LargeAreaCD LargeAreaName
        MiddleAreaCD MiddleAreaName SmallAreaCD SmallAreaName 
        Latitude Longitude GenreCD GenreName FoodCD FoodName
        GenreCatch ShopCatch BudgetCD BudgetDesc BudgetAverage
        Capacity Access KtaiAccess ShopUrl KtaiShopUrl KtaiQRUrl
        PictureUrl Open Close PartyCapacity Wedding Course
        FreeDrink FreeFood PrivateRoom Horigotatsu Tatami
        Card NonSmoking Charter Ktai Parking BarrierFree
        Sommelier OpenAir Show Equipment Karaoke Band Tv 
        English Pet Child
    )],
    PictureUrl => [qw(
        PcLargeImg PcMiddleImg PcSmallImg MbLargeImg MbSmallImg
    )],
}; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::HotPepper::GourmetSearch::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::HotPepper::GourmetSearch::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::HotPepper::GourmetSearch::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::HotPepper::GourmetSearch::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::HotPepper::GourmetSearch::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::HotPepper::GourmetSearch - HotPepper Web Service "GourmetSearch" API

=head1 SYNOPSIS

    use WebService::Recruit::HotPepper;

    my $api = WebService::Recruit::HotPepper->new();
    $api->key( 'xxxxxxxxxxxxxxxx' );

    my $param = {
        ServiceAreaCD => 'SA11',
        GenreCD       => 'G002',
    };
    my $res = $api->GourmetSearch( %$param );
    die 'error!' if $res->is_error;

    my $list = $res->root->Shop;
    foreach my $shop ( @$list ) {
        print "name:  ", $shop->ShopName, "\n";
        print "addr:  ", $shop->ShopAddress, "\n";
        print "photo: ", $shop->PictureUrl->PcLargeImg, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is an interface for the C<GourmetSearch> API.
It accepts following query parameters to make an request.

    my $param = {
        Start       => 1,
        Count       => 10,
        keyword     => 'italian pizza',
        ShopName    => 'antonio',
        SmallAreaCD => 'X005',
        #
        # ...and so on. See
        # http://api.hotpepper.jp/reference.html
        # for a complete list of available params.
    };
    my $res = $hpp->GourmetSearch( %$param );

C<$hpp> above is an instance of L<WebService::Recruit::HotPepper>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->NumberOfResults;
    $root->DisplayPerPage;
    $root->DisplayFrom;
    $root->APIVersion;
    $root->Shop->[0]->ShopIdFront;
    $root->Shop->[0]->ShopNameKana;
    $root->Shop->[0]->ShopName;
    $root->Shop->[0]->ShopAddress;
    $root->Shop->[0]->StationName;
    $root->Shop->[0]->KtaiCoupon;
    $root->Shop->[0]->LargeServiceAreaCD;
    $root->Shop->[0]->LargeServiceAreaName;
    $root->Shop->[0]->ServiceAreaCD;
    $root->Shop->[0]->ServiceAreaName;
    $root->Shop->[0]->LargeAreaCD;
    $root->Shop->[0]->LargeAreaName;
    $root->Shop->[0]->MiddleAreaCD;
    $root->Shop->[0]->MiddleAreaName;
    $root->Shop->[0]->SmallAreaCD;
    $root->Shop->[0]->SmallAreaName;
    $root->Shop->[0]->Latitude;
    $root->Shop->[0]->Longitude;
    $root->Shop->[0]->GenreCD;
    $root->Shop->[0]->GenreName;
    $root->Shop->[0]->FoodCD;
    $root->Shop->[0]->FoodName;
    $root->Shop->[0]->GenreCatch;
    $root->Shop->[0]->ShopCatch;
    $root->Shop->[0]->BudgetCD;
    $root->Shop->[0]->BudgetDesc;
    $root->Shop->[0]->BudgetAverage;
    $root->Shop->[0]->Capacity;
    $root->Shop->[0]->Access;
    $root->Shop->[0]->KtaiAccess;
    $root->Shop->[0]->ShopUrl;
    $root->Shop->[0]->KtaiShopUrl;
    $root->Shop->[0]->KtaiQRUrl;
    $root->Shop->[0]->PictureUrl->PcLargeImg;
    $root->Shop->[0]->PictureUrl->PcMiddleImg;
    $root->Shop->[0]->PictureUrl->PcSmallImg;
    $root->Shop->[0]->PictureUrl->MbLargeImg;
    $root->Shop->[0]->PictureUrl->MbSmallImg;
    $root->Shop->[0]->Open;
    $root->Shop->[0]->Close;
    $root->Shop->[0]->PartyCapacity;
    $root->Shop->[0]->Wedding;
    $root->Shop->[0]->Course;
    $root->Shop->[0]->FreeDrink;
    $root->Shop->[0]->FreeFood;
    $root->Shop->[0]->PrivateRoom;
    $root->Shop->[0]->Horigotatsu;
    $root->Shop->[0]->Tatami;
    $root->Shop->[0]->Card;
    $root->Shop->[0]->NonSmoking;
    $root->Shop->[0]->Charter;
    $root->Shop->[0]->Ktai;
    $root->Shop->[0]->Parking;
    $root->Shop->[0]->BarrierFree;
    $root->Shop->[0]->Sommelier;
    $root->Shop->[0]->OpenAir;
    $root->Shop->[0]->Show;
    $root->Shop->[0]->Equipment;
    $root->Shop->[0]->Karaoke;
    $root->Shop->[0]->Band;
    $root->Shop->[0]->Tv;
    $root->Shop->[0]->English;
    $root->Shop->[0]->Pet;
    $root->Shop->[0]->Child;

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

L<WebService::Recruit::HotPepper>

=head1 AUTHOR

Toshimasa Ishibashi L<http://iandeth.dyndns.org/>

This module is unofficial and released by the author in person.

=head1 THANKS TO

Yusuke Kawasaki L<http://www.kawa.net/>

For creating/preparing all the base modules and stuff.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Toshimasa Ishibashi. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
