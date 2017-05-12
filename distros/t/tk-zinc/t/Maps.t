#!/usr/bin/perl -w

#
# $Id: Maps.t,v 1.1 2005/12/02 21:51:12 mertz Exp $
# Author: Christophe Mertz  mertz@intuilab.com
#

# this test mainly does funny effects when openGL is on


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
}

use strict;
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 800, -height => 600, -backcolor => "white",
                     -render => 0)->pack;

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");


$zinc->add('text', 1, -position => [10,5], -text => 
"this is a simple sample of a mapitem in TkZinc");

$zinc->after(10, \&proceedTest);

Tk::MainLoop;

sub proceedTest {
 
$zinc->mapinfo('first', 'create');

my $k = 10;
foreach (0..70) {
foreach my $j (0..80) {
  $zinc->mapinfo('first', 'add', 'line', 'simple', 1, 10, 10+$j*$k, 790, 10+$j*$k);
  $zinc->mapinfo('first', 'add', 'line', 'simple', 1, 10+$j*$k, 10, 10+$j*$k, 790);
}
}

$zinc->add('map', 1, -mapinfo => 'first');


$zinc->mapinfo('second', 'create');

$k = 30;
foreach (0..70) {
foreach my $j (0..80) {
  $zinc->mapinfo('first', 'add', 'line', 'dashed', 1, 10, 5+$j*$k, 790, 5+$j*$k);
  $zinc->mapinfo('first', 'add', 'line', 'mixed', 1, 5+$j*$k, 10, 5+$j*$k, 790);
  $zinc->mapinfo('first', 'add', 'line', 'simple', 1, 10, 5+$j*$k, 790, 5+$j*$k);
  $zinc->mapinfo('first', 'add', 'line', 'simple', 1, 5+$j*$k, 10, 5+$j*$k, 790);
}
}

$zinc->add('map', 1, -color => 'red', -mapinfo => 'second');

&pass("map is displayed");
$zinc->after(1000, sub {exit});

}


