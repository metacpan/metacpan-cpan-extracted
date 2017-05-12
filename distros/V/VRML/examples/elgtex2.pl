#
# Elevationgrid with colors and transparency mask
# Attention: there are different results with CosmoPlayer and WorldView
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
->elevationgrid(\@height, [\@color,"white;tex=circle.gif"], undef, undef, 250, undef, 75, undef, 0)
->save;