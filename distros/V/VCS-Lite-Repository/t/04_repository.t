#!/usr/bin/perl -w
use strict;

###############################################################################
# Before running this test, run the following tests:
#
# 00_clear.t - remove ./test
# 01_clear.t - create fresh ./test/backend
# 03_subsidiary.t - create repositories test/backend/parent etc.
###############################################################################

use Test::More;
use File::Spec::Functions qw(catdir catfile updir rel2abs);
use File::Copy;

our @stores;

#----------------------------------------------------------------------------

BEGIN {
	require 'backends.pl';

	@stores = test_stores();
	plan tests => 1 + @stores * 21;
	
	#01
	use_ok 'VCS::Lite::Repository';
}

VCS::Lite::Repository->user('test');  # for tests on non-Unix platforms

my $testfile = rel2abs(catfile(qw! t 04_repository.t !));


for (@stores) {
	diag "# Store $_\n";

	my $child1 = VCS::Lite::Repository->new(
        catdir('test',$_,'session1'),
		store => $_
    );
	
	chdir 'test';
	chdir $_;

	#+01
	isa_ok($child1, 'VCS::Lite::Repository', "session1 still available from previous tests");

	my $child2 = VCS::Lite::Repository->new(
        'session2',
		store => $_
    );

	#+02
	isa_ok($child2, 'VCS::Lite::Repository', "session2 still available from previous tests");

	chdir 'session1';

	my $testrep = $child1->add_repository('t');

	#+03
	isa_ok($testrep, 'VCS::Lite::Repository', "add_repository return");

	my $testele = $testrep->add('04_repository.t');

	#+04
	isa_ok($testele, 'VCS::Lite::Element', "add return");

	copy($testfile,'t');

	my $scriptrep = VCS::Lite::Repository->new(
        'scripts',
		store => $_
    );

	#+05
	isa_ok($scriptrep, 'VCS::Lite::Repository', "Script directory");

	#+06
	ok($scriptrep->remove('vlmerge.pl'), "remove");

	chdir updir;
	$child1 = VCS::Lite::Repository->new(
        'session1',
		store => $_
    );

	#+07
	isa_ok($child1, 'VCS::Lite::Repository', "Read back repository");

	$child1->check_in( description => 'Test add and remove');

	my @cont1 = $child1->contents;

	#+08
	is(@cont1, 3, "contents returns 3 objects");

	chdir 'session1';
	$testrep = VCS::Lite::Repository->new(
        't',
		store => $_
    );

	#+09
	isa_ok($testrep, 'VCS::Lite::Repository', "test repository still there");

	my @test1 = $testrep->contents;

	#+10
	is(@test1, 1, "contents returns 1 object");

	$scriptrep = VCS::Lite::Repository->new(
        'scripts',
		store => $_
    );

	#+11
	isa_ok($scriptrep, 'VCS::Lite::Repository', "script repository still there");

    TODO: {
        local $TODO = 'Incomplete tests';
        todo_skip $TODO, 10;
     
        my @script1 = $scriptrep->contents;

        #+12
        is(@script1, 2, "contents returns 2 objects");

        $child1->commit;

        chdir updir;

        my $parent = VCS::Lite::Repository->new(
            'parent',
            store => $_
        );

        $parent->check_in( description => 'Test add and remove');

        my @contp = $child1->contents;

        #+13
        is(@contp, 3, "contents returns 3 objects");

        chdir 'parent';
        $testrep = VCS::Lite::Repository->new(
            't',
            store => $_
        );

        #+14
        isa_ok($testrep, 'VCS::Lite::Repository', "test repository in parent");

        my @testp = $testrep->contents;

        #+15
        is(@testp, 1, "contents returns 1 object");

        $scriptrep = VCS::Lite::Repository->new(
            'scripts',
            store => $_
        );

        #+16
        isa_ok($scriptrep, 'VCS::Lite::Repository', "script repository in parent");

        my @scriptp = $scriptrep->contents;

        #+17
        is(@scriptp, 2, "contents returns 2 objects");

        $child2->update;
        $child2->check_in( description => 'Test add and remove');

        chdir updir;

        $child2 = VCS::Lite::Repository->new(
            'session2',
            store => $_
        );

        chdir 'session2';

        $testrep = VCS::Lite::Repository->new('t', store => $_);

        #+18
        isa_ok($testrep, 'VCS::Lite::Repository', "test repository in session2");

        my @test2 = $testrep->contents;

        #+19
        is(@test2, 1, "contents returns 1 object");

        $scriptrep = VCS::Lite::Repository->new(
            'scripts',
            store => $_
        );

        #+20
        isa_ok($scriptrep, 'VCS::Lite::Repository', "script repository in session2");

        my @script2 = $scriptrep->contents;

        #+21
        is(@script2, 2, "contents returns 2 objects");

        $child2->commit;
    }

    chdir updir;
    chdir updir;
    chdir updir;
}
