use strict;
use warnings;
use Test::More tests => 8;
use Test::Tk;
require Tk::ListBrowser;
require Tk::ListBrowser::Entry;

createapp;
my $ib;

if (defined $app) {
	
	#setup listbrowser widget;
	$ib = $app->ListBrowser(
		-arrange => 'list',
		-itemtype => 'text',
		-textanchor => 'w',
		-textside => 'right',
		-textjustify => 'left',
		-filterfield => 'text',

		-browsecmd => sub {
			print "browsecmd ";
			for (@_) { print  "$_ " }
			print "\n";
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


sub getall {
	my @all = $ib->getAll;
	my @nm;
	for (@all) {
		push @nm, $_->name
	}
	return \@nm;
}

sub newentry {
	my $nm = shift;
	return new Tk::ListBrowser::Entry(
		-name => $nm,
		-text => $nm,
		-listbrowser => $ib,
	);
}

push @tests, (
	[ sub { return defined $ib }, 1, 'ListBrowser widget created' ],
	[ sub {
		my $i = newentry('red');
		$ib->insert($i, 0);
		return getall;
	}, ['red'], 'red'],
	[ sub {
		my $i = newentry('yellow');
		$ib->insert($i);
		return getall;
	}, ['red', 'yellow'], 'yellow'],
	[ sub {
		my $i = newentry('green');
		$ib->insert($i, 1);
		return getall;
	}, ['red', 'green', 'yellow'], 'green'],
	[ sub {
		my $i = newentry('blue');
		$ib->insert($i, 2);
		return getall;
	}, ['red', 'green', 'blue', 'yellow'], 'blue'],
	[ sub {
		$ib->refresh;
		return 1
	}, 1, 'refresh'],
);

starttesting;

