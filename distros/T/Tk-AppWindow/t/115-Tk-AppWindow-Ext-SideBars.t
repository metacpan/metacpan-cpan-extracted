use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::SideBars');
};


createapp(
	-extensions => [qw[Art MenuBar SideBars]],
);

my $ext;
if (defined $app) {
	$ext = $app->extGet('SideBars');
	$app->geometry('640x400+100+100');
	for (qw[LEFT RIGHT TOP BOTTOM]) {
		my $panel = $_;
		$ext->nbAdd($panel, $panel, lc($panel));
		my $page = $ext->pageAdd($panel, $panel, 'edit-cut', $panel);
		$page->Label(-width => 12, -height => 8, -text => $panel)->pack(-expand => 1, -fill, 'both');
	}
}

@tests = (
	[sub { return $ext->Name eq 'SideBars' }, 1, 'extension SideBars loaded']
);

starttesting;
