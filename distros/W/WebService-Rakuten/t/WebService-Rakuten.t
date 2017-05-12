# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Rakuten.t'

#########################

use Test::More tests => 28;
BEGIN { use_ok('WebService::Rakuten') };

#########################

my $r = WebService::Rakuten->new(
    developer_id => 'mock developer id',
    output_type  => 'perl',
);

for my $method ( qw( 
    simplehotelsearch
    booksgamesearch
    hoteldetailsearch
    gethotelchainlist
    bookssoftwaresearch
    bookscdsearch
    vacanthotelsearch
    booksmagazinesearch
    itemcodesearch
    bookstotalsearch
    booksforeignbooksearch
    genresearch
    auctionitemsearch
    dynamicad
    cdsearch
    booksearch
    getareaclass
    hotelranking
    catalogsearch
    booksdvdsearch
    keywordhotelsearch
    itemranking
    auctionitemcodesearch
    dvdsearch
    itemsearch
    booksbooksearch
    booksgenresearch
) ) {

    can_ok( $r, $method );
}

1;
