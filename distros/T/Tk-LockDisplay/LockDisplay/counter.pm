sub Animation {			# all plugin animation subroutines are named Animation()

    # counter
    #
    # A simple counter just to demonstrate the essential features of a LockDisplay plugin.  SOL, 98/09/19
    #
    # Simply store your file in the plugin directory, with a subroutine named Animation().  You'll note
    # that plugins have an initialization section that's executed once to preset widgets and variables.
    #
    # Stephen.O.Lidie@Lehigh.EDU, 98/09/20.

    my($canvas) = @_;		# canvas you can scribble upon

    if ($init) {		# if already initialized
	$iteration ++;		# increment counter
    } else {			# plugin initialization
	$iteration = 1;		# initialize counter
	my($w, $h) = ($canvas->screenwidth, $canvas->screenheight);
	my $l = $canvas->Label(-textvariable => \$iteration);
	$canvas->createWindow($w/2, $h/2, -window => $l);
	$init = 1;		# plugin initialization complete
    } # ifend initialization

    1;				# the plugin returns 1 if success

} # end counter animation

1;				# all require files must signal success
