#
# Elevationgrid with color per height
#
use VRML;

open(FILE,"<height.txt");
my @height = <FILE>;
open(COL,"<color.txt");
my @color = <COL>;

$vrml = VRML->new(2);
$vrml
->navigationinfo(["EXAMINE","FLY"],200)
->backgroundcolor("navy")
->viewpoint("Top","1900 6000 1900","TOP")
->elevationgrid(\@height, \@color, undef, undef, 250, undef, 75, 1)
->save;