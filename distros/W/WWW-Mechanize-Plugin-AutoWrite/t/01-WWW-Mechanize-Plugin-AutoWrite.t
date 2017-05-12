#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 6 };

use Test::Differences;

use File::Slurp qw{ read_file };
use File::Temp  qw{ tempfile };

BEGIN {
	use_ok ( 'WWW::Mechanize' ) or exit;
}

my $mech = WWW::Mechanize->new();

my $TEST_URL  = 'http://www.cpan.org/';
my $TEST_URL2 = 'http://search.cpan.org/';

my ($fh, $TEST_TEMP_FILENAME) = tempfile();
close($fh);
diag 'tempfilename '.$TEST_TEMP_FILENAME;

#fetch the content while AutoWrite is not activated
$mech->get($TEST_URL);
my $cpan = $mech->content;

#load AutoWrite
use_ok ( 'WWW::Mechanize::Plugin::AutoWrite' ) or exit;

#check if the autowrite method is there
can_ok($mech, 'autowrite');

$mech->autowrite->file($TEST_TEMP_FILENAME);
is($mech->autowrite->file, $TEST_TEMP_FILENAME, '->autowrite set/get');
$mech->autowrite->file(undef);

#online tests
SKIP: {	
	skip 'unable to fetch '.$TEST_URL.' skipping online tests', 1 if ($mech->status != 200);
	
	unlink $TEST_TEMP_FILENAME;
	$mech->autowrite->file($TEST_TEMP_FILENAME);
	$mech->get($TEST_URL);
	
	eq_or_diff(scalar read_file($TEST_TEMP_FILENAME), $cpan, 'check if the file is created and filled properly.');

	$mech = WWW::Mechanize->new();
	$mech->autowrite->file($TEST_TEMP_FILENAME);
	$mech->get($TEST_URL2);

	unlink $TEST_TEMP_FILENAME;
	$mech->submit_form(
		'form_name' => 'f',
		'fields'    => {
			'query' => 'WWW::Mechanize::Plugin::AutoWrite',
			'mode'  => 'module', 
		},
	);

	like(scalar read_file($TEST_TEMP_FILENAME), qr{WWW-Mechanize-Plugin-AutoWrite-[0-9]}x, 'check submit search results');
}


#clean up the test file
END {
	if (defined $TEST_TEMP_FILENAME) {
		diag 'unlink '.$TEST_TEMP_FILENAME;
		unlink $TEST_TEMP_FILENAME;
	}
}
