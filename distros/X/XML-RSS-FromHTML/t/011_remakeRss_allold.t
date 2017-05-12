use Test::More tests => 9;
use strict;
use FindBin;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}

my $rss = XML::RSS::FromHTML::Test->new;
my $list = [];
my $old_list = undef;
my $old_rss = XML::RSS->new;
$old_rss->add_item(title => 'old 01', link => 'http://old/01');
$old_rss->add_item(title => 'old 02', link => 'http://old/02');
$old_rss->add_item(title => 'old 03', link => 'http://old/03');
is(scalar @{ $old_rss->{items} },3);

# all old
{
	my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
	is($cnt,0);
	is(scalar @{$new->{items}},3);
	my $path = $rss->_getFeedFilePath;
	ok(-f $path);
	is(bytes::length( $new->as_string ), -s $path);
	unlink $path;
}

# all old - with max item count
{
	$rss->maxItemCount(2);
	my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
	is($cnt,0);
	is(scalar @{$new->{items}},2);
	my $path = $rss->_getFeedFilePath;
	ok(-f $path);
	is(bytes::length( $new->as_string ), -s $path);
	unlink $path;
}
