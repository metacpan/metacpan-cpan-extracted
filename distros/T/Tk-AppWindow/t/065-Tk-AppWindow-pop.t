
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 3;
$mwclass = 'Tk::AppWindow';

BEGIN { use_ok('Tk::AppWindow') };


createapp(
);

if (defined $app) {
	$app->Button(
		-text => 'Pop form',
		-command => sub {
			my %result = $app->popForm(
				-acceptempty => 1,
				-initialvalues => {
					color => '#0000FF',
				},
				-structure => [
					color => ['color', 'Color test'],
				],
			);
			for (sort keys %result) {
				print "$_: '", $result{$_}, "'\n";
			}
		}
	)->pack(-fill => 'x');
	$app->geometry('640x400+100+100');
}

starttesting;
