use strict;
use warnings;
use Test::More;

my $errstr;
eval {
    use LWP::UserAgent;
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy();
    $agent->timeout(2);
    my $url = 'http://www.baidu.com';
    my $res = $agent->get($url);
    if (! $res->is_success) {
        $errstr = $res->status_line;
        die;
    }
};
if ($@) {
    plan skip_all => "$errstr (live tests skipped)" ;
}

plan tests => 6 * 20 + 2;

use Cache::FileCache;
use WWW::Baidu;
my $cache = Cache::FileCache->new(
    { namespace          => '02-live-t',
      default_expires_in => $Cache::Cache::EXPIRES_NOW }
);
my $baidu = WWW::Baidu->new($cache);
$baidu->limit(20);
my $count = $baidu->search('Perl', 'Iraq');
ok $count > 20, 'more than 20 results returned';
my @items;
my $i = 1;
my $has_cached_url;
while (my $item = $baidu->next) {
    if ($i > 20) {
        fail('oops! limit(20) has no effect...');
        last;
    }
    ok $item->title, "item $i - title ok";
    ok $item->summary, "item $i - summary ok";
    my $s = $item->title . $item->summary;
    SKIP: {
        skip "skip a weird bug on the baidu side", 2 if $s =~ /¶«·½ºì/;
        like $s, qr/Perl/i, "item $i - 'perl' appears in the item";
        like $s, qr/Iraq/i, "item $i - 'Iraq' appears in the item";
    };
    like $item->url, qr/^\S*\w+\S*$/, "item $i - url looks okay";
    like $item->size, qr/^\d+\s*[KM]$/, "item $i - size looks good";
    if (!$has_cached_url and defined $item->cached_url) {
        like $item->cached_url, qr[^http://cache\.baidu\.com/\S*\w+\S*$], 'cached url looks good';
        $has_cached_url = 1;
    }
    $i++;
}
if (!$has_cached_url) {
    fail("weird. cached url never found :(");
}
