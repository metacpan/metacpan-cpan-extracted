# $Id: 03basic.t,v 1.2 2006/01/10 11:38:15 nicolaw Exp $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More;

my $loops = 3;
my $perLoop = 16;
plan tests => ($perLoop*$loops)+4;

use WWW::Comic qw();

my $wc;
ok($wc = new WWW::Comic, 'new()');
ok(UNIVERSAL::isa($wc,'WWW::Comic'), '$wc isa WWW::Comic');

my @comics;
ok((@comics = $wc->comics) && @comics >= 2,
	'List of at least 2 supported comics');

my @plugins;
ok((@plugins = $wc->plugins) && @plugins >= 2,
	'List of at least 2 loaded plugins');

my @testComics;
$actualLoops = @comics > 2 ? 3 : 2;
for (1..$actualLoops) {
	my $i = int(rand(@comics));
	push @testComics, $comics[$i];

	delete $comics[$i];
	my @x;
	for (@comics) {
		push @x, $_ if defined($_);
	}
	@comics = @x;
}

for my $comic (@testComics) {
	my $url = '';
	ok($url = $wc->strip_url(comic => $comic), 'strip_url()');
	ok($url =~ m#^https?://.+\.(jpe?g|png|gif)$#i, 'URL looks sane');

	my $oldurl = $url;
	ok($url = $wc->strip_url(comic => $comic), 'strip_url() again');
	ok($url =~ m#^https?://.+\.(jpe?g|png|gif)$#i, 'URL looks sane again');

	ok($url eq $oldurl, 'compare second url to first');

	my @blobs = ();
	ok($blobs[0] = $wc->get_strip(comic => $comic),'get_strip');
	ok($blobs[1] = $wc->get_strip(comic => $comic, url => $url),'get_strip specific url');
	ok($blobs[2] = $wc->get_strip(comic => $comic, url => $oldurl),'get_strip second specific url');
	ok($blobs[0] eq $blobs[1] && $blobs[1] eq $blobs[2],'strips are the same');
	ok(_image_format($blobs[0]),'blob is a gif, jpeg or png image');

	my $oldW = $^W; $^W = 0;
	ok(!($blobs[0] = $wc->get_strip(comic => $comic, url => 'X9X9X9X9')),'get_strip non-existant');
	ok(!defined($blobs[0]),'non-existant strip returns undef');
	$^W = $oldW;

	ok($wc->mirror_strip(comic => $comic, filename => 'bar') =~ /bar\.(gif|jpg|png)$/,
		'mirror_strip to bar');
	ok(-f 'bar.gif' || -f 'bar.jpg' || -f 'bar.png',
		'mirror_strip check bar.??? file');
	for (qw(gif png jpg)) {
		unlink "bar.$_" if -f "bar.$_";
	}

	my $file = '';
	ok($file = $wc->mirror_strip(comic => $comic),'mirror_strip blindly');
	ok(-f $file,"check file $file exists");
	unlink $file if -f $file;
}

SKIP: {
	if ($actualLoops < $loops) {
		my $skipped = ($loops-$actualLoops)*$perLoop;
		skip "not enough plugins loaded for additional round of tests", $skipped;
	}
}

sub _image_format {
	local $_ = shift || '';
	return 'gif' if /^GIF8[79]a/;
	return 'jpg' if /^\xFF\xD8/;
	return 'png' if /^\x89PNG\x0d\x0a\x1a\x0a/;
	return undef;
}

