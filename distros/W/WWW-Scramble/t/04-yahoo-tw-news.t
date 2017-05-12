#!perl -T
use utf8;
use Test::More skip_all => "network";
#use Test::More tests => 3;
use WWW::Scramble;

BEGIN {
        my $scrab = WWW::Scramble->new();
        my $entry = $scrab->fetchnews('http://tw.news.yahoo.com/article/url/d/a/090817/4/1p7dx.html');
        isa_ok ( $entry , 'WWW::Scramble::Entry' );
        is ($entry->title->as_trimmed_text, '韓國救難隊 嗅覺如搜救犬般靈敏', 'Check title');
        like ($entry->content->as_trimmed_text, qr/六龜鄉/, 'Check content');
}

diag( "Testing Yahoo!TW News" );
