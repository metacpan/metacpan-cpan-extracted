package Tk::MDI::ChildWindow;

use strict;

my $unfocusedTitleBg = 'lightgray';      # bg color when no focus
my $focusedTitleBg   = 'papayawhip';       # default color when focused

my %changeCursorHash = 
	(
		n  => [qw/size_ns    top_side/],
		w  => [qw/size_we   left_side/],
		e  => [qw/size_we  right_side/],
		s  => [qw/size_ns bottom_side/],

		nw => [qw/size_nw_se     top_left_corner/],
		se => [qw/size_nw_se bottom_right_corner/],
		sw => [qw/size_ne_sw  bottom_left_corner/],
		ne => [qw/size_ne_sw    top_right_corner/],
	);

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	my $obj = bless {} => $class;

	my %args  = @_;
	$obj->{PARENT}    = delete $args{-parent} or die "No Parent Frame";
	$obj->{PARENTOBJ} = delete $args{-parentobj} or die "No Parent Object";
	$obj->{NAME}     = $args{-name};
	$obj->{FOCUSBG}   = $args{-titlebg} || $focusedTitleBg;
	$obj->{MINFRAME}  = $args{-minframe};

	$obj->{EXTBD} = $obj->{PARENTOBJ}->_getExtBD;
	$obj->{INTBD} = $obj->{PARENTOBJ}->_getIntBD;
	$obj->{MINIMIZEDHEIGHT}=23;
	$obj->{MINIMIZEDWIDTH}=120;
	$obj->{CASCADEHEIGHT}=400;
	$obj->{CASCADEWIDTH}=500;

	my $x = delete $args{-x} || 0;
	my $y = delete $args{-y} || 0;
	$x=$y=0 unless ($x == $y);
	my $h = delete $args{-height} || $obj->{CASCADEHEIGHT};
	my $w = delete $args{-width} || $obj->{CASCADEWIDTH};

	$obj->{EXTERNAL} = $obj->{PARENT}->Frame(
				-relief=>'raised',
				-bd=>$obj->{EXTBD}
				)->place(-x=>$x,-y=>$y,-width=>$w,-height=>$h);

	$obj->{INTERNAL} = $obj->{EXTERNAL}->Frame(
				-relief=>'flat',
				-bd=>$obj->{INTBD},
				)->pack(qw/-fill both -expand 1/);

	$obj->{TITLE} = $obj->{INTERNAL}->Frame(
				-relief=>'flat', 
				-height=>$obj->{MINIMIZEDHEIGHT},
				-bd=>0,
				-bg => $obj->{FOCUSBG},
				)->pack(qw/-fill x -expand 0/);

	$obj->{MAIN} = $obj->{INTERNAL}->Frame(
				-container => 1,
				)->pack(qw/-fill both -expand 1/);

	# for some reason I need an eval here to get it to work on winblowZ.
	$obj->{TOPLEVEL} = $obj->{PARENT}->Toplevel(-use => eval $obj->{MAIN}->id);

	$obj->{TITLELABEL} = $obj->{TITLE}->Label(
				-text => $obj->{NAME},
				-bg   => $obj->{FOCUSBG},
				-anchor => 'w',
				)->grid(qw/-row 0 -column 0 -sticky nesw/);

	# populate the title.
	$obj->{CLOSEBUTTON}=$obj->{TITLE}->Button(
				-image=>$obj->{PARENTOBJ}->{IMAGES}->{close},
				-command => sub { $obj->_killWindow(1) },
				)->grid(qw/-row 0 -column 3 -sticky ew -padx 2/);
                         
	# We put the Restore button directly beneath the minimize and maximize buttons.
	# This means only we only need a Tk::raise to toggle between them
	$obj->{RESTORE_FROM_MAX}=$obj->{TITLE}->Button(
				-image=>$obj->{PARENTOBJ}->{IMAGES}->{restore},
				-command => sub { $obj->_restoreFromMax },
				)->grid(qw/-row 0 -column 2 -sticky ew/);       

	$obj->{MAXBUTTON}=$obj->{TITLE}->Button(
				-image=>$obj->{PARENTOBJ}->{IMAGES}->{maximize},
				-command => sub { $obj->_maximizeWindow },
				)->grid(qw/-row 0 -column 2 -sticky ew/);

	$obj->{RESTORE_FROM_MIN}=$obj->{TITLE}->Button(
				-image=>$obj->{PARENTOBJ}->{IMAGES}->{restore},
				-command => sub { $obj->_restoreFromMin },
				)->grid(qw/-row 0 -column 1 -sticky ew/);

	$obj->{MINBUTTON}=$obj->{TITLE}->Button(
				-image=>$obj->{PARENTOBJ}->{IMAGES}->{minimize},
				-command => sub { $obj->_minimizeWindow },
				)->grid(qw/-row 0 -column 1 -sticky ew/);

	$obj->{TITLE}->gridColumnconfigure(0,-weight=>1);
	$obj->{TITLE}->raise;

	foreach my $b(qw/CLOSEBUTTON MAXBUTTON RESTORE_FROM_MIN RESTORE_FROM_MAX MINBUTTON/){
		$obj->{$b}->bind('<Enter>',[sub {$obj->{$b}->configure(qw/-relief ridge/)}]);
		$obj->{$b}->bind('<Leave>',[sub {$obj->{$b}->configure(qw/-relief raised/)}]);
	}

	$obj->{ISMAX}     = 0; # is it currently maximized?
	$obj->{ISMIN}     = 0; # is it currently minimized?
	$obj->{ISSHADED}  = 0; # is it currently shaded?
	$obj->{HASFOCUS}  = 0; # is it currently focused?
	$obj->{WASMIN}    = 0; # was the last position held a minimized position?
	$obj->{WASMAX}    = 0; # was the last position held a maximized position?
	$obj->{MYSLOT}    = 0; # Holds the current array numbers of a minimized window.

	# create default bindings.
	$obj->_createDefaultBindings;

	# Give the Toplevel an OnDestroy hook to delete the object itself!
	# This will allow the user to destroy child windows programmatically.
	# We don't want _killWindow to be executed twice if the user actually just
	# clicked on the 'X' close button - so pass a zero flag to the sub to show
	# that this OnDestroy hook was called.
	$obj->{TOPLEVEL}->OnDestroy(sub{$obj->_killWindow(0)});

	return $obj;
}

sub _checkCursorPosition
{
	my ($obj,$first)=@_;
	my ($cX,$cY)=$obj->{EXTERNAL}->pointerxy;
	my $posn = $obj->_find_location($cX,$cY);
		if ($first){
			$obj->_changeCursor($posn);
			$obj->{OLDPOSN}=$posn;
			return;
		}
		if ($obj->{OLDPOSN} ne $posn){
			$obj->_changeCursor($posn);
			$obj->{OLDPOSN}=$posn;
			return;
		}
}

sub _find_location
{
	my ($obj,$point_rootx,$point_rooty)=@_;
	my $wi=$obj->{EXTERNAL}->width;
	my $he=$obj->{EXTERNAL}->height;
	my $wx=$point_rootx-($obj->{EXTERNAL}->rootx);
	my $wy=$point_rooty-($obj->{EXTERNAL}->rooty);
	my ($x,$y)=('','');

	if ($wx<=20){
		$x='w';
	}
	elsif($wx>=$wi-20){
		$x='e';
	}
	if ($wy<=20){
		$y='n';
	}
	elsif($wy>=$he-20){
	$y='s';
	}
	return $y.$x;
}

sub _changeCursor
{
	my ($obj,$p)=@_;
	$obj->{EXTERNAL}->configure(-cursor => $changeCursorHash{$p}[$Tk::platform ne 'MSWin32']);;
}

sub _createDefaultBindings {
	my $obj = shift;

	# Toplevel focus - haven't figured these out yet!!
	$obj->{TOPLEVEL}->bind('<Enter>'       => [sub {$obj->_enterToplevel}]);
	$obj->{TOPLEVEL}->bind('<Leave>'       => [sub {$obj->_leaveToplevel}]);

	# bindings for focussing, dragging and (un)shading the title bar.
	for my $o (qw/TITLE TITLELABEL/) {
		$obj->{$o}->bind('<ButtonPress-1>'   => [sub { $obj->_button1Press }]);
		$obj->{$o}->bind('<ButtonRelease-1>' => [sub { $obj->_button1Release }]);	
		$obj->{$o}->bind('<B1-Motion>'       => [sub { $obj->_button1Drag  }]);
		$obj->{$o}->bind('<ButtonPress-3>' => [sub { $obj->_shadeWindow  }]);
	}

		# bindings for focussing, changing cursors and resizing the window.
	$obj->_bindExternal;
	$obj->{EXTERNAL}->bind('<ButtonPress-1>'    =>[sub  { $obj->_expandWinPress  }]);

	$obj->{DIRECTION} = {
			's'  =>     [0,1,0,0],
			'sw' =>     [0,1,1,0],
			'se' =>     [0,1,0,1],
			'n'  =>     [1,0,0,0],
			'nw' =>     [1,0,1,0],
			'ne' =>     [1,0,0,1],
			'w'  =>     [0,0,1,0],
			'e'  =>     [0,0,0,1],
			};
}

sub _bindExternal
{
	#this callback is invoked at the end of a window resize to reset the 
	#bindings which were cancelled at the onset of resize
	#Called from _expandWinRelease

	my $obj=shift;
	$obj->{EXTERNAL}->bind('<Enter>'=> [sub { $obj->_enterExternal }]);
	$obj->{INTERNAL}->bind('<Enter>'=> [sub { $obj->_enterInternal }]);
	$obj->{INTERNAL}->bind('<Leave>'=> [sub { $obj->_enterExternal }]);
	$obj->{EXTERNAL}->bind('<Leave>'=> [sub { $obj->_leaveExternal }]);
}

sub _unbindExternal
{
	#This callback stops all bindings to the window being resized. This is only
	#temporary - as the bindings are replaced at the end of a resize. Why do this?
	#Because sometimes if you move the mouse too quickly enter and leave events will
	#occur during a resize - and we want neither!
	#Called from _expandWinPress
	
	my $obj=shift;
	$obj->{EXTERNAL}->bind('<Enter>'=> '');
	$obj->{INTERNAL}->bind('<Enter>'=> '');
	$obj->{INTERNAL}->bind('<Leave>'=> '');
	$obj->{EXTERNAL}->bind('<Leave>'=> '');
}

sub _leaveExternal
{
	my $obj=shift;
	if ($obj->{PARENTOBJ}->cget(-focus) eq 'strict'){
		$obj->_unfocusIt;
		$obj->{PARENTOBJ}->_unfocusMe($obj->{NAME});
	}

	$obj->{EXTERNAL}->configure(-cursor => 'left_ptr');
	$obj->{EXTERNAL}->bind('<Motion>','');
}

sub _enterExternal
{
	my $obj=shift;
	$obj->_focusIt if ($obj->{PARENTOBJ}->cget(-focus) ne 'click');
	$obj->_checkCursorPosition(1);  
	$obj->{EXTERNAL}->bind('<Motion>',[sub{$obj->_checkCursorPosition(0)}]);
}

sub _enterInternal
{
	my $obj=shift;
	$obj->{EXTERNAL}->configure(-cursor => 'left_ptr');
	$obj->{EXTERNAL}->bind('<Motion>','');
}

sub _enterToplevel
{
	my $obj = shift;

	if ($obj->{PARENTOBJ}->cget(-focus) ne 'click'){
		$obj->_focusIt unless ($obj->{HASFOCUS});
		#foreach my $child ($obj->{TOPLEVEL}->children){
		#       print "CHILD: $child\n";
		#       $child->bind('<Enter>',sub{$child->Tk::EnterFocus});
		#}
	}
	else{
		$obj->{TOPLEVEL}->bind('<ButtonPress-1>' => [sub {$obj->_focusIt}]);
	}
}

sub _leaveToplevel
{
	# my $obj = shift;
	#  $obj->{TOPLEVEL}->bind('<ButtonPress-1>' => '');
}

sub _expandWinPress 
{
	my $obj = shift;

	$obj->{PARENTOBJ}->_win32confineCursor if ($obj->{PARENTOBJ}->_confineMethod eq "win32");
	$obj->_focusIt;

	my @dir = @{$obj->{DIRECTION}->{$obj->{OLDPOSN} }};

	my ($x, $y)   = $obj->{PARENT}->pointerxy;
	my $w = $obj->{EXTERNAL}->width;
	my $h = $obj->{EXTERNAL}->height;

	my $sx = $obj->{EXTERNAL}->x();
	my $sy = $obj->{EXTERNAL}->y();
	$obj->{TEMP} = [$x, $y, $sx, $sy, $w, $h];
	
	$obj->_setShadow($sx,$sy) if ($obj->{PARENTOBJ}->cget(-shadow));
	$obj->_unbindExternal;
	$obj->{EXTERNAL}->bind('<Motion>','');
	
	$obj->{PARENTOBJ}->bind('all','<Motion>',[sub {$obj->_expandWinDrag(@dir,0)}]);
	$obj->{PARENTOBJ}->bind('all','<ButtonRelease-1>',[sub {$obj->_expandWinRelease(@dir,1)}]);

	#Turn off shaded feature as you are resizing
	$obj->{ISSHADED}=0;
}

sub _expandWinRelease {
	my $obj = shift;
	$obj->{PARENTOBJ}->bind('all','<Motion>','');
	$obj->_expandWinDrag(@_);
	$obj->{PARENTOBJ}->_win32releaseCursor if ($obj->{PARENTOBJ}->_confineMethod eq "win32");

	$obj->{PARENTOBJ}->bind('all','<ButtonRelease-1>','');	  
	$obj->_bindExternal;
}

sub _expandWinDrag {
	my ($obj, $top, $bottom, $left, $right, $final) = @_;
	my $l = $obj->{TEMP};

	$obj->_warpToConfine if ($obj->{PARENTOBJ}->_confineMethod eq "unix");
		
	my ($x, $y) = $obj->{PARENT}->pointerxy;
		#warn "NOW $x: $y";
	my $dw = my $dh = my $dx = my $dy = my $YLimit = my $XLimit = 0;

	if ($top) {
		$dh -= $y - $l->[1];
		$dy += $y - $l->[1];
		$YLimit = $l->[3]+$l->[5]-$obj->{MINIMIZEDHEIGHT};
	}
	elsif ($bottom) {
		$dh += $y - $l->[1];
	}
	if ($left) {
		$dw -= $x - $l->[0];
		$dx += $x - $l->[0];
		$XLimit = $l->[2]+$l->[4]-$obj->{MINIMIZEDWIDTH};
	}
	elsif ($right) {
		$dw += $x - $l->[0];
	}

	my $cX = $l->[2]+$dx;
	$cX = $XLimit if ( $left && $cX > $XLimit);

	my $cY = $l->[3]+$dy;
	$cY = $YLimit if ( $top && $cY > $YLimit);

	my $cH = $l->[5]+$dh;
	$cH = $obj->{MINIMIZEDHEIGHT} if ($cH < $obj->{MINIMIZEDHEIGHT});

	my $cW = $l->[4]+$dw;
	$cW = $obj->{MINIMIZEDWIDTH} if ($cW < $obj->{MINIMIZEDWIDTH}); 

	if ($obj->{PARENTOBJ}->cget(-shadow) && not $final){
		$obj->_resizeShadow($cX,$cY,$cW,$cH);
	}
	else{
		$obj->{EXTERNAL}->place(
				-x => $cX,
				-y => $cY,
				-width  => $cW,
				-height => $cH,
				);
		$obj->_hideShadow if ($obj->{PARENTOBJ}->cget(-shadow));
	}       
}

sub _shadeWindow {
	my $obj = shift;
	return if ($obj->{ISMIN});
	return if ($obj->{ISMAX});

	if ($obj->{ISSHADED}) {
		# it is shaded. Unshade it.
		$obj->{EXTERNAL}->place(
				-height => $obj->{ISSHADED}
				);
		$obj->{ISSHADED} = 0;
	}
	else {
		$obj->{ISSHADED} = $obj->{EXTERNAL}->height;
		$obj->{EXTERNAL}->place(
				-height => $obj->{MINIMIZEDHEIGHT}
				);
	}
}

sub _killWindow {
	my ($obj,$flag) = @_;

	# If $flag is an affirmative boolean then the 'X' button was clicked.
	# In this case we make sure the OnDestroy hook gets cancelled - so 
	# this subroutine does not get called twice.

	$obj->{TOPLEVEL}->OnDestroy([sub{}]) if ($flag);

	$obj->{PARENTOBJ}->IwasUnMaximized($obj) if ($obj->{ISMAX});# turn off max flag in MDI.pm
	$obj->{PARENTOBJ}->IwasUnMinimized($obj) if ($obj->{ISMIN});# open the minimized slot
	$obj->{PARENTOBJ}->_destroyMe($obj); # bye bye world!
	$obj->{EXTERNAL}->destroy;
	undef $obj;
}

sub _minimizeWindow
{
	my $obj = shift;

	if ($obj->{ISMIN}){
		$obj->_unfocusIt;
		return;
	}
	# back-up placement info only if coming from an UN-maximized position.
	unless ($obj->{ISMAX}){
		my %info = $obj->{EXTERNAL}->placeInfo;
		$obj->{SAVEDINFO}=\%info;
	}
	# force a button change..
	$obj->{RESTORE_FROM_MIN}->raise($obj->{MINBUTTON});
	$obj->{MAXBUTTON}->raise($obj->{RESTORE_FROM_MAX});

	# if minimized from a maximised position?
	if ($obj->{ISMAX}){
		$obj->{PARENTOBJ}->IwasUnMaximized($obj);
	}

	my ($r,$c) = $obj->{PARENTOBJ}->_findMinimizeSlot($obj);
	my $h = $obj->{PARENT}->height;

	# disallow resize by removing the borders
	$obj->{EXTERNAL}->configure(-bd=>0);
	$obj->{INTERNAL}->configure(-bd=>0);
	$obj->_unfocusIt;
	#now show ONLY the titlebar
	$obj->{EXTERNAL}->placeForget;
	$obj->{EXTERNAL}->place(
				-relx=>$c/5,
				-rely => 1,
				-y    => -($r)*($obj->{MINIMIZEDHEIGHT}-$obj->{EXTBD}-$obj->{INTBD}),
				-height=>$obj->{MINIMIZEDHEIGHT}-$obj->{EXTBD}-$obj->{INTBD},
				-relwidth=>0.2,
				);

	$obj->{MYSLOT} = $r.'~'.$c;
	$obj->{ISMAX}  = 0;
	$obj->{ISMIN}  = 1;
	$obj->{WASMIN} = 0;
	#$obj->{PARENTOBJ}->IwasMinimized($obj);
}

sub _restoreFromMin
{
	# Restore after a minimize..
	my $obj = shift;
	$obj->_restore;
	$obj->{PARENTOBJ}->IwasUnMinimized($obj);
	$obj->_focusIt;

}

sub _restore
{
	my $obj = shift;
	#force correct buttons...       
	$obj->{MINBUTTON}->raise($obj->{RESTORE_FROM_MIN});
	$obj->{MAXBUTTON}->raise($obj->{RESTORE_FROM_MAX});

	#allow resize by replacing the borders
	$obj->{EXTERNAL}->configure(-bd=>$obj->{EXTBD});
	$obj->{INTERNAL}->configure(-bd=>$obj->{INTBD});
	$obj->{EXTERNAL}->placeForget;
	$obj->{EXTERNAL}->place(%{$obj->{SAVEDINFO}});
	$obj->{ISMIN} = 0;
	$obj->{ISMAX} = 0;
	$obj->{WASMIN}= 0;      
}

sub _restoreFromMax
{
	my $obj = shift;
	$obj->_restore;
	$obj->{PARENTOBJ}->IwasUnMaximized($obj);
	$obj->_focusIt;
}

sub _maximizeWindow
{
	my $obj = shift;
	if ($obj->{ISMAX}){
		$obj->_focusIt;
		return;
	}
	if ( $obj->{ISMIN} ){
		#then we are maximizing from a minimize position
		$obj->{MINBUTTON}->raise($obj->{RESTORE_FROM_MIN});
		$obj->{PARENTOBJ}->IwasUnMinimized($obj);
		$obj->{WASMIN}=1;
	}
	else {
		# we are coming from a placed position
		# back up placement info.
		my %info = $obj->{EXTERNAL}->placeInfo;
		$obj->{SAVEDINFO}=\%info;
	}

	$obj->{ISMAX} = 1;
	$obj->{ISMIN} = 0;

	#disallow resize by zeroing the borders
	$obj->{EXTERNAL}->configure(-bd=>0);
	$obj->{INTERNAL}->configure(-bd=>0);
	$obj->{RESTORE_FROM_MAX}->raise($obj->{MAXBUTTON});

	#now finally maximize it..
	$obj->{EXTERNAL}->placeForget;
	$obj->{EXTERNAL}->place(
				-in=>$obj->{PARENTOBJ}->{MAINFRAME},
				-relx=>0, -rely=>0,
				-relheight => 1.0,
				-relwidth  => 1.0,
				);
	$obj->{PARENTOBJ}->IwasMaximized($obj);
	$obj->_focusIt;
}

sub _revert
{
	my $obj = shift;
	if ($obj->{WASMIN}){
		$obj->_minimizeWindow;
	}
	else{
		$obj->_restoreFromMax;
	}
}


sub _button1Press {
	my $obj = shift;

	#disallow move on a minimized or maximized window
	return if ($obj->{ISMAX} or $obj->{ISMIN});

	$obj->{PARENTOBJ}->_win32confineCursor if ($obj->{PARENTOBJ}->_confineMethod eq "win32");
	$obj->_focusIt;
	
	my ($x, $y) = $obj->{EXTERNAL}->pointerxy;
	my %info    = $obj->{EXTERNAL}->placeInfo;
	my ($w,$h)  = ($obj->{EXTERNAL}->width,$obj->{EXTERNAL}->height);
	my $ox      = $info{'-x'};
	my $oy      = $info{'-y'};

	$obj->{TEMP} = [$x, $y, $ox, $oy, $w, $h];
	$obj->_setShadow($ox,$oy) if ($obj->{PARENTOBJ}->cget(-shadow));
}

sub _button1Release{
	my $obj = shift;
	#disallow move on a minimized or maximized window
	return if ($obj->{ISMAX} or $obj->{ISMIN});

	$obj->{PARENTOBJ}->_win32releaseCursor if ($obj->{PARENTOBJ}->_confineMethod eq "win32");
	#$obj->resizePane; # not yet implemented
	my ($xN, $yN) = $obj->{EXTERNAL}->pointerxy;
	$obj->_hideShadow if ($obj->{PARENTOBJ}->cget(-shadow));
	$obj->{PARENTOBJ}->update;
	$obj->{EXTERNAL}->place(
			-x => $obj->{TEMP}[2] + $xN - $obj->{TEMP}[0],
			-y => $obj->{TEMP}[3] + $yN - $obj->{TEMP}[1]
				);

}

sub _button1Drag {
	my $obj = shift;
	#disallow move on a minimized or maximized window
	return if ($obj->{ISMAX} or $obj->{ISMIN});

	$obj->_warpToConfine if ($obj->{PARENTOBJ}->_confineMethod eq "unix");
	my ($xN, $yN) = $obj->{EXTERNAL}->pointerxy;

	if ($obj->{PARENTOBJ}->cget(-shadow)){
		my $X = $obj->{TEMP}[2] + $xN - $obj->{TEMP}[0];
		my $Y = $obj->{TEMP}[3] + $yN - $obj->{TEMP}[1];
		$obj->_moveShadow($X,$Y);       
	}
	else {
		$obj->{EXTERNAL}->place(
				-x => $obj->{TEMP}[2] + $xN - $obj->{TEMP}[0],
				-y => $obj->{TEMP}[3] + $yN - $obj->{TEMP}[1]);
	}
}

sub _setShadow{
	my ($obj,$X,$Y) = @_;
	my $bd=$obj->{EXTBD};
	$bd=1 unless ($bd);
	my ($ts,$bs,$ls,$rs) = $obj->{PARENTOBJ}->_getShadowRefs;

	$ts->place(
		-x=>$X,
		-y=>$Y,
		-width=>$obj->{TEMP}[4],
		-height=>$bd
	);
	$bs->place(
		-x=>$X,
		-y=>$Y+$obj->{TEMP}[5]-$bd,
		-width=>$obj->{TEMP}[4],
		-height=>$bd
	);
	$ls->place(
		-x=>$X,
		-y=>$Y,
		-width=>$bd,
		-height=>$obj->{TEMP}[5]
	);
	$rs->place(
		-x=>$X+$obj->{TEMP}[4]-$bd,
		-y=>$Y,
		-width=>$bd,
		-height=>$obj->{TEMP}[5]);

	foreach ($ts,$bs,$ls,$rs){
		$_->raise;
	}
}

sub _moveShadow
{
	my ($obj,$X,$Y) = @_;
	my $bd=$obj->{EXTBD};
	$bd=1 unless ($bd);

	my ($ts,$bs,$ls,$rs) = $obj->{PARENTOBJ}->_getShadowRefs;

	$ts->place(
		-x=>$X,
		-y=>$Y
	);
	$bs->place(
		-x=>$X,
		-y=>$Y+$obj->{TEMP}[5]-$bd
	);
	$ls->place(
		-x=>$X,
		-y=>$Y
	);
	$rs->place(
		-x=>$X+$obj->{TEMP}[4]-$bd,
		-y=>$Y
	);
}

sub _resizeShadow
{
	my ($obj,$X,$Y,$w,$h)=@_;
	my $bd=$obj->{EXTBD};
	$bd=1 unless ($bd);

	my ($ts,$bs,$ls,$rs) = $obj->{PARENTOBJ}->_getShadowRefs;
	$ts->place(
		-x=>$X,
		-y=>$Y,
		-width=>$w
	);
	$bs->place(
		-x=>$X,
		-y=>$Y+$h-$bd,
		-width=>$w
	);
	$ls->place(
		-x=>$X,
		-y=>$Y,
		-height=>$h
	);
	$rs->place(
		-x=>$X+$w-$bd,
		-y=>$Y,
		-height=>$h
	);
}

sub _hideShadow
{
	my $obj = shift;
	#Hide the shadow frame
	foreach ($obj->{PARENTOBJ}->_getShadowRefs){
		$_->place(-x=>-50,-y=>-50,-width=>10,-height=>10);
	}
}

sub _menuFocus
{
	# This only gets called if someone clicked on the menu
	# to bring up the child. Standard MDI is to not only bring
	# up the window - but to maximize it if indeed others are maximized.
	# If window has focus then minimize it - but NOT if it is currently
	# maximized.

	my $obj = shift;

	return if ($obj->{ISMAX} and $obj->{HASFOCUS});
	my ($existsMaxWindow) = $obj->{PARENTOBJ}->_isWindowMaxed;

	if ($obj->{ISMIN}){
		if ($existsMaxWindow){
			$obj->_maximizeWindow;
		}
		else {
			$obj->_restoreFromMin;
		}
	}
	elsif ($obj->{HASFOCUS} and not $existsMaxWindow){
		$obj->_minimizeWindow;
	}
	else {
		if ($existsMaxWindow){
			$obj->_maximizeWindow;
		}
		else {
			$obj->_focusIt;
		}
	}
}

sub _warpToConfine
{
	my $obj = shift;
	my ($rx, $ry) = $obj->{PARENT}->pointerxy;
		#warn "$rx: $ry";
	my ($wi, $he) = ($obj->{PARENT}->width, $obj->{PARENT}->height);
	my ($rootx,$rooty)=($obj->{PARENT}->rootx,$obj->{PARENT}->rooty);
	my ($px,$py)=($rx-$rootx,$ry-$rooty);
	my $warpneeded=0;

	if ($px <= 0) {
		$px = 1;
		$warpneeded=1;
	}
	elsif ($px >= $wi) {
		$px = $wi - 1;
		$warpneeded=1;
	}

	if ($py <= 0) {
		$py = 1;
		$warpneeded=1;
	}
	elsif ($py >= $he) {
		$py = $he - 1;
		$warpneeded=1;
	}

	# Wow! Huge memory leak here if the '-when' is not set.
	# I had 60 meg core dumps..didn't quite figure out why yet?
	if ($warpneeded){
		#warn "Warping: $px $py";
		$obj->{PARENT}->eventGenerate(
				"<Motion>",
				-when=>'head',
				-x => $px,
				-y => $py,
				-warp => 1
				);
		$obj->{PARENT}->idletasks;		
	}
}

sub _focusIt {
	my $obj=shift;

	return if ($obj->{ISMIN}); #Don't focus a minimized window
	$obj->{PARENTOBJ}->_focusMe($obj->{NAME});
	$obj->{HASFOCUS} = 1;
	$obj->{TITLE}     ->configure(-bg => $obj->{FOCUSBG});
	$obj->{TITLELABEL}->configure(-bg => $obj->{FOCUSBG});
	$obj->{EXTERNAL}  ->raise;
	# somehow need to get packed widgets the focus.
	#foreach ($obj->{TOPLEVEL}->children){
	#    $_->Tk::focus;     
	#}

}

sub _unfocusIt {
	my $obj = shift;

	if ($obj->{HASFOCUS}) {
		$obj->{TITLE}     ->configure(-bg => $unfocusedTitleBg);
		$obj->{TITLELABEL}->configure(-bg => $unfocusedTitleBg);
		$obj->{HASFOCUS}   = 0;
	}
}

sub mainFrame { $_[0]->{TOPLEVEL} }

sub _TileMe
{
	#avoids relx/rely bug.
	my ($obj, $x, $y, $w, $h) = @_;

	$obj->{EXTERNAL}->place(
				-x => $x,
				-y => $y,
				-width  => $w,
				-height => $h,
	);
	$obj->{EXTERNAL}->raise;
}

sub _name   { return $_[0]->{NAME}  }

sub _isMin  { return $_[0]->{ISMIN} }

sub _wasMin { return $_[0]->{WASMIN}}

sub _isMax  { return $_[0]->{ISMAX} }

sub _mySlot { return $_[0]->{MYSLOT}}

1;
