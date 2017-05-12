# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
    if ( ! defined $ENV{MORE_TESTS} ) {
        plan skip_all => '$MORE_TESTS is not defined';
    }
# ----------------------------------------------------------------
    plan tests => 7;
    use_ok('WebService::Hatena::BookmarkCount');
    my $list = [qw(
        http://d.hatena.ne.jp/jkondo/
        http://b.hatena.ne.jp/
        http://f.hatena.ne.jp/
    )];
    foreach my $url ( @$list ) {
        chomp $url;
        my $cnt = WebService::Hatena::BookmarkCount->getTotalCount( $url );
        ok( defined $cnt, $url );
        ok( ($cnt > 0), "$url => $cnt" );
    }
# ----------------------------------------------------------------
;1;
