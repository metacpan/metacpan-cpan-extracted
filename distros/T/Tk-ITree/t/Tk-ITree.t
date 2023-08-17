use strict;
use warnings;
use Test::Tk;
use Tk;
use Test::More tests => 4;
BEGIN { use_ok('Tk::ITree') };

createapp(
);

my $it;
if (defined $app) {
	$it = $app->Scrolled('ITree',
		-scrollbars => 'osoe',
		-itemtype => 'imagetext',
		-separator => '/',
		-selectmode => 'single',
		-exportselection => 0,
	)->pack(-expand => 1, -fill => 'both');

	my @entries =(
				'colors',
		'colors/Red',
		'colors/Green',
		'colors/Blue',
		'sizes',
		'sizes/10',
		'sizes/12',
		'sizes/16',
	);

	my $img = $app->Pixmap(-file => Tk->findINC('file.xpm'));
	for (@entries) {
		$it->add($_, -image => $img, -text => $_, -itemtype => 'imagetext');
		$it->autosetmode;
	}
}

@tests = (
	[sub {  return defined $it }, '1', 'Can create']
);

starttesting;


