#!/usr/bin/perl -w

#
# $Id: PreviousKnownBugs.t,v 1.3 2004/04/02 12:01:49 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 2;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use Tk::Zinc;
 	1;
    }) {
        print "unable to load Tk::Zinc";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
 	MainWindow->new();
 	1;
    }) {
        print "# tests only work properly when it is possible to create a mainwindow in your env\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}

#use Tk::Zinc;

$mw = MainWindow->new();
$zinc = $mw->Zinc(-width => 100, -height => 100);

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

# following bug detected by A. Lemort
my $curve = $zinc->add('curve', 1, [[0, 0], [0, 100, 'c'], [100,100, 'c'], [100, 0]]) ;
$zinc->coords($curve,  [[500,0], [500, 100], [600, 100], [600, 0]]);

my @coords = $zinc->coords($curve,0);


is_deeply([ @coords ],
          [ [500,0], [500, 100], [600, 100], [600, 0] ],
          "lemort bug 17 sept 2003 v3.2.94; testing correct value");



diag("############## all known bugs");
