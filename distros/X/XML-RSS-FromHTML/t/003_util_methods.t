use Test::More tests => 8;
use FindBin;
use strict;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}
my $rss = XML::RSS::FromHTML::Test->new();

# name
$rss->name('hoge');
is($rss->{name}, 'hoge');
$rss->name('with space');
is($rss->{name},'with_space');
$rss->name('012');
is($rss->{name},'012');
$rss->name(q(with 'punc's!));
is($rss->{name},'with__punc_s_');

# getDateTime
my $qr_datetime = qr/\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} \w+/;
like($rss->getDateTime,$qr_datetime);

my $dtstr;
$dtstr = 'Sun, 06 Nov 1994 08:49:37 GMT';
like($rss->getDateTime($dtstr),$qr_datetime);
$dtstr = '1994-02-03 14:15:29 -0100';
like($rss->getDateTime($dtstr),$qr_datetime);
$dtstr = '20060521';
like($rss->getDateTime($dtstr),$qr_datetime);
