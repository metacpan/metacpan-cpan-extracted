
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 5;
BEGIN { use_ok('Tk::AppWindow::Plugins::Geometry') };

createapp(
	-configfolder => 't/settings',
	-extensions => [qw[Plugins MenuBar]],
	-availableplugs => ['Geometry'],
	-plugins => ['Geometry'],
);

my $ext;
my $plug;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Plugins');
	$plug = $ext->plugGet('Geometry');
}

@tests = (
	[sub { return $ext->Name }, 'Plugins', 'extension Plugins loaded'],
	[sub { return $ext->plugExists('Geometry') }, 1, 'plugin Geometry loaded'],
);

starttesting;


