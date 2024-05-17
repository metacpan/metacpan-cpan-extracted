
use strict;
use warnings;
use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Help') };


createapp(
	-extensions => [qw[Art MenuBar Help]],
	-helpfile => 't/sample_help.pod',
#	-helpfile => 'https://www.google.com',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Help');
}

@tests = (
	[sub { return $ext->Name }, 'Help', 'extension Help loaded']
);

starttesting;


