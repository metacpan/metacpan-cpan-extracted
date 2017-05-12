use strict;
use warnings;

use t::Cache;
use Test::More tests => 8 * 7 + 9 + 3 * 6;
BEGIN { use_ok('WWW::Baidu'); }

#binmode \*STDOUT, ':encoding(GBK)';
#binmode \*STDERR, ':encoding(GBK)';

my $cache = t::Cache->new(
    { 'namespace'  => '01-sanity' }
);
#warn "!!! $Cache::Cache::EXPIRES_NEVER";
my $baidu = WWW::Baidu->new(cache => $cache);
my $count = $baidu->search('章亦春');
is $count, 65, 'count okay';
my @items;
while (my $item = $baidu->next) {
    push @items, $item;
}
is scalar(@items), 15, 'results count okay';

my $i = 0;
ok( $items[$i] );
is( $items[$i]->title, 'rebeccanewworld - MSN 空间网络日志汇总' );
is( $items[$i]->url, 'http://yxy.ujs.edu.cn/images/rebeccanewworld++.html' );
like( $items[$i]->summary, qr/章亦春.*?你的页面布局有些太拥挤了.*这个空间时的\.\.\./ );
is( $items[$i]->date, '2006-7-21' );
is( $items[$i]->size, '11K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*?yxy%2Eujs%2Eedu.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, 'Kid 日志汇总--Human and Machine' );
is( $items[$i]->url, 'http://www.blogchinese.com/06053/220352/archives/2006/2006634219.shtml' );
like( $items[$i]->summary, qr/章亦春 \(Agent Zhang\) 站点日历.*?应毛老师的建议.*日志汇总到了\.\.\./ );
is( $items[$i]->date, '2006-12-1' );
is( $items[$i]->size, '17K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*?blogchinese.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, '这个版还有存在的必要吗?! - 西祠胡同' );
is( $items[$i]->url, 'http://www.xici.net/b9811/d42135762.htm' );
like( $items[$i]->summary, qr/年,章亦春访问母校,校长.*?实现了一个立体几何/ );
is( $items[$i]->date, '2006-11-27' );
is( $items[$i]->size, '44K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//www%2Exici%2Enet.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, '江苏大学学报（自然科学版）ml' );
is( $items[$i]->url, 'http://www.wanfangdata.com.cn/qikan/periodical.Articles/jslgdxxb/jslg2005/0505/0505ml.htm' );
like( $items[$i]->summary, qr/章亦春等 〈文摘〉 PDF全文/ );
is( $items[$i]->date, '2006-7-12' );
is( $items[$i]->size, '14K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//www%2Ewanfangdata%2Ecom.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, '网络日志' );
is( $items[$i]->url, 'http://yz841225.spaces.live.com/blog/' );
like( $items[$i]->summary, qr/章亦春 当时班级里成绩最好的人.*?虽然他木讷,但是大方,够\.\.\./ );
is( $items[$i]->date, '2006-7-3' );
is( $items[$i]->size, '107K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//yz841225%2Espaces%2Elive.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, 'Human and Machine' );
is( $items[$i]->url, 'http://agentzh.spaces.live.com/' );
like( $items[$i]->summary, qr/章亦春 姓名: 章亦春.*?抄写 Perl 6 的核心\.\.\. / );
is( $items[$i]->date, '2006-7-22' );
is( $items[$i]->size, '45K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//agentzh%2Espaces%2Elive.*?\&user=baidu$} );
$i++;

ok( $items[$i] );
is( $items[$i]->title, '【XLS】"江苏省先进个人(学生)"' );
is( $items[$i]->url, 'http://www1.ujs.edu.cn/tzb/jsj/shehuishijian.xls' );
like( $items[$i]->summary, qr/\.\.\."院级先进个人" "27","计0304 ","谈建华".*?"徐 洁","院级先进个人"\.\.\./ );
is( $items[$i]->date, '2004-9-13' );
is( $items[$i]->size, '35K' );
is( $items[$i]->cached_url, undef );
$i++;


$i = 14;
ok( $items[$i] );
is( $items[$i]->title, '江苏大学学报（自然科学版） 2005年05期' );
is( $items[$i]->url, 'http://www.ilib.cn/Issue.aspx?P=jslgdxxb&Y=2005&I=05' );
like( $items[$i]->summary, qr/章亦春 , 徐景 , ZHAO Jun , QIU Bai-jing.*?Chun-hua , LIU Rong-gui/ );
is( $items[$i]->date, '2007-1-4' );
is( $items[$i]->size, '110K' );
like( $items[$i]->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//www%2Eilib%2Ecn.*?\&user=baidu$} );

# Test for a lot of hits
$count = $baidu->search('市 路 号');
is ($count, '4710000');

$baidu->limit(4);

my $item = $baidu->next;
ok $item, 'first one okay';
is $item->title, '100054 北京市劳动保护科学研究所 地址';
is $item->date, '2006-11-22';
is $item->size, '31K';
is $item->url, 'http://www.esd-china.com/map.htm';
like $item->summary, qr/地址:北京市宣武区陶然亭路55号.*?换59路公交车\.\.\./;

$item = $baidu->next;
is $item->url, 'http://zhidao.baidu.com/question/5395411.html';
is $item->title, '你好我想问你们上海市东方路1381号兰村大厦怎么乘公交啊,很急_百...';
like $item->summary, qr/浦东新区已解决你好我想问你们上海市东方路.*?我想问你从南汇新\.\.\./;
is $item->date, '2006-6-14';
is $item->size, '12K';
like $item->cached_url,
    qr{^http://cache.baidu.com/c\?word=.*http%3A//zhidao%2Ebaidu%2Ecom.*?\&user=baidu$};

$item = $baidu->next;
is $item->url, 'http://student.ylps.tp.edu.tw/~900153/word%A7@%AB~/4303%B3q%B0T%BF%FD.doc';
is $item->title, '【DOC】台中市五权路345号';
like $item->summary, qr/台北市中山区罗斯福路五段9号/;
is $item->date, '2005-1-4';
is $item->size, '36K';
is $item->cached_url, undef;

ok $baidu->next;
is $baidu->next, undef, 'limit is 4';

# Test for 0 hit
$count = $baidu->search('章亦秋');
is $count, 0, 'no results found';
is $baidu->next, undef, '"next" returns undef';
is $baidu->{limit}, 4, 'limit not reset';
