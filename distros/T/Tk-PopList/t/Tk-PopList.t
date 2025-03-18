
use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Tk::PopList') };

use Test::Tk;

createapp(
	-width => 300,
	-height => 200,
);

my @colors = qw(black blue brown cyan green grey magenta orange pink red violet white yellow);
my @directions = qw(up down left right);

my $poplist;
if (defined $app) {
	$app->Button(
		-command => sub  { $poplist->configure('-values', \@colors) },
		-text => 'Colors',
	)->pack(-fill => 'x');
	$app->Button(
		-command => sub  { $poplist->configure('-values', \@directions) },
		-text => 'Directions',
	)->pack(-fill => 'x');
	$app->Button(
		-command => sub  { $poplist->configure('-values', []) },
		-text => 'Empty',
	)->pack(-fill => 'x');
	my $b = $app->Button(
		-command => sub  { 
			$poplist->popUp;
		},
		-text => 'Pop list',
	)->pack(-fill => 'x');
	$poplist = $app->PopList(
# 		-relief => 'raised',
# 		-borderwidth => 2,
# 		-popdirection => 'down',
		-confine => 1,
		-filter => 1,
		-motionselect => 1,
		-values => [],
		-selectcall => sub {
			my $val = shift;
			$b->configure(-text => "Color: $val");
		},
		-widget => $b,
	);
	$app->geometry('200x200+200+200');
}

@tests = (
	[sub { return defined $poplist }, 1, 'Created PopList'],
);
starttesting;



