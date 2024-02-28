
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::ConfigFolder') };


createapp(
	-configfolder => 't/settings',
	-extensions => [qw[ConfigFolder]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('ConfigFolder');
}

@tests = (
	[sub { return $ext->Name }, 'ConfigFolder', 'extension ConfigFolder loaded']
);

starttesting;


