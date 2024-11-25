use strict;
use warnings;
use Test::More tests => 5;
use Test::Tk;
require Tk::HList;
use Tk;

BEGIN {
	use_ok('Tk::FileManager');
};

createapp;

my $fm;
if (defined $app) {
	$app->geometry('640x400+100+100');
	$fm = $app->FileManager(
	)->pack(-expand => 1, -fill => 'both');
#	$fm->load('./t/testfiles');
	$fm->load();
}

testaccessors($fm, 'cutOperation');

push @tests, (
	[ sub { return defined $fm }, 1, 'Tk::FileManager created' ],
);


starttesting;



