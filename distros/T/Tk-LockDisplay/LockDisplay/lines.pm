sub Animation {

    # lines
    #
    # Reflect two points about the confines of the canvas.  The cool effect comes from drawing a line between the 
    # points and assigning each line a color from the (visible) spectrum.  Each line is tagged with (effectively)
    # an integer, so after N lines are drawn we begin to delete them, oldest first, maintaining N lines playing 
    # follow the leader.
    #
    # Stephen.O.Lidie@Lehigh.EDU, 98/09/20.

    my($canvas) = @_;

    if ($init) {		# if already initialized
	my $tag = 'l' . ($line_count - $max_lines);
	$canvas->delete($tag);
	foreach my $point (@points) {
	    my($x0, $y0) = ($point->[0], $point->[1]);
	    my($vx, $vy) = ($point->[2], $point->[3]);
	    my($nx, $ny) = ($x0+$vx, $y0+$vy);
	    if ($nx >= $w) {
		$nx = $w;
		$vx = -$vx;
	    } elsif ($nx <= 1) {
		$nx = 1;
		$vx = -$vx;
	    } elsif ($ny >= $h) {
		$ny = $h;
		$vy = -$vy;
	    } elsif ($ny <= 1) {
		$ny = 1;
		$vy = -$vy;
	    }
	    ($point->[0], $point->[1]) = ($nx, $ny);
	    ($point->[2], $point->[3]) = ($vx, $vy);
	}
	$tag = 'l' . $line_count++;
	$canvas->createLine($points[0][0], $points[0][1],
			    $points[1][0], $points[1][1],
			    -tags => $tag, -fill => '#' . $colors[$line_count % scalar(@colors)]);
	$canvas->lower($tag);
    } else {			# initialize 'lines' plugin
	($w, $h) = ($canvas->screenwidth, $canvas->screenheight);
	(@points) = ( [20,20, 6, 9], [580,380,-3, -5] ); # initial end points (and X/Y velocities) of the line
	$max_lines = 80;
	$line_count = 0;
	@colors = (qw/
	    ffff00000000 ffff13f80000 ffff2b020000 ffff420c0000 ffff59160000 ffff70200000 ffff872a0000 ffff9e350000
	    ffffb53f0000 ffffcc490000 ffffe3530000 fffffa5d0000 ee97ffff0000 d78cffff0000 c082ffff0000 a978ffff0000
	    926effff0000 7b64ffff0000 645affff0000 4d50ffff0000 3645ffff0000 1f3bffff0000 0831ffff0000 0000ffff0ed9
	    0000ffff25e3 0000ffff3ced 0000ffff53f7 0000ffff6b02 0000ffff820c 0000ffff9916 0000ffffb020 0000ffffc72a
	    0000ffffde34 0000fffff53f 0000f3b5ffff 0000dcabffff 0000c5a1ffff 0000ae97ffff 0000978dffff 00008083ffff
	    00006978ffff 0000526effff 00003b64ffff 0000245affff 00000d50ffff 09ba0000ffff 20c40000ffff 37cf0000ffff
	    4ed90000ffff 65e30000ffff 7ced0000ffff 93f70000ffff ab010000ffff c20c0000ffff d9160000ffff f0200000ffff
	    ffff0000f8d4 ffff0000e1ca ffff0000cac0 ffff0000b3b6 ffff00009cab ffff000085a1 ffff00006e97 ffff0000578d
	 /);		# 64 colors from my 1000 data-point "continuous spectra" file
	$init = 1;		# mark initialization complete
    }

    1000/5;			# 5 cycles/second

} # end lines animation

1;
