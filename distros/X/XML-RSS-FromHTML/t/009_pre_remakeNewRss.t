use Test::More tests => 14;
use strict;
use FindBin;
use File::Path;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}

my $list = [
	{ title => 'to link 01', link => 'http://link/01.html' },
	{ title => 'to link 02', link => 'http://link/02.html' },
	{ title => 'to link 03', link => 'http://link/03.html' },
];

# passthru
{
	my $rss = XML::RSS::FromHTML::Test->new();
	$rss->passthru({ version => '2.0' });
	my $new = new XML::RSS(%{ $rss->passthru });
	is($new->{version},'2.0');
}

# addNewItem
{
	my $rss = XML::RSS::FromHTML::Test->new();
	my $new = new XML::RSS;
	ok( $rss->addNewItem($new,$list->[0]) );
	is($new->{items}[0]->{description},'this is to link 01');
	ok( $rss->addNewItem($new,$list->[1]) );
	is($new->{items}[1]->{link},'http://link/02.html');
}

# defineRSS
{
	my $rss = XML::RSS::FromHTML::Test->new();
	my $new = new XML::RSS;
	$rss->defineRSS($new);
	is($new->{channel}{title},'ほげほげフィード');  # japanese text
	is($new->{channel}{description},'foo bar');
	is($new->{image}{url},'http://mysite/rss/feed.png');
}

# saveToFile
{
	my $rss = XML::RSS::FromHTML::Test->new();
	my $new = new XML::RSS;
	my $path = $rss->_getFeedFilePath;
	unlink $path;
	$rss->addNewItem($new,$list->[0]);
	$rss->addNewItem($new,$list->[1]);

	# without specified filename
	ok( $rss->_saveToFile($new) );
	ok(-f $path);
	is(bytes::length($new->as_string), -s $path);
	unlink $path;

	# with specified out filename
	$rss->outFileName('hogehoge');
	ok( $rss->_saveToFile($new) );
	my $path2 = $rss->_getFeedFilePath;
	$path2 =~ s/Test\.xml$/hogehoge\.xml/;
	ok(-f $path2);
	is bytes::length($new->as_string), -s $path2;
    #unlink $path2;
}
