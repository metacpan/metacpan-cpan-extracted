# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 6;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::Jalan');

    # these usages below are not documented in pod however.

    my $HotelSearchLite = WebService::Recruit::Jalan::HotelSearchLite->new();
    ok( ref $HotelSearchLite, 'W::R::J::HotelSearchLite->new()' );

    my $HotelSearchAdvance = WebService::Recruit::Jalan::HotelSearchAdvance->new();
    ok( ref $HotelSearchAdvance, 'W::R::J::HotelSearchAdvance->new()' );

    my $AreaSearch = WebService::Recruit::Jalan::AreaSearch->new();
    ok( ref $AreaSearch, 'W::R::J::AreaSearch->new()' );

    my $OnsenSearch = WebService::Recruit::Jalan::OnsenSearch->new();
    ok( ref $OnsenSearch, 'W::R::J::OnsenSearch->new()' );

    my $StockSearch = WebService::Recruit::Jalan::StockSearch->new();
    ok( ref $StockSearch, 'W::R::J::StockSearch->new()' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
