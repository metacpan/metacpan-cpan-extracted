#!/usr/bin/perl -w 

#
# $Id: Bbox-curve-multi-contour.t,v 1.2 2006/02/12 09:38:07 mertz Exp $
# Author: Christophe Mertz  mertz@intuilab.com, adapted from a script 
# reported by Daniel Etienne for a bug report in Tk::Zinc 3.3.0
#

use strict;

# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 4;
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
use Tk;

my $mw = MainWindow->new;
my $zinc = $mw->Zinc(-render => 1, -width => 800, -height => 500);
$zinc->pack;
like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

my $n = 8;

##  test cannot be run directly since $zinc->update does not work properly 
##  when not in a  mainloop
##  so I use a timer to trigger tests after entering the mainloop

$zinc->after(10, \&testExecute);  

Tk::MainLoop;

sub testExecute {

    # first
    my $group = $zinc->add('group', 1);
    $zinc->coords($group, [100, 250]);

    my $curve = $zinc->add('curve', $group, [],
                           -fillrule => 'nonzero',
                           -closed => 1,
                           -filled => 1,
                           -fillcolor => 'black',
                           -linecolor => 'red',
                           );
    my $arc = $zinc->add('arc', $group, [-50, -50, 50, 50]);
    $zinc->contour($curve, 'add', 1, $arc);
    $zinc->remove($arc);
    
    for (1..$n) {
        my $arc = $zinc->add('arc', $group, [-15, -70, 15, -40]);
        $zinc->rotate($arc, ($_-1)*(360/$n), 'degree');
        $zinc->contour($curve, 'add', 1, $arc);
        $zinc->remove($arc);
    }
    
    ok(&similarFlatArray ([$zinc->bbox($group)],
                          [28,178, 172, 322],   # beware this coordinates are
                          # not exactly the good one
                          [2,2,   2,2 ],
                          ),
       "bbox of left figure");
    
    
     # second
    $group = $zinc->add('group', 1);
    $zinc->coords($group, [350, 250]);
    
    $curve = $zinc->add('curve', $group, [],
                        -fillrule => 'nonzero',
                        -closed => 1,
                        -filled => 1,
                        -fillcolor => 'black',
                        -linecolor => 'red',
                        );
    $arc = $zinc->add('arc', $group, [-30, -30, 30, 30]);
    $zinc->contour($curve, 'add', 1, $arc);
    $zinc->remove($arc);
    
    for (1..$n) {
        my $arc = $zinc->add('arc', $group, [-15, -70, 15, -40]);
        $zinc->rotate($arc, ($_-1)*(360/$n), 'degree');
        $zinc->contour($curve, 'add', 1, $arc);
        $zinc->remove($arc);
    }
    &showbbox($group);
    ok(&similarFlatArray ([$zinc->bbox($group)],
                          [278,178, 422,322],   # beware this coordinates are 
                          # not exactly the good one
                          [2,2,   2,2 ],
                          ),
       "bbox of middle figure");
    
    
    # third
    $group = $zinc->add('group', 1);
    $zinc->coords($group, [600, 250]);
    
    $curve = $zinc->add('curve', $group, [],
                        -fillrule => 'nonzero',
                        -closed => 1,
                        -filled => 1,
                        -fillcolor => 'black',
                        -linecolor => 'red',
                        );
    $arc = $zinc->add('arc', $group, [-30, -30, 30, 30]);
    $zinc->contour($curve, 'add', 1, $arc);
    $zinc->remove($arc);
    $n = 3*$n;
    for (1..$n) {
        $arc = $zinc->add('arc', $group, [-5, -70, 5, -40]);
        $zinc->rotate($arc, ($_-1)*(360/$n), 'degree');
        $zinc->contour($curve, 'add', 1, $arc);
        $zinc->remove($arc);
    }
    &showbbox($group);
    ok(&similarFlatArray ([$zinc->bbox($group)],
                          [528,178, 672, 322],   # beware this coordinates are 
                          # not exactly the good one
                          [2,2,   2,2 ],
                          ),
       "bbox of right figure");
    
    diag("############## end of text test");
    exit;

}




sub showbbox {
    my @b = $zinc->bbox(shift);
#    print "bbox @b\n";
    $zinc->add('rectangle', 1, [@b],
	       -filled => 0, -linecolor => 'green', -tags => ['bbox']);
}

## ref1 is the gotten array
## ref2 is the expected array
sub similarFlatArray {
  my ($ref1, $ref2, $deltaref)= @_;
  diag ("waiting a reference for \$ref1"), return 0 unless ref ($ref1) eq 'ARRAY';
  diag ("waiting a reference for \$ref2"), return 0 unless ref ($ref2) eq 'ARRAY';
  diag ("waiting a reference for \$deltaref"), return 0 unless ref ($deltaref) eq 'ARRAY';
  
  my @array1 = @{$ref1};
  my @array2 = @{$ref2};
  my @deltaarray = @{$deltaref};
  diag ("arrays gotten, expected and deltas are not of same length,".$#array1.",".$#array2.",".$#deltaarray), return 0 
    unless ($#array1 == $#array2) and ($#array2 == $#deltaarray);
  for my $i (0.. $#array1) {
    my $a = $array1[$i];
    my $b = $array2[$i];
    my $delta = $deltaarray[$i];
    diag ("waiting a numeric value for elt $i of gotten array"), return 0 
      unless &numerical($a);
    diag ("waiting a numeric value for elt $i of expected array"), return 0 
      unless &numerical($b);
    diag ("waiting a numeric value for elt $i of deltas array"), return 0 
      unless &numerical($delta);
        
    diag ("delta > $delta between elt $i of gotten array ($a) and expected array ($b)"), return 0 
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
