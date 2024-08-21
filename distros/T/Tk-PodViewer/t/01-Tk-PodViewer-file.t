
use strict;
use warnings;
use Test::More tests => 5;
use Test::Tk;

BEGIN { use_ok('Tk::PodViewer') };

createapp;

my $viewer;
if (defined $app) {
	my $bf = $app->Frame->pack(-fill => 'x');
	$bf->Button(
		-text => 'Previous',
		-command => sub { $viewer->previous },
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Next',
		-command => sub { $viewer->next },
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Zoom in',
		-command => sub { $viewer->zoomIn },
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Zoom out',
		-command => sub { $viewer->zoomOut },
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Zoom reset',
		-command => sub { $viewer->zoomReset },
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$viewer = $app->PodViewer(
		-font => 'Helvetica 14',
		-fixedfontfamily => 'Hack',
	)->pack(-expand => 1, -fill => 'both');
	$app->geometry('800x600+200+200');
}

push @tests, (
	[ sub { return defined $viewer }, 1, 'PodViewer created' ],
#	[ sub {
#		my @list = $viewer->tagList;
#		for (@list) { print "$_\n" }
#		my $size = @list;
#		print "$size tags\n";
#		return 1 
#	}, 1, 'Taglist' ],
	[ sub {
		$viewer->load('t/sample.pod');
		return 1 
	}, 1, 'Pod file loaded' ],
);


starttesting;
