#!/usr/bin/perl -w

# Simon says:
#
#   Bastardized font opacity using alpha channels and image rub-throughs
#
#   Based on http://www.eecs.umich.edu/~addi/perl/Imager/ex_code/ex1/
#
use Imager qw(:handy);                             # load the module with shortcut macros ( NC & NF )

$fname= $ARGV[0] || "../ImUgly.ttf";

$i=Imager->new(xsize=>200,ysize=>200,channels=>4); # create image with alpha channel
$d=Imager->new(xsize=>200,ysize=>200,channels=>3); # destination image

$font=Imager::Font->new(file=>$fname);
$colour=Imager::Color->new( 0,0,0,80 );
$i->string(x=>10,y=>150,
	   size=>115,font=>$font,text=>"Img", color=>$colour, aa=>1 ); # write text with an alphaness of 80 (out of 255)

# Draw some stuff to write text overtop of
$d->flood_fill(x=>0,y=>0,color=>NC("#FFFFFF"));
$d->box(xmin=>50, ymin=>50, xmax=>150, ymax=>150, color=>NC("#FF0000"));

$d->rubthrough(src=>$i);                           # rub the noise with the alpha onto the destination
$d->rubthrough(src=>$i, tx=>10, ty=>10);           # rub the noise with the alpha onto the destination
$d->write(file=>"test.png");
