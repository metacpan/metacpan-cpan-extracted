
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Balloon') };


createapp(
	-extensions => [qw[Balloon]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Balloon');
}

@tests = (
	[sub { return $ext->Name }, 'Balloon', 'extension Balloon loaded']
);

starttesting;

