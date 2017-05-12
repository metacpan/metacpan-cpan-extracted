# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
    if ( ! defined $ENV{MORE_TESTS} ) {
        plan skip_all => '$MORE_TESTS is not defined';
    }
# ----------------------------------------------------------------
    plan tests => 6;
    use_ok('WebService::Hatena::BookmarkCount');
    my $src = [ grep { m#^http://# } <DATA> ];
    foreach my $num (qw( 5 10 20 40 60 )) {
        my $list = [ @$src ];   # copy
        $#$list = $num-1;
        my $hash = WebService::Hatena::BookmarkCount->getCount( @$list );
        is( (scalar @$list), (scalar keys %$hash), "multiple $num" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
#   http://b.hatena.ne.jp/entrylist?url=http://kawa.at.webry.info/&sort=count&mode=rss
#   http://b.hatena.ne.jp/entrylist?url=http://www.kawa.net/&sort=count&mode=rss
# ----------------------------------------------------------------
__END__
http://www.kawa.net/works/js/jkl/parsexml.html
http://www.kawa.net/works/perl/feedpp/feedpp.html
http://www.kawa.net/works/js/animation/cube.html
http://www.kawa.net/works/ajax/tips/mimetype/content-type.html
http://www.kawa.net/xp/index-j.html
http://www.kawa.net/works/perl/i18n-emoji/i18n-emoji.html
http://www.kawa.net/works/js/animation/raster.html
http://www.kawa.net/works/ajax/rss/rss.html
http://www.kawa.net/works/js/jkl/hina.html
http://www.kawa.net/works/ajax/ajaxtb/ajaxtb.html
http://www.kawa.net/works/js/jkl/calender.html
http://www.kawa.net/works/ajax/zip/ajaxzip.html
http://www.kawa.net/works/js/jkl/floating.html
http://www.kawa.net/works/js/jkl/resizable.html
http://www.kawa.net/works/ajax/mail/ajaxmail.html
http://www.kawa.net/works/perl/catch/news.html
http://www.kawa.net/works/perl/html/tagparser.html
http://www.kawa.net/works/perl/tips/cpan.html
http://www.kawa.net/works/perl/treepp/treepp.html
http://www.kawa.net/works/perl/phone/pnews.html
http://www.kawa.net/works/qmail/queue-fast.html
http://www.kawa.net/service/jsan/search/
http://www.kawa.net/works/js/xml/objtree.html
http://www.kawa.net/works/js/jkl/debug.html
http://www.kawa.net/works/js/data-scheme/base64.html
http://www.kawa.net/works/perl/i18n-emoji/Encode561.pm.html
http://www.kawa.net/works/jcode/uni-escape.html
http://www.kawa.net/works/ajax/ajaxcom/ajaxcom.html
http://www.kawa.net/works/js/jkl/dumper.html
http://www.kawa.net/works/ajax/rss/rss-box.html
http://www.kawa.net/works/js/jkl/date-w3cdtf.html
http://www.kawa.net/service/jsan/search/index.html
http://www.kawa.net/works/js/game/ncross.html
http://www.kawa.net/works/perl/romanize/roman-demo.html
http://www.kawa.net/works/perl/feedpp/demo.html
http://www.kawa.net/works/ajax/autoruby/autoruby.html
http://www.kawa.net/works/js/animation/raster-e.html
http://www.kawa.net/works/js/animation/cube-e.html
http://www.kawa.net/works/perl/romanize/romanize.html
http://www.kawa.net/works/js/8queens/nqueens.html
http://www.kawa.net/works/nameraka/4-points.html
http://www.kawa.net/works/greasemonkey/myscripts.html
http://kawa.at.webry.info/200605/article_1.html
http://kawa.at.webry.info/200604/article_3.html
http://kawa.at.webry.info/200604/article_15.html
http://kawa.at.webry.info/200605/article_4.html
http://kawa.at.webry.info/200604/article_5.html
http://kawa.at.webry.info/200603/article_14.html
http://kawa.at.webry.info/200605/article_9.html
http://kawa.at.webry.info/200604/article_7.html
http://kawa.at.webry.info/200602/article_8.html
http://kawa.at.webry.info/200602/article_6.html
http://kawa.at.webry.info/200605/article_10.html
http://kawa.at.webry.info/200605/article_7.html
http://kawa.at.webry.info/200511/article_9.html
http://kawa.at.webry.info/200605/article_8.html
http://kawa.at.webry.info/200603/article_5.html
http://kawa.at.webry.info/200604/article_16.html
http://kawa.at.webry.info/200603/article_12.html
http://kawa.at.webry.info/200603/article_9.html
http://kawa.at.webry.info/200605/article_3.html
http://kawa.at.webry.info/200601/article_1.html
http://kawa.at.webry.info/200602/article_2.html
http://kawa.at.webry.info/200603/article_1.html
http://kawa.at.webry.info/200602/article_15.html
http://kawa.at.webry.info/200602/article_10.html
http://kawa.at.webry.info/200602/article_4.html
http://kawa.at.webry.info/200511/article_15.html
http://kawa.at.webry.info/200604/article_1.html
http://kawa.at.webry.info/200603/article_13.html
http://kawa.at.webry.info/200602/article_11.html
http://kawa.at.webry.info/200508/article_3.html
http://kawa.at.webry.info/200511/article_14.html
http://kawa.at.webry.info/200605/article_12.html
http://kawa.at.webry.info/200604/article_13.html
http://kawa.at.webry.info/200604/article_12.html
http://kawa.at.webry.info/200604/article_9.html
http://kawa.at.webry.info/200604/article_8.html
http://kawa.at.webry.info/200604/article_14.html
http://kawa.at.webry.info/200604/article_10.html
http://kawa.at.webry.info/200604/article_4.html
http://kawa.at.webry.info/200512/article_1.html
http://kawa.at.webry.info/200603/article_11.html
http://kawa.at.webry.info/200603/article_7.html
http://kawa.at.webry.info/200601/article_3.html
http://kawa.at.webry.info/200602/article_12.html
http://kawa.at.webry.info/200602/article_13.html
http://kawa.at.webry.info/200602/article_3.html
http://kawa.at.webry.info/200511/article_5.html
http://kawa.at.webry.info/200508/article_2.html
