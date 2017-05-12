# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 4;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::Dokoiku');

    # these usages below are not documented in pod however.

    my $searchPOI = WebService::Recruit::Dokoiku::SearchPOI->new();
    ok( ref $searchPOI, 'W::R::D::SearchPOI->new()' );

    my $getLandmark = WebService::Recruit::Dokoiku::GetLandmark->new();
    ok( ref $getLandmark, 'W::R::D::GetLandmark->new()' );

    my $GetStation = WebService::Recruit::Dokoiku::GetStation->new();
    ok( ref $GetStation, 'W::R::D::GetStation->new()' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
