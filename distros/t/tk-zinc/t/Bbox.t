#!/usr/bin/perl -w

#
# $Id: Bbox.t,v 1.9 2006/02/14 09:42:40 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
        use Test::More tests => 12;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use Tk::Zinc;
        use Tk::Font;
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
$zinc = $mw->Zinc(-width => 400, -height => 400)->pack;
like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

my $coords = [ [10,10], [40, 40] ];


my $font = $zinc->fontCreate('font20pixels', -size => -20);
#my @metrics = $zinc->fontMetrics('font20pixels');
#print "metrics = @metrics\n";
my $linespace = $zinc->fontMetrics('font20pixels', -linespace);

my $txt1 = $zinc->add('text', 1, 
                      -font => 'font20pixels',
                      -alignment => 'center',
                      #-text => 'text', # an empty text
                      -position => [30,25],
                     );
#print "bbox=(", join(',', $zinc->bbox($txt1)),")\n";

# from v3.30 the bbox of an empty text is ()
ok(&similarFlatArray ([$zinc->bbox($txt1)],
                      [],
                      [],
                     ),
   "bbox of empty text");

my $width = $zinc->fontMeasure('font20pixels', 'dummy');
#print "width = $width\n";
my $txt2 = $zinc->add('text', 1, 
                      -font => 'font20pixels',
                      -alignment => 'left',
                      -text => 'dummy',
                      -position => [200,100],
                     );
# print "bbox=(", join(',', $zinc->bbox($txt2)),")\n";

ok(&similarFlatArray ([$zinc->bbox($txt2)],
                      [200,100, 200+$width, 100+$linespace],
                      [4,4,   4,4 ],
                     ),
   "bbox of 'dummy' text");

my $txt3 = $zinc->add('text', 1, 
                      -font => 'font20pixels',
                      -alignment => 'center',
                      -text => 'dummy',
                      -position => [200,200],
                     );
# print "bbox=(", join(',', $zinc->bbox($txt3)),")\n";

ok(&similarFlatArray ([$zinc->bbox($txt3)],
                      [200,200, 200+$width, 200+$linespace],
                      [4,4,   4,4 ],
                     ),
   "bbox of 'dummy' aligned-centered text");

my $txt4 = $zinc->add('text', 1, 
                      -font => 'font20pixels',
                      -anchor => 'center',
                      -text => 'dummy',
                      -position => [200,100],
                     );
# print "bbox=(", join(',', $zinc->bbox($txt4)),")\n";

ok(&similarFlatArray ([$zinc->bbox($txt4)],
                      [200-$width/2,100-$linespace/2, 200+$width/2, 100+$linespace/2],
                      [4,4,   4,4 ],
                     ),
   "bbox of 'dummy' centered text");


### testing bbox of fields or labels of track/waypoint and tabular items
my $track = $zinc->add('track', 1, 4, -position => [56, 78]);
# print "bbox11=(", $bbox,")\n";

is($zinc->bbox(-label, $track), (),
   "bbox of a track label without labelformat is ()");

my $bbox = $zinc->bbox(-field, 0, $track);
#print "bbox22=(", $bbox,")\n";

is( $bbox, undef, "bbox of a track field without labelformat is undef");


$zinc->itemconfigure($track, -labelformat => 'x20x18+0+0');
#print "bbox=(", join(',', $zinc->bbox(-label, $track)),")\n";

$bbox = eval { $zinc->bbox(-field, 4, $track) } ;
#print "bbox=(", $bbox,")\n";

is( $bbox, (), 
    "bbox of a track field which field is out of bound is undef");

my $wpt = $zinc->add('waypoint', 1, 0, -position => [561, 781]);
#print "wpt bbox=(", join(',', $zinc->bbox($wpt)),")\n";
ok(&similarFlatArray ([ $zinc->bbox($wpt) ],
                      [ 561,781,  561,781],
                      [5,5,   5,5],
                      ),
   "coords of a waypoint without label");


my $tab = $zinc->add('tabular', 1, 1, -position => [61, 81]);
is_deeply([ $zinc->bbox($tab) ],
	  [ ],
	  "bbox of a tabular without labelformat");

#print "tab bbox=(", join(',', $zinc->bbox(-label, $tab)),")\n";
is_deeply([ $zinc->bbox(-label, $tab) ],
	  [ ],
	  "bbox of a tabular without labelformat");

#print "tab bbox=(", join(',', $zinc->bbox(-field, 0, $tab)),")\n";
is_deeply([ $zinc->bbox(-field, 0, $tab) ],
	  [ ],
	  "bbox of a tabular field without labelformat");


# $zinc->itemconfigure($tab, -labelformat => 'x20x18+0+0');
# is_deeply([ $zinc->coords($tab) ],
# 	  [ 61,81 ],
# 	  "coords of a tabular with a labelformat");




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

## ref1 is the obtained array
## ref2 is the expected array
sub similarFlatArray {
  my ($ref1, $ref2, $deltaref)= @_;
  diag ("waiting a reference for \$ref1"), return 0 unless ref ($ref1) eq 'ARRAY';
  diag ("waiting a reference for \$ref2"), return 0 unless ref ($ref2) eq 'ARRAY';
  diag ("waiting a reference for \$deltaref"), return 0 unless ref ($deltaref) eq 'ARRAY';
  
  my @array1 = @{$ref1};
  my @array2 = @{$ref2};
  my @deltaarray = @{$deltaref};
  diag ("arrays obtained, expected and deltas are not of same length,".$#array1.",".$#array2.",".$#deltaarray), return 0 
    unless ($#array1 == $#array2) and ($#array2 == $#deltaarray);
  for my $i (0.. $#array1) {
    my $a = $array1[$i];
    my $b = $array2[$i];
    my $delta = $deltaarray[$i];
    diag ("waiting a numeric value for elt $i of obtained array"), return 0 
      unless &numerical($a);
    diag ("waiting a numeric value for elt $i of expected array"), return 0 
      unless &numerical($b);
    diag ("waiting a numeric value for elt $i of deltas array"), return 0 
      unless &numerical($delta);
        
    diag ("delta > $delta between elt $i of obtained array ($a) and expected array ($b)"), return 0 
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


diag("############## bbox test");


