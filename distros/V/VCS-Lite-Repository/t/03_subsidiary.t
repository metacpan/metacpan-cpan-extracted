#!/usr/bin/perl -w
use strict;

###############################################################################
# Before running this test, run the following tests:
#
# 00_clear.t - Remove ./test
# 01_basic.t - Create fresh ./test/backend
###############################################################################

use Test::More;
use File::Spec::Functions qw(splitpath catdir updir catfile);
our @stores;

#----------------------------------------------------------------------------

BEGIN {
	require 'backends.pl';
	
	@stores = test_stores();
	plan tests => 2 + @stores * 17;
	
	#01
	use_ok "VCS::Lite::Repository";
}

VCS::Lite::Repository->user('test');  # for tests on non-Unix platforms

my $from = VCS::Lite::Repository->new('example');

#02
isa_ok($from, 'VCS::Lite::Repository', "Successful return from new");

for (@stores) {
	print "# Using store $_\n";

	my $parent = $from->check_out("test/$_/parent", store => $_);

	chdir 'test';
	chdir $_;

	#+01
	isa_ok($parent, 'VCS::Lite::Repository', 
		"Successful return from check_out");

	my $child1 = $parent->check_out('session1', store => $_);

	#+02
	isa_ok($child1, 'VCS::Lite::Repository', "Successful check_out of check_out");

	#+03
	is_deeply($child1->parent,$parent, "Return from parent method");

	my $child2 = $parent->check_out('session2', store => $_);

	#+04
	isa_ok($child2, 'VCS::Lite::Repository', "Successful check_out of check_out");

	#+05
	is_deeply($child2->parent,$parent, "Return from parent method");

	my $scriptdir = catdir(qw(session1 scripts));
	my $scriptrep = VCS::Lite::Repository->new($scriptdir, store => $_);

	#+06
	isa_ok($scriptrep, 'VCS::Lite::Repository', "Script directory");

	my $ele;

	chdir $scriptdir;
	for my $file (glob '*.*') {
		next if $file =~ /VCSLITE/i;	# for VMS

		$ele = VCS::Lite::Element->new($file, store => $_);

		#+07 +09 +11
		isa_ok($ele, 'VCS::Lite::Element', "Element for script $file");

		my $lit = $ele->fetch;

		#+08 +10 +12
		isa_ok($lit, 'VCS::Lite', "fetch from element $file");

		my $script = $lit->text;
		# Alter the shebang line as a test
		$script =~ s!/usr/local/bin/perl!/usr/bin/perl!;
	
		my $fil;
		open $fil,'>',$file or die "Failed to write $file, $!";
		print $fil $script;
	}

	$child1->check_in( description => 'Alter shebang lines');

	$ele = VCS::Lite::Element->new('vldiff.pl', store => $_);

	#+13
	is($ele->latest,1,"Generation has been checked in");

	$child1->commit;

	$parent->check_in( description => 'Alter shebang lines');

	chdir updir;
	chdir updir;

	my $scriptcheck = catfile(qw(parent scripts vldiff.pl));
	my $checkele = VCS::Lite::Element->new($scriptcheck, store => $_);

	#+14
	isa_ok($checkele, 'VCS::Lite::Element', "Element in parent");

	#+15
	is($checkele->latest,1,"Generation has been checked in to parent");

	my $otheredit = catfile(qw(session2 scripts vldiff.pl));
	my $fil;
	open $fil,'>>',$otheredit or die "Failed to write to $otheredit, $!";
	print $fil '# Here is another edit';
	close $fil;

	$child2->update;
	$child2->check_in( description => 'Apply changes from parent');

	$scriptcheck = catfile(qw(session2 scripts vldiff.pl));
	$checkele = VCS::Lite::Element->new($scriptcheck, store => $_);

	#+16
	isa_ok($checkele, 'VCS::Lite::Element', "Element in parent");

	#+17
	is($checkele->latest,1,"Generation has been checked in to parent");

	chdir updir;
	chdir updir;
}
