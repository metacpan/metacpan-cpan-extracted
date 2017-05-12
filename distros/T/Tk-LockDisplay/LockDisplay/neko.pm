
use File::Basename;
use POSIX qw/acos atan2/;
use subs qw/do_awake do_move do_sleep do_stop do_togi frame init_plug position_to_heading set_state stopped/;
use vars qw/$akubi_time $awake_time $canvas $close_enough $debug %dxdy $init $jare_time $kaki_time $maxx $maxy $nx
    $ny $pi $pix $pixbits @pixlist %pixmaps $r2d $state %states $state_count $stop_time $togi_time $velocity $x $y
    $where/;
use strict;

sub Animation {

    # neko
    #
    # A Tk::LockDisplay plugin that emulates Masayuki Koba's xneko game.  This "mainloop" dispatches control to
    # one of 5 state processors, each of which displays pixmaps based on the state's cycle count.
    #
    # Stephen.O.Lidie@Lehigh.EDU, 98/10/20.

    $canvas = $_[0];

    if ($init) {		# if plugin already initialized

	$where = sprintf("state=%s, nx/ny=%d/%d", $state, $nx, $ny) if $debug;
	$state_count++;		# current state's cycle count
      STATES:
	foreach my $regex (keys %states) {
	    next STATES unless (my $match) = $state =~ /^$regex$/;
	    &{$states{$regex}}($match);
	    return 1;		# success
	}
	print STDERR "Illegal neko state=$state!\n";
	return 0;		# fail

    } else {	

	init_plug;		# plugin initialization
	return 1000/10;		# animate with a frequency of 10 cycles/second

    }

} # end neko Animation

sub frame {

    # Display a frame unless it's already visible.

    my($frame) = @_;

    return if $pix eq "$frame.ppm";
    $canvas->coords($pixmaps{$pix}, -1000, -1000);
    $pix = "$frame.ppm";
    $canvas->coords($pixmaps{$pix}, $nx, $ny);

} # end frame

sub init_plug {

    $debug = 0;
    my $base = Tk->findINC('LockDisplay/images');
    my $cursor = $^O eq 'MSWin32' ? 'mouse' : ["\@$base/mouse.xbm", "$base/mouse.mask", qw/black white/];
    $canvas->configure(-background => 'white', -cursor => $cursor);
    $canvas->idletasks;
    $canvas->createWindow(300, 300, -window => $canvas->Label(-textvariable => \$where)) if $debug;
    
    $pi = acos(-1);		# pi
    $r2d = 180.0 / $pi;		# radians to degrees
    ($maxx, $maxy) = ($canvas->screenwidth, $canvas->screenheight); # display size
    ($nx, $ny) = ($maxx/2, $maxy/2 + 80); # current neko position
    $velocity = 10;		# in pixels/cycle
    $canvas->createWindow($nx, $ny - 35, -window => $canvas->Scale(qw/-background white -from 0 -to 20
        -showvalue 1 -resolution 1 -orient horizontal -relief flat -font fixed -highlightthickness 0 
        -variable/ => \$velocity),
    );
    $canvas->idletasks;
    $close_enough = 5;		# neko has caught mouse if within this pixel distance
    %dxdy = (
        LEFT    => [-1,  0],
	RIGHT   => [+1,  0],
        UP      => [ 0, -1],
        DOWN    => [ 0, +1],
        DWLEFT  => [-1, +1],
        DWRIGHT => [+1, +1],
        UPLEFT  => [-1, -1],
        UPRIGHT => [+1, -1],
    );				# x/y pixel delta multipliers
    $pix = '';			# currently displayed Pixmap
    $pixbits = 16;		# 0.5 Pixmap size in bits
    $state = '';		# current game state
    %states = (
        'NEKO_(AWAKE)' => \&do_awake,
        'NEKO_(UP|UPRIGHT|RIGHT|DWRIGHT|DOWN|DWLEFT|LEFT|UPLEFT)' => \&do_move,
        'NEKO_(STOP)' => \&do_stop,
        'NEKO_(UTOGI|RTOGI|DTOGI|LTOGI)' => \&do_togi,
        'NEKO_(SLEEP)' => \&do_sleep,
    );				# neko state table
    $state_count = 0;		# current state's cycle count
    set_state 'NEKO_AWAKE';
    $akubi_time =  3 * 2;	# yawn cycles
    $awake_time =  3 * 2;	# awake cycles
    $jare_time  = 10 * 2;	# stomp cycles
    $kaki_time  =  4 * 2;	# scratch neko cycles
    $stop_time  =  4 * 2;	# stop cycles
    $togi_time  = 10 * 2;	# scratch wall cycles

    # Load and momentarily display Pixmaps (probably poor Japanese translations my own).
    #
    # Icon        - neko icon
    # awake       - freshly awake
    # down1       - south #1
    # down2       - south #2
    # dtogi1      - south wall scratch #1
    # dtogi2      - south wall scratch #2
    # dwleft1     - southwest #1
    # dwleft2     - southwest #2
    # dwright1    - southeast #1
    # dwright2    - southeast #2
    # jare2       - stopped #2 (stomp ground)
    # kaki1       - scratch #1
    # kaki2       - scratch #2
    # left1       - west #1
    # left2       - west #2
    # ltogi1      - west wall scratch #1
    # ltogi2      - west wall scratch #2
    # mati2       - stopped #1
    # mati3       - yawn
    # rtogi1      - east wall scratch #1
    # rtogi2      - east wall scratch #2
    # sleep1      - sleep #1
    # sleep2      - sleep #2
    # north1      - north #1
    # north2      - north #2
    # upleft1     - northwest #1
    # upleft2     - northwest #2
    # upright1    - northeast #1
    # upright2    - northeast #2
    # utogi1      - north wall scratch #1
    # utogi2      - north wall scratch #2

    my $x = 40;
    my $y = 30;
    my $i = $canvas->createText(120, 20, -fill => 'black', -text => "Loading pixmaps ...");
    my $n = 1;
    foreach my $pfn ( <$base/*.ppm> ) {
	my $bpfn = basename $pfn;
	$pixmaps{$bpfn} = $canvas->createImage($x, $y, -image => $canvas->Photo(-file => $pfn));
	$canvas->idletasks;
	$x += 35;
	if ($n++ >= 8 or $bpfn eq 'Icon.ppm') {
	    $y += 50;
	    $x  = 40;
	    $n = 1;
	}
    } # forend all Pixmaps
    
    # Hide Pixmaps off-canvas until we need them.
    
    $canvas->delete($i);
    $canvas->after(1000);
    foreach my $pxid (keys %pixmaps) {
	$canvas->coords($pixmaps{$pxid}, -1000, -1000);
	$canvas->after(50);
	$canvas->idletasks;
    }
    
    $init = 1;

} # end init_plug

sub position_to_heading {

    # Swiped and modified from my TclRobots entry #2, position_to_heading() determines the direction (as one of
    # eight cardinal compass points) from the neko to the mouse.  0 degress at three o'clock, moving clockwise.

    ($x, $y) = $canvas->pointerxy;
    $y -= ($pixbits / 2 + 3 );

    # Don't let the neko run off the display.

    if ($x < 0 + $pixbits) {
	$x = $pixbits;
    } elsif ($x > $maxx - $pixbits) {
	$x = $maxx - $pixbits;
    } elsif ($y < 0 + $pixbits) {
	$y = $pixbits;
    } elsif ($y > $maxy - $pixbits) {
	$y = $maxy - $pixbits;
    }
    return if stopped;

    # Return heading from the neko to the mouse.

    my $h = int( $r2d * CORE::atan2( ($y - $ny), ($x - $nx) ) ) % 360;
    my($degrees, $dir);

    foreach (
	     [[ 22.5,  67.5], 'DWRIGHT'],
	     [[ 67.5, 112.5], 'DOWN'],
	     [[112.5, 157.5], 'DWLEFT'],
	     [[157.5, 202.5], 'LEFT'],
	     [[202.5, 247.5], 'UPLEFT'],
	     [[247.5, 292.5], 'UP'],
	     [[292.5, 337.5], 'UPRIGHT'],
	     [[337.5,  22.5], 'RIGHT'],
	     ) {
	($degrees, $dir) = ($_->[0], $_->[1]);
	last if $h >= $degrees->[0] and $h < $degrees->[1];
    } # forend

    set_state "NEKO_$dir";

} # end positition_to_heading

sub set_state {

    # Initialize for a new state if it's different from the current state.

    my($new_state) = @_;

    return if $new_state eq $state;
    $state = $new_state;
    $state_count = 0;

} # end set_state

sub stopped {

    # See if the neko and mouse are close enough to pretend we are stopped.  $close_enough is tied
    # to the neko's velocity to prevent "directional hysteresis".

    $close_enough = $velocity;
    ( abs($x - $nx) <= $close_enough and abs($y - $ny) <= $close_enough ) ? 1 : 0;

} # end stopped

# Neko state processors.

sub do_awake {

    frame 'awake';
    return if $state_count < $awake_time;
    position_to_heading;

} # end do_awake

sub do_move {

    my($dir) = @_;
    if (stopped) {
	($nx, $ny) = ($x, $y);
	set_state 'NEKO_STOP';
    } else {
	my($dx, $dy) = @{$dxdy{$dir}};
	($nx, $ny) = ($nx + ($dx * $velocity), $ny + ($dy * $velocity));
	frame lc($dir) . (($state_count % 2) + 1);
	position_to_heading;
    }

} # end do_move

sub do_sleep {

    position_to_heading;
    if (stopped) {
	if ($state_count < $jare_time) {
	    frame (($state_count % 2) ? 'jare2' : 'mati2');
	} elsif ($state_count < $jare_time + $kaki_time) {
	    frame 'kaki' . (($state_count % 2) + 1);
	} elsif ($state_count < $jare_time + $kaki_time + $akubi_time) {
	    frame 'mati3';
	} else {
	    frame 'sleep' . ((($state_count % 8) <= 3) ? '1' : '2');
	}
    } else {
	set_state 'NEKO_AWAKE';
    }

} # end do_sleep

sub do_stop {

    if (stopped) {
	if ($state_count < $stop_time) {
	    frame 'mati2';
	} elsif ($nx <= 0 + $pixbits) {
	    set_state 'NEKO_LTOGI';
	} elsif ($nx >= $maxx - $pixbits) {
	    set_state 'NEKO_RTOGI';
	} elsif ($ny <= 0 + $pixbits) {
	    set_state 'NEKO_UTOGI';
	} elsif ($ny >= $maxy - $pixbits) {
	    set_state 'NEKO_DTOGI';
	} else {
	    set_state 'NEKO_SLEEP';
	}
    } else {
	set_state 'NEKO_AWAKE';
    }

} # end do_stop

sub do_togi {

    my($dir) = @_;

    position_to_heading;
    if (stopped) {
	if ($state_count < $togi_time) {
	    frame lc($dir) . (($state_count % 2) + 1);
	} elsif ($state_count < $togi_time + $kaki_time) {
	    frame 'kaki' . (($state_count % 2) + 1);
	} elsif ($state_count < $togi_time + $kaki_time + $akubi_time) {
	    frame 'mati3';
	} else {
	    frame 'sleep' . ((($state_count % 8) <= 3) ? '1' : '2');
	}
    } else {
	set_state 'NEKO_AWAKE';
    }

} # end do_togi

1;
