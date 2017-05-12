use Test::More tests => 1;
use strict;
use FindBin;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}
my $rss = XML::RSS::FromHTML::Test->new();

# url property
$rss->url('http://iandeth.dyndns.org/');
is($rss->url,'http://iandeth.dyndns.org/');

# create local HTTP::Daemon? guess not for now...
$rss->name('Test');
#ok( $rss->getHTML($rss->url) );