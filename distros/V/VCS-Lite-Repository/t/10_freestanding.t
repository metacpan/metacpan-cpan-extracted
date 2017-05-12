#!/usr/bin/perl -w
use strict;

###############################################################################
# Before running this test, run the following tests:
#
# 00_clear.t - Remove ./test
# 01_basic.t - Create fresh ./test
# 03_subsidiary.t - Create test/parent, test/session1, test/session2
###############################################################################

use Test::More;
use File::Spec::Functions qw(catdir updir catfile);
use File::Find;
our @stores;

#----------------------------------------------------------------------------

BEGIN {
	require 'backends.pl';

	@stores = test_stores();
	plan tests => 1 + @stores * 12;
	#01
	use_ok 'VCS::Lite::Repository';
}

VCS::Lite::Repository->user('test');  # for tests on non-Unix platforms

# The purpose of this test is to replicate a problem found when
# a parent repository is created from scratch.
#
# This uses test/parent, blowing away the repository files underneath
# it, and re-creating the repository.
#
# This may invalidate some of tests 02_traverse.t through 06_binary.t

for (@stores) {
	print "Store $_\n";

	my $pardir = catdir("test", $_, "parent");

	{
	    local $_;	# File::Find is overwriting $_ !!
	    find ( {
	        bydepth => 1,
	        wanted => sub {
        	    return unless $File::Find::name =~ /.VCSLite/;

	            if (-d $_) {
	                rmdir $_;
	            } 
	            else {
	                1 while unlink $_;
	            }
	        } }, $pardir);
	}

	my $rep = VCS::Lite::Repository->new($pardir, store => $_);

	chdir 'test';
	chdir $_;
	
	#+01
	isa_ok($rep, 'VCS::Lite::Repository','Created new');

	#+02
	isa_ok($rep->add('mariner.txt'), 'VCS::Lite::Element', 
					'Add a text file');

	my $screp = $rep->add('scripts');

	#+03
	isa_ok($screp->add('vldiff.pl'), 'VCS::Lite::Element', 
					'Add vldiff.pl');

	#+04
	isa_ok($screp->add('vlpatch.pl'), 'VCS::Lite::Element', 
					'Add vlpatch.pl');

	#+05
	isa_ok($screp->add('vlmerge.pl'), 'VCS::Lite::Element', 
					'Add vlmerge.pl');

	my $tpath = catfile(updir,qw/t 04_repository.t/);

	#+06
	isa_ok($screp->add($tpath), 'VCS::Lite::Element', 'Add a test');

	$rep = VCS::Lite::Repository->new('parent', store => $_);
	$rep->check_in( description => 'Initial version');

	my @repc = $rep->fetch->text;

	#+07
	is_deeply(\@repc, [ qw/ mariner.txt scripts t / ], 
		"Top level contents");

	my $sess = $rep->check_out('session3', store => $_);

	#+08
	isa_ok($sess, 'VCS::Lite::Repository', 'Clone returns');

	#+09
	is( scalar($sess->contents), 3, 
		'Correct number of members before update');

	$sess->update;

	$sess = VCS::Lite::Repository->new('session3', store => $_);

	#+10
	is( scalar($sess->contents), 3, 
		'Correct number of members after update');

	#+11
	isa_ok($sess, 'VCS::Lite::Repository', 'reconstruction');

	@repc = $sess->fetch->text;

	#+12
	is_deeply(\@repc, [ qw/ mariner.txt scripts t / ], 
		"Top level contents");

	chdir updir;
	chdir updir;
}
