# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 4;
    BEGIN { use_ok('WebService::Hatena::BookmarkCount') };
# ----------------------------------------------------------------
    my $url = "http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%B5%BB%BD%D1%CA%B8%BD%F1";
    my $hash = WebService::Hatena::BookmarkCount->getCount( $url );
    ok( ref $hash, 'response hash' );
    my $count = $hash->{$url};
    ok( defined $count, 'response value' );
    $count ||= 0;
    ok( (0 < $count), "$url $count" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
