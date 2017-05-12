# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 2;
    BEGIN { use_ok('WebService::Hatena::AsinCount') };
# ----------------------------------------------------------------
    my $url = "http://www.hatena.ne.jp/info/webservices";
    my $hash = WebService::Hatena::AsinCount->getCount( $url );
    ok( 0 < $hash->{$url}, $url );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
