use Test::More tests => 10;
use strict;
use FindBin;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}

my $rss = XML::RSS::FromHTML::Test->new;
my $list = [
	{ title => 'to link 01', link => 'http://link/01.html' },
	{ title => 'to link 02', link => 'http://link/02.html' },
	{ title => 'to link 03', link => 'http://link/03.html' },
];
my $old_list = undef;
my $old_rss = $rss->_loadOldRss;
is(scalar @{ $old_rss->{items} },0);

# completely new
{
	my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
	is($cnt,3);
	is(scalar @{ $rss->newItems },3);
	is(scalar @{$new->{items}},3);
	my $path = $rss->_getFeedFilePath;
	ok(-f $path);
	is(bytes::length( $new->as_string ), -s $path);
	unlink $path;
}

# completely new - with max item count
{
	$rss->maxItemCount(2);
	my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
	is($cnt,2);
	is(scalar @{$new->{items}},2);
	my $path = $rss->_getFeedFilePath;
	ok(-f $path);
	is(bytes::length( $new->as_string ), -s $path);
	unlink $path;
}