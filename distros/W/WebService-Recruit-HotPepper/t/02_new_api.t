# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 3;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::HotPepper');
    my $api = WebService::Recruit::HotPepper::GourmetSearch->new();
    ok ref $api;
    $api = WebService::Recruit::HotPepper::ShopSearch->new();
    ok ref $api;
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
