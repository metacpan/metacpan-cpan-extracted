#!/usr/bin/perl -w
use strict;

###############################################################################
# Run test 00_clear.t first

# This test creates directory ./test as a repository
# and does rudimentary operations on a standalone repository.

# Note: the test directory is used by subsequent tests
###############################################################################

use Test::More;
use File::Spec::Functions qw(rel2abs catfile catdir curdir updir);
use IO::File;

our @stores;

#----------------------------------------------------------------------------

BEGIN {

    require 'backends.pl';

    @stores = test_stores();
    plan tests => 3 + @stores * 13;

    #01
    use_ok 'VCS::Lite::Repository';
}

VCS::Lite::Repository->user('test'); # For tests on non-Unix platforms

# Duff args

#03 - File instead of directory
eval {VCS::Lite::Repository->new('MANIFEST')};
like ($@, qr(Invalid path), "File as path croaks");

#04 - Garbage filespec in any O/S
eval {VCS::Lite::Repository->new('/\/\~~#&')};
like ($@, qr(Failed to create directory), "Invalid filespec croaks");

mkdir 'test';

for (@stores) {
	print "# Using store $_\n";
	my $rep = VCS::Lite::Repository->new(catdir('test',$_),
		store => $_);

	#+01
	isa_ok($rep, 'VCS::Lite::Repository', "Successful return from new");

	#+02
	my $hwtest = $rep->add_element('helloworld.c');
	isa_ok($hwtest, 'VCS::Lite::Element', 'add_element');

	#+03
	my @eleret = $rep->elements;
	is (@eleret,1,'elements returned one element');

	#+04
	isa_ok($eleret[0], 'VCS::Lite::Element', 
		'member of array returned by elements');

	#+05
	is($hwtest->latest,0,"Latest generation of new element = 0");

	my $wkdir = rel2abs(curdir);

	chdir 'test';
	chdir $_;

	my $hworld = <<EOF;

#include <stdio.h>

main() {

    printf("Hello World\\n");
}

EOF

	if(my $TEST = IO::File->new('helloworld.c','w+')) {
        print $TEST $hworld;
        $TEST->close;
    }

	$hwtest->check_in( description => 'Initial version');

	#+06
	is($hwtest->latest,1,"Latest generation following check-in = 1");

	$hworld =~ s/Hello World/Bonjour Le Monde/;
	if(my $TEST = IO::File->new('helloworld.c','w+')) {
        print $TEST $hworld;
        $TEST->close;
    }

	$hwtest->check_in(description => 'Change text to French');

	#+07
	is($hwtest->latest,2,"Latest generation following second check-in = 2");

	my $lit1 = $hwtest->fetch( generation => 1);

	#+08
	isa_ok($lit1,'VCS::Lite',"fetch generation 1 returns");

	my $lit2 = $hwtest->fetch( generation => 2);

	#+09
	isa_ok($lit1,'VCS::Lite',"fetch generation 2 returns");

	my $diff=$lit1->delta($lit2)->udiff;

	$diff =~ s/(@@\d+)\s/$1/g; # Fix spurious trailing blanks from udiff

	my $absfile = catfile($wkdir, 'test', $_, "helloworld.c");

	$absfile = lc $absfile if $^O =~ /VMS/i;	
		#VCS::Lite::Repository 0.06 onwards

	my $expected = <<END;
--- $absfile\@\@1
+++ $absfile\@\@2
\@\@ -6,1 +6,1 \@\@
-    printf("Hello World\\n");
+    printf("Bonjour Le Monde\\n");
END

	#+10
	is($diff,$expected,"Compare diff with expected results");

	my $foorep = $rep->add_repository('foobar');

	#+11
	isa_ok($foorep, 'VCS::Lite::Repository', "Return from add_repository");

	my @cont = $rep->contents;

	#+12
	is(@cont, 2, "Objects returned by contents");

	$rep->remove('foobar');
	@cont = $rep->contents;

	#+13
	is(@cont, 1, "Only one object after remove");

	chdir updir;
	chdir updir;
}
