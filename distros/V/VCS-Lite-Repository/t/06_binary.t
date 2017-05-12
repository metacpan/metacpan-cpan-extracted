#!/usr/bin/perl -w
use strict;

###############################################################################
# Run test 00_clear.t first

# This test creates directory ./test as a repository
# and does rudimentary operations on a standalone repository.

# Note: the test directory is used by subsequent tests
###############################################################################

use Test::More;
use File::Spec::Functions qw(:ALL);
use File::Copy;

our @stores;

#----------------------------------------------------------------------------

BEGIN {
	require 'backends.pl';

	@stores = test_stores();
	plan tests => 1 + @stores * 8;

	#01
	use_ok 'VCS::Lite::Element::Binary';
}

VCS::Lite::Element::Binary->user('test'); # For tests on non-Unix platforms

for (@stores) {
	print "Store $_\n";
	
	my $bin_ele = VCS::Lite::Element::Binary->new(
		catfile("test", $_, "rook.bmp"),
		store => $_);

	chdir 'test';
	chdir $_;

	#+01
	isa_ok($bin_ele,'VCS::Lite::Element::Binary','Construction');

	#+02
	is($bin_ele->latest,0,"Latest generation of new element = 0");

	copy catfile( updir, updir, "example","rook1.bmp"), "rook.bmp";

	$bin_ele->check_in( description => 'Initial version');

	#+03
	is($bin_ele->latest,1,"Latest generation following check-in = 1");

	copy catfile( updir, updir, "example","rook2.bmp"), "rook.bmp";

	$bin_ele->check_in(description => 'Black rook');

	#+04
	is( $bin_ele->latest, 2,
		"Latest generation following second check-in = 2");

	my $lit = $bin_ele->fetch( generation => 1);

	#+05
	isa_ok($lit,'VCS::Lite',"fetch generation 1 returns");

	chdir updir;
	chdir updir;
	
	my $orig = $bin_ele->_slurp_lite(catfile(qw'example rook1.bmp'));

	#+06
	ok(!$lit->delta($orig),"Fetch returned generation 1 OK");

	$lit = $bin_ele->fetch( generation => 2);

	#+07
	isa_ok($lit,'VCS::Lite',"fetch generation 2 returns");

	$orig = $bin_ele->_slurp_lite(catfile(qw'example rook2.bmp'));

	#+08
	ok(!$lit->delta($orig),"Fetch returned generation 2 OK");

	my @txt1 = $lit->text;
	my @txt2 = $orig->text;
}
