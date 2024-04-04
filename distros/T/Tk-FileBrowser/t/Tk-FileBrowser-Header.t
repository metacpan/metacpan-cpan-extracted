use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
require Tk::HList;
use Tk;

BEGIN {
	use_ok('Tk::FileBrowser::Header');
};

createapp;

my $hd;
if (defined $app) {
	$app->geometry('640x400+100+100');

	my $list = $app->Scrolled('HList',
		-columns => 1,
		-header => 1,
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	$hd = $list->Header(
		-column => 0,
		-text => 'Header',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
	$list->headerCreate(0, -itemtype => 'window', -widget => $hd);
}

push @tests, (
	[ sub { return defined $hd }, 1, 'Header widget created' ],
);


starttesting;



