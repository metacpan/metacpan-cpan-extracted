#!/usr/bin/perl -w

#
# $Id: Transformations.t,v 1.3 2004/04/02 12:03:34 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 21;
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
my $coords = [ [10,10], [40, 40] ];

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

my $g = $zinc->add('group',1);
$zinc->scale($g,2,2);
my $rect1 = $zinc->add('rectangle', $g, [10,10,40,40]);

# todo : add a test for the to-come method to get a transform!

is_deeply([ $zinc->coords($rect1) ],
	  [ [10,10], [40, 40] ],
	  "coords are not modified by the group transform!");

is_deeply([
	   $zinc->transform(1, $g, [100, 100, 300, 500] )
	    ],
	  [ 50, 50, 150, 250 ],
	  "transform from window coordinates to group"); 

is_deeply([
	   $zinc->transform($g, 1, [$zinc->coords($rect1)] )
	    ],
	  [ [20,20], [80, 80] ],
	  "transform to window coordinates"); 


# question suggested by D. Etienne (30 sept 2003):
# is it possible to get the window coordinate of a transformed item?
# the answer is of course yes and it is verified here.
my $rect2 = $zinc->add('rectangle', 1, [10,10,40,40]);

# applying a transform to the rectangle:
$zinc->scale($rect2, 2,2);

# todo : add a test for the to-come method to get a transform!

is_deeply([ $zinc->coords($rect1) ],
	  [ [10,10], [40, 40] ],
	  "coords are not modified by the item transform!");

is_deeply([
	   $zinc->transform(1, $rect2, [100, 100, 300, 500] )
	    ],
	  [ 50, 50, 150, 250 ],
	  "transform window coordinates with same transform than rect2 "); 
is_deeply([
	   $zinc->transform($rect2, 1, [$zinc->coords($rect2)] )
	    ],
	  [ [20,20], [80, 80] ],
	  "transform rect2 coordinates to window coordinates, with group 1"); 

is_deeply([
	   $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
	    ],
	  [ [20,20], [80, 80] ],
	  "transform rect2 coordinates to window coordinates with 'device'"); 

$zinc->scale(1, 0.5, 0.5);

is_deeply([
	   $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
	    ],
	  [ [10,10], [40, 40] ],
	  "transform rect2 coordinates to window coordinates with 'device'"); 

# setting the top group transformation to the id, with a translation with tset
$zinc->tset(1,   1,0, 0,1, -20,-10);
is_deeply([
	   $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
	    ],
	  [ [0,10], [60, 70] ],
	  "rect2 window coordinates with 'device' after topgroup transfo setting"); 

# restting top group transformation
$zinc->treset(1);
is_deeply([
	   $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
	    ],
	  [ [20,20], [80, 80] ],
	  "rect2 window coordinates with 'device' after topgroup treset"); 

# resetting the rect2 trasnformation
$zinc->treset($rect2);
is_deeply([
	   $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
	    ],
	  [ [10,10], [40, 40] ],
	  "rect2 window coordinates with 'device' after rect2 treset"); 

$zinc->treset($rect2);
$zinc->skew($rect2, 10,00);
$zinc->skew($rect2, -10,00);
ok(&similarPoints ([
                    $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
                   ],
                   [ [10, 10], [40, 40] ]),
   "rect2 window coordinates with 'device' after rect2 skew (back and forth)");


$zinc->treset($rect2);
$zinc->skew($rect2, -10,00);
$zinc->skew($rect2, 10,00);
ok(&similarPoints ([
                    $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
                   ],
                   [ [10, 10], [40, 40] ]),
   "rect2 window coordinates with 'device' after rect2 skew (forth and back)");


$zinc->treset($rect2);
$zinc->translate($rect2, 34,43);
$zinc->translate($rect2, 15,15, 'absolute'); # the previous relative translation will be overridden
is_deeply([
           $zinc->transform($rect2, 'device', [$zinc->coords($rect2)] )
          ],
	  [ [25,25], [55, 55] ],
	  "rect2 window coordinates with 'device' after rect2 absolute translation"); 

if (0) {
$zinc->treset($rect2);
print "0     ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 3.14159);
print "+3.14 ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, -3.14159, 0);
print "0     ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 180, 1);
print "180   ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, -3.14159, 100, 200);
print "0     ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, -3.14159, 0, 100, 200);
print "3.14  ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 180, 1, 100, 200);
print "0     ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 180, 1, 100, 200, 300);
print "3.14  ", $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 180, 1, 100, 200, 300, 600);
print $zinc->tget($rect2, 'rotation'), "\n";
$zinc->rotate($rect2, 180, 1, 100, 200, 300, 600, 900);
print $zinc->tget($rect2, 'rotation'), "\n";
}

$zinc->treset($rect2);
$zinc->translate($rect2, 40,50);
$zinc->scale($rect2, 2,3);
$zinc->rotate($rect2, 3.1415/2);

my ($m00, $m01, $m10, $m11, $m20, $m21) = $zinc->tget($rect2);
#print "matrix: $m00, $m01, $m10, $m11, $m20, $m21\n";
ok(&similarFlatArray ([$zinc->tget($rect2)],
                      [0,     2,     -3,    0,     -150, 80],
                      [0.001, 0.001, 0.001, 0.001, 1,    1]),
   "tget of rect2");

my ($xTranslate, $yTranslate, $xScale, $yScale, $angle, $skew) = $zinc->tget($rect2, 'all');
#print "matrix: $xTranslate, $yTranslate, $xScale, $yScale, $angle, $skew\n";
ok(&similarFlatArray ([$zinc->tget($rect2,'all')],
                      [-150,   80,     2,     3,  3.14159/2, 0    ],
                      [1,       1, 0.001, 0.001,  0.001,     0.001]),
   "tget 'all' of rect2");


($xTranslate, $yTranslate) = $zinc->tget($rect2, 'translation');
#print "translate: $xTranslate, $yTranslate\n";
ok(&similarFlatArray ([$zinc->tget($rect2,'translation')],
                      [-150,   80],
                      [1,      1 ]),
   "tget 'translation' of rect2");

($xScale, $yScale) = $zinc->tget($rect2, 'scale');
#print "scale: $xScale, $yScale\n";
ok(&similarFlatArray ([$zinc->tget($rect2,'scale')],
                      [2,     3,   ],
                      [0.001, 0.001]),
   "tget 'scale' of rect2");

($m00, $m01, $m10, $m11, $m20, $m21) = $zinc->tget($rect2, 'rotation');
ok(&similarFlatArray ([$zinc->tget($rect2,'rotation')],
                      [3.14159/2],
                      [0.001    ]),
   "tget 'rotation' of rect2");

#$zinc->skew($rect2, 10,0);
ok(&similarFlatArray ([$zinc->tget($rect2,'skew')],
                      [0],
                      [0.001    ]),
   "tget 'skew' of rect2");


sub similarPoints {
  my ($ref1, $ref2)= @_;
  diag ("waiting a reference for \$ref1" . ref ($ref1)), return 0 unless ref ($ref1) eq 'ARRAY';
  diag ("waiting a reference for \$ref2"), return 0 unless ref ($ref2) eq 'ARRAY';

  my @array1 = @{$ref1};
  my @array2 = @{$ref2};

  diag ("arrays for \$ref1 and \$ref2 are not of same length"), return 0 
    unless scalar @array1 == @array2;

  for my $i (0.. $#array1) {
    my $pt1 = $array1[$i];
    my $pt2 = $array2[$i];
    diag ("waiting a reference to a point in elt $i \$ref1"), return 0 
      unless ref $pt1 eq 'ARRAY';
    my (@pt1) = @{$pt1};
    diag ("waiting a reference to a point (x,y) in elt $i \$ref1"), return 0 
      unless scalar @pt1 == 2 and &numerical($pt1[0]) and &numerical($pt1[1]) ;
    
    diag ("waiting a reference to a point in elt $i \$ref1"), return 0 
      unless ref $pt2 eq 'ARRAY';
    my (@pt2) = @{$pt2};
    diag ("waiting a reference to a point (x,y) in elt $i \$ref2"), return 0 
      unless scalar @pt2 == 2 and &numerical($pt2[0]) and &numerical($pt2[1]) ;
    
    diag ("delta > 0.001 between x of pt$i"), return 0 if abs($pt1[0]-$pt2[0]) > 0.001;
    diag ("delta > 0.001 between y of pt$i"), return 0 if abs($pt1[1]-$pt2[1]) > 0.001;
  }
  return 1;
}

sub similarFlatArray {
  my ($ref1, $ref2, $deltaref)= @_;
  diag ("waiting a reference for \$ref1"), return 0 unless ref ($ref1) eq 'ARRAY';
  diag ("waiting a reference for \$ref2"), return 0 unless ref ($ref2) eq 'ARRAY';
  diag ("waiting a reference for \$deltaref"), return 0 unless ref ($deltaref) eq 'ARRAY';
  
  my @array1 = @{$ref1};
  my @array2 = @{$ref2};
  my @deltaarray = @{$deltaref};
  diag ("arrays for \$ref1 and \$ref2 and \$deltaref are not of same length,".$#array1.",".$#array2.",".$#deltaarray), return 0 
    unless ($#array1 == $#array2) and ($#array2 == $#deltaarray);
  for my $i (0.. $#array1) {
    my $a = $array1[$i];
    my $b = $array2[$i];
    my $delta = $deltaarray[$i];
    diag ("waiting a numeric value for elt $i of \$ref1"), return 0 
      unless &numerical($a);
    diag ("waiting a numeric value for elt $i of \$ref2"), return 0 
      unless &numerical($b);
    diag ("waiting a numeric value for elt $i of \$deltaref"), return 0 
      unless &numerical($delta);
        
    diag ("delta > $delta between elt $i of \$ref1 ($a) and \$ref2 ($b)"), return 0 
      if (abs($a-$b) > $delta) ;
  }
  return 1;
}


sub numerical {
  my ($v) = @_;
  return 0 unless defined $v;
  ### this really works!!
  return $v eq $v*1;
  }


diag("############## transformations test");


