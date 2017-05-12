package SVGExtension;

#       Zinc methods, usefull at display time of Zinc code generated for SVG file
# 
#	Copyright 2003
#	Centre d'Études de la Navigation Aérienne
#
#	Author: Christophe Mertz <mertz@cena.fr>
#
# $Id: SVGExtension.pm,v 1.6 2003/10/06 15:28:15 mertz Exp $
#############################################################################

use strict;
use Carp;


use vars qw( $VERSION );

($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

# To implement SVG viewport.
# This method must be called when dispalying zinc objects, because the bbox of
# Zinc objects must be known.
## BUG: Zinc method bbox return an oversized bbox (Zinc 3.2.6h).
## So this method cannot currently be fully exact.
sub Tk::Zinc::adaptViewport {
    my ($zinc, $name, $width,$height, $viewbox, $aspectRatio) = @_;
    my($x0,$y0,$x1,$y1)=$zinc->bbox($name); 
    ($x0,$y0,$x1,$y1)=($x0+2,$y0+2,$x1-2,$y1-2); # 2 is a delta induced by zinc!
    my $dx=$x1-$x0;
    my $dy=$y1-$y0;
#    print "In adaptViewport: $name w=$width h=$height dx=$dx dy=$dy x0=$x0,y0=$y0,x1=$x1,y1=$y1\n";
    if (!$aspectRatio) {
	## simple scale should be enough!
	my ($scaleX,$scaleY) = ($width/$dx, $height/$dy);
	$zinc->scale($name, $scaleX,$scaleY);
    } else {	
	my ($minx,$miny,$portWidth,$portHeight) = split /[\s,]+/ , $viewbox;
	my ($xalign,$yalign,$meet) = $aspectRatio =~ /x(.*)Y(.*)\s+(.*)/ ;
	print "In adaptViewport: $name viewbox=$viewbox xalign=$xalign yalign=$yalign meet=$meet\n";
	if ($meet eq 'meet') {
	    ## il faut réduire la taille
	    my $scale = 1;
	    my ($scaleX,$scaleY) = ($width/$dx, $height/$dy);
	    if ($scaleX < $scaleY) {
		if ($scaleX < 1) {
		    $scale = $scaleX;
		}
	    } elsif ($scaleY < 1) {
		$scale = $scaleY;
	    }
	    print "In adaptViewport: meet scale=$scale\n";
	    $zinc->scale($name, $scale,$scale);
	    
	    my ($shiftX,$shiftY)=(0,0);
	    if ($xalign eq 'Min') {
	    } elsif ($xalign eq 'Max') {
		$shiftX = $width - $dx*$scale;
	    } elsif ($xalign eq 'Mid') {
		$shiftX = ($width - $dx*$scale)/2;
	    } else {
		print "ERROR bad aspectratio value (for X): $aspectRatio\n";
	    }
	    
	    if ($yalign eq 'Min') {
	    } elsif ($yalign eq 'Max') {
		$shiftY = $height - $dy*$scale;
	    } elsif ($yalign eq 'Mid') {
		$shiftY = ($height - $dy*$scale)/2;
	    } else {
		print "ERROR: bad aspectratio value (for Y): $aspectRatio \n";
	    }
	    $zinc->translate($name, $shiftX,$shiftY);
	} elsif ($meet eq 'slice') {
	    ## il faut clipper
	    my $scale = 1;
	    if ($dx < $width)  {
		$scale = $width/$dx;
	    }
	    if ($dy < $height) {
		my $scaleY = $height/$dy;
		if ($scaleY > $scale) {$scale=$scaleY};
	    }
	    print "In adaptViewport: slice scale=$scale\n";
	    $zinc->scale($name, $scale,$scale);
		my ($shiftX,$shiftY)=(0,0);
	    
	    if ($xalign eq 'Min') {
	    } elsif ($xalign eq 'Max') {
		$shiftX = $width - $dx*$scale;
	    } elsif ($xalign eq 'Mid') {
		$shiftX = ($width - $dx*$scale)/2;
	    } else {
		print "ERROR bad aspectratio value (for X): $aspectRatio\n";
	    }
	    
	    if ($yalign eq 'Min') {
	    } elsif ($yalign eq 'Max') {
		$shiftY = $height - $dy*$scale;
	    } elsif ($yalign eq 'Mid') {
		$shiftY = ($height - $dy*$scale)/2;
	    } else {
		print "ERROR: bad aspectratio value (for Y): $aspectRatio \n";
	    }
	    $zinc->translate($name, $shiftX,$shiftY);
	    
	    my $g=$zinc->group($name);
	    my ($tag)= $zinc->gettags($name); # there should only be one!
	    $zinc->add('group', $g, -tags => [ "sub$tag" ]);
	    $zinc->chggroup($name, "sub$tag");
	    print "clipping with [0,0, $width,$height]\n";
	    $zinc->add('rectangle', "sub$tag", [0,0, $width+1,$height+1],
		       -tags => ["clipper_sub$tag"]);
	    $zinc->itemconfigure("sub$tag", -clip => "clipper_sub$tag"); 
	}
	print "\n";
    }
}


###################################################################


1;
