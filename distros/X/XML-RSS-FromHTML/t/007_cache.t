use Test::More tests => 10;
use strict;
use FindBin;
use File::Path;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}
my $rss = XML::RSS::FromHTML::Test->new();

# list made from makeItemList()
my $list = [
	{ title => 'to link 01', link => 'http://link/01.html' },
	{ title => 'to link 02', link => 'http://link/02.html' },
	{ title => 'to link 03', link => 'http://link/03.html' },
];
my $path = $rss->_getCacheFilePath;

# cache - no update
{
	open(my $fh,'>',$path) or die $!;
	print $fh Data::Dumper::Dumper($list);
	close($fh);
	my ($update,$old_list,$size_new,$size_old) = $rss->cache($list);
	ok(!$update);
}

# cache - no cache yet, very first time called
{
	unlink $path;
	my ($update,$old_list,$size_new,$size_old) = $rss->cache($list);
	ok($update);
	is($size_new, 338);
	is($size_old, 0);
	is_deeply($old_list, undef);
}

# cache - update with new-old difference
{
	unlink $path;
	my $dummy_old = [
		{ title => 'old item', link => 'http://old/link' }
	];
	open(my $fh,'>',$path) or die $!;
	my $s = Data::Dumper::Dumper($dummy_old);
	print $fh $s;
	close($fh);
	my ($update,$old_list,$size_new,$size_old) = $rss->cache($list);
	ok($update);
	is($size_new, 338);
	is($size_old, bytes::length($s));
	is_deeply($old_list, $dummy_old);
	is(-s $path, 338);
	unlink $path;
}

