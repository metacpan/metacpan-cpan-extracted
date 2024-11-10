
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 12;
BEGIN { use_ok('Tk::AppWindow::Ext::Daemons') };

my $pause = 1000;

createapp(
	-extensions => [qw[Daemons]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Daemons');
}

my $count = 0;

push @tests, (
	[sub { return $ext->Name }, 'Daemons', 'extension Daemons loaded'],
	[sub {
		$ext->jobAdd('test1', 2, sub { $count ++ if $count < 12 });
		pause($pause);
		return $count 
	}, 12, 'did job'],
	[sub { return $ext->jobExists('test1') }, 1, 'jobExists'],
	[sub { return $ext->cycleActive }, 1, 'cycleActive yes'],
	[sub { return [ $ext->jobList ]}, [ 'test1' ], 'jobList'],
	[sub { 
		$ext->jobRemove('test1'); 
		return [ $ext->jobList ]
	}, [ ], 'jobRemove'],
	[sub {
		$count = 0;
		$ext->jobAdd('test2', 2, sub { $count ++ if $count < 12 });
		$ext->jobPause('test2');
		pause($pause);
		return $count 
	}, 0, 'jobPause'],
	[sub {
		$count = 0;
		$ext->jobResume('test2');
		pause($pause);
		return $count 
	}, 12, 'jobResume'],
	[sub { 
		$ext->jobRemove('test2'); 
		return $ext->cycleActive
	}, '', 'cycleActive no'],
);

starttesting;



