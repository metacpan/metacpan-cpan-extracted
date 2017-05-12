#!/usr/bin/perl -w

#
# $Id: Text.t,v 1.2 2004/04/02 12:01:49 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 5;
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


$mw = MainWindow->new();
$zinc = $mw->Zinc(-width => 100, -height => 100);

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

# following a mail in zinc@tls.cena.fr (23 sept 2003) by A. Lemort
# we verify that the -width attribute of text items is converted as an integer
my $text = $zinc->add('text', 1, -position => [10,10], -text => "text");

&ok ($zinc->itemconfigure($text, -width => 10.1) or 1, "setting width to 10.1");
&is ($zinc->itemcget($text, -width), 10, "width attribute was converted to an integer");
&ok ($zinc->itemconfigure($text, -width => 9.9) or 1, "setting width to 10.9");
&is ($zinc->itemcget($text, -width), 9, "width attribute was converted to lower integer");



diag("############## text items test");
