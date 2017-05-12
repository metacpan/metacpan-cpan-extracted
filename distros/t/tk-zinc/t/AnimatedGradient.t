#!/usr/bin/perl -w

#
# $Id: AnimatedGradient.t,v 1.2 2005/12/02 20:59:27 mertz Exp $
# Author: Christophe Mertz  mertz@intuilab.com
#

# this test mainly does funny effects when openGL is on


# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 18;
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
my $zinc = $mw->Zinc(-width => 200, -height => 200, -backcolor => "white",
                     -render => 1)->pack;

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");


$zinc->after(10, \&proceedTests);

Tk::MainLoop;

sub proceedTests {

$zinc->add('text', 1, -position => [10,5], -text => 
"the gradient fills a rectangle 
which is clipped by the curve 
made of two circles...\n"x5);
 

my $circle1 = $zinc->add('arc', 1, [20,20,180,180]);
my $circle2 = $zinc->add('arc', 1, [70,70,130,130]);

my $curve = $zinc->add('curve', 1, [], 
                       -fillcolor => 'red', -filled => 1, -linewidth => 1);
$zinc->contour($curve, 'add', 1, $circle1);
$zinc->contour($curve, 'add', -1, $circle2);

$zinc->remove($circle1);
$zinc->remove($circle2);

my $gradient;
for (1..4) { 
  for (my $i = 0; $i <=360; $i++) {
    $gradient = "=axial $i | red | white 50 | blue";
    $zinc->itemconfigure($curve, -fillcolor => $gradient); 
    $zinc->update;
  }
}
pass("turning gradient one side");

for (1..4) {
  for (1..100) {
    $zinc->translate($curve,0.5,0.5);
    $zinc->update;
  }
  for (1..800) {
    $zinc->rotate($curve, 3.14159/400, 100,100);
    $zinc->update;
  }
  for (1..100) {
    $zinc->translate($curve,0.5,0.5);
    $zinc->update;
  }
  
  for (1..400) {
    $zinc->translate($curve,-0.5,-0.5);
    $zinc->update;
  }
  for (1..200) {
    $zinc->translate($curve,0.5,0.5);
    $zinc->update;
  }
  pass ("shaking the circle around");
}

for (1..4) { 
  for (my $i = 359; $i > 0; $i--) {
    $gradient = "=axial $i | red | white 50 | blue";
    $zinc->itemconfigure($curve, -fillcolor => $gradient); 
    $zinc->update;
  }
}
pass("turning gradient the other side");


my $gr = $zinc->add('group', 1);
my $rect = $zinc->add('rectangle', $gr, [0,-480,200,180], -filled => 1,
                      -fillcolor => "=axial 90 |blue|white 10|red 20|white 30|blue 40|white 50|red 60|white 70|blue 80|white 90|red");

$zinc->chggroup($curve, $gr);
$zinc->itemconfigure($curve, -visible => 0);

$zinc->itemconfigure($gr, -clip => $curve);


pass("displaying a translated rectangle filled with froggy colors and clipped by two circles");
for (1..2) {
  for (my $i = 0; $i<500 ; $i++) {
    $zinc->translate($rect, 0,1);
    $zinc->update;
  }
  for (my $i = 0; $i<500 ; $i++) {
    $zinc->translate($rect, 0,-1);
    $zinc->update;
  }
  pass ("a thousand translation");
}

$zinc->translate($rect, 0,250);


for (1..1000) {
  $zinc->scale($rect, 1, 0.998, 100,100);
  $zinc->update;
}
pass("a thousand scaling down");


for (1..360) {
  $zinc->rotate($rect, 3.14159/180, 100,100);
  $zinc->update;
}
pass("360 rotation of 1°");


for (1..360) {
  $zinc->rotate($rect, -3.14159/180, 100,100);
  $zinc->update;
}
pass("360 rotation of 1°");


for (1..360) {
  $zinc->rotate($rect, -3.14159/180, 100,100);
  $zinc->update;
}


for (1..1000) {
  $zinc->scale($rect, 1, 1/0.998, 100,100);
  $zinc->update;
}
pass("a thousand scaling up");



for (1..4) {
  for my $i (0..200) {
    $zinc->itemconfigure($gr, -alpha => (200-$i)/2);
    $zinc->update;
  }
  for my $i (0..200) {
    $zinc->itemconfigure($gr, -alpha => $i/2);
    $zinc->update;
  }
  pass("fade out/in in 400 steps");
}

exit;

}
