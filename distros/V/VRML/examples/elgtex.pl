#
# Elevationgrid with image texture
#
use VRML;

open(FILE,"<height.txt");
my @height = <FILE>;

$vrml = VRML->new(2);
$vrml
->navigationinfo(["EXAMINE","FLY"],200)
->backgroundcolor("navy")
->viewpoint("Top","1900 6000 1900","TOP")
->elevationgrid(\@height, "tex=mount.jpg", undef, undef, 250, undef, 75, undef, 0)
->save;