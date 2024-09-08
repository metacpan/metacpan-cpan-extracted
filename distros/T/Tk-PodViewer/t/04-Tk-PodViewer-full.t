
use strict;
use warnings;
use Test::More tests => 5;
use Test::Tk;
use Tk;
#require Tk::Pixmao;

BEGIN { use_ok('Tk::PodViewer::Full') };

createapp;

my $viewer;
if (defined $app) {
#	my $if = Tk->findINC('folder.xpm');
#	print "image $if found\n" if defined $if;
#	my $image = $app->Pixmap(-file => $if);
	$viewer = $app->PodViewerFull(
#		-nextimage => $image,
#		-previmage => $image,
#		-zoominimage => $image,
#		-zoomoutimage => $image,
#		-zoomresetimage => $image,
		-font => 'Helvetica 12',
		-fixedfontfamily => 'Courier',
	)->pack(-expand => 1, -fill => 'both');
	$app->geometry('800x600+200+200');
}


push @tests, (
	[ sub { return defined $viewer }, 1, 'PodViewerFull created' ],
	[ sub {
		$viewer->load('Tk::PodViewer');
		return 1 
	}, 1, 'Pod file loaded' ],
);


starttesting;
