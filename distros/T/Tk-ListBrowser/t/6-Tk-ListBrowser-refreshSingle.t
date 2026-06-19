use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
require Tk::ListBrowser;
require Tk::ListBrowser::Entry;

createapp;
my $ib;

if (defined $app) {
	
	#setup listbrowser widget;
	$ib = $app->ListBrowser(
#		-arrange => 'hlist',
		-arrange => 'tree',
		-itemtype => 'text',
		-selectmode => 'multiple',
		-separator => '.',
		-textanchor => 'w',
		-textjustify => 'left',
		-filterfield => 'text',

		-browsecmd => sub {
			my $e = shift;
			$ib->refreshSingle($e);
		},
		-command => sub {
			print "command ";
			for (@_) { print  "$_ " }
			print "\n";
		},
	)->pack(-expand =>1, -fill => 'both');

	#setup columns

	$app->geometry('500x600+200+200');
}

my @dataset = (
	'first',
	'first.red',
	'first.red.light',
	'first.green',
	'second',
);

push @tests, (
	[ sub { return defined $ib }, 1, 'ListBrowser widget created' ],
	[ sub {
		for (@dataset) {
			$ib->add($_, -text => $_)
		}
		$ib->refresh;
		return 1
	}, 1, 'Data loaded' ],

);

starttesting;

