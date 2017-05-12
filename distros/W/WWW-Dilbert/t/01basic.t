# $Id: 01basic.t,v 1.4 2005/12/29 21:40:09 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 20 - 4;

use WWW::Dilbert qw(:all);

my $url = '';
ok($url = strip_url(),'strip_url');
ok($url =~
	m#^https?://www.dilbert.com/comics/dilbert/archive/images/dilbert\d+\.(jpg|gif)$#i,
		'strip_url results'
	);

sleep 3;

my $oldurl = $url;
ok($url = strip_url(),'strip_url again');
ok($url =~
	m#^https?://www.dilbert.com/comics/dilbert/archive/images/dilbert\d+\.(jpg|gif)$#i,
		'strip_url results again'
	);

ok($url eq $oldurl,'compare second url to first');

my @blobs = ();
ok($blobs[0] = get_strip(),'get_strip');
ok($blobs[1] = get_strip($url),'get_strip specific url');
ok($blobs[2] = get_strip($oldurl),'get_strip second specific url');
ok($blobs[0] eq $blobs[1] && $blobs[1] eq $blobs[2],'strips are the same');
ok(_image_format($blobs[0]),'blob is a gif, jpeg or png image');

my $oldW = $^W; $^W = 0;
ok(!($blobs[0] = get_strip(99999)),'get_strip non-existant');
ok(!defined($blobs[0]),'non-existant strip returns undef');
$^W = $oldW;

#ok($blobs[0] = get_strip('dilbert200512287225.jpg'),'get_strip 25/Dec/2005 jpeg strip');
#ok(_image_format($blobs[0]) eq 'jpg','blob is a jpeg image');
#
#ok(mirror_strip('foo.gif','dilbert200512287225.jpg') eq 'foo.jpg','mirror_strip dilbert200512287225.jpg to foo.jpg');
#ok(-f 'foo.jpg','foo.jpg exists');
#unlink 'foo.jpg' if -f 'foo.jpg';

ok(mirror_strip('bar') =~ /bar\.(gif|jpg)/,'mirror_strip to bar');
ok(-f 'bar.gif' || -f 'bar.jpg','mirror_strip check bar.??? file');
unlink 'bar.gif' if -f 'bar.gif';
unlink 'bar.jpg' if -f 'bar.jpg';

my $file = '';
ok($file = mirror_strip(),'mirror_strip blindly');
ok(-f $file,"check file $file exists");
unlink $file if -f $file;

sub _image_format {
	local $_ = shift || '';
	return 'gif' if /^GIF8[79]a/;
	return 'jpg' if /^\xFF\xD8/;
	return 'png' if /^\x89PNG\x0d\x0a\x1a\x0a/;
	return undef;
}

