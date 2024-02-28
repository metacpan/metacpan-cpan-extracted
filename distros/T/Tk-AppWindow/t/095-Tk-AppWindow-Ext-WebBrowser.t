
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::WebBrowser') };


createapp(
	-configfolder => 't/settings',
	-extensions => [qw[Art WebBrowser]],
);

my $ext;
if (defined $app) {
	$ext = $app->extGet('WebBrowser');
	$app->Button(
		-text => 'Open URL',
		-command => ['cmdExecute', $app, 'browser_open', 'https://github.com/haje61/Tk-AppWindow'],
	)->pack;
}

@tests = (
	[sub { return $ext->Name }, 'WebBrowser', 'extension WebBrowser loaded']
);

starttesting;

