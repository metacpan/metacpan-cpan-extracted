use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;
require Tk::CodeText;

BEGIN { use_ok('Tk::CodeText::StatusBar') };

createapp;

my $text;
my $bar;
if (defined $app) {
	$text = $app->CodeText(
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
# 	$bar = $app->StatusBar(
# 		-widget => $text,
# 	)->pack(
# 		-fill => 'x',
# 	);
}

push @tests, (
	[ sub { return defined $text }, 1, 'CodeText widget created' ],
#.	[ sub { return defined $bar }, 1, 'StatusBar widget created' ],
);

starttesting;
