package Tk::MDI;

use strict;
use vars qw($VERSION);
use Carp qw/carp/;

$VERSION="0.2";

use base qw(Tk::Frame);
Construct Tk::Widget 'MDI';

require Tk::MDI::ChildWindow;
require Tk::MDI::Images;
require Tk::MDI::Menu;

sub Populate {
	my ($self, $args) = @_;

	$self->SUPER::Populate($args);

	$self->{MW}      = $self->toplevel;
	$self->{TRACK_X} = 600;
	$self->{TRACK_Y} = 600;
	$self->{EXTBD}   = 3;
	$self->{INTBD}   = 1;

	$self->{STYLE} = lc(delete $args->{-style});
	$self->_defineButtons($self->{STYLE} || 'default');

	$self->{CONFINE} = 'unix'; #default to 'perl based' cursor confine

	if ($Tk::platform eq 'MSWin32'){
		if (eval"require Win32::API"){
			$self->{CLIPCURSOR}=new Win32::API('user32','ClipCursor',['P'],'N');
			$self->{CONFINE}='win32'if ( $self->{CLIPCURSOR} );
		}
	}
	$self->{MAINFRAME} = $self->{MW}->Frame(
				-height=>$self->{TRACK_Y},
				-width=>$self->{TRACK_X},
				)->pack(-fill=>'both', -expand=>1);


	$self->{FOCUSED}  = 0;
	$self->{WINS}     = {};
	$self->{WINCOUNT} = 1;
	$self->{SMARTXY}  = 0;
	$self->{SMARTDELTA}=23;
	$self->{CURRENT_MAXWINDOW} = 0;
	$self->{MINSLOT}  = [];

	# Note -style is not in configspecs because we won't need to 
	# change styles in the midst of the program.
	# menu and toolbar need to be of type METHOD..
	$self->ConfigSpecs(
		-menu	=> [qw/METHOD   menu    Menu/,     'both'],
		-focus       => [qw/METHOD   focus   Focus/,   'click'],
		-shadow      => [qw/METHOD   shadow  Shadow/,	1],
		-autoresize  => [qw/PASSIVE  autoresize AutoResize/, 0],
		-background  => [$self->{MAINFRAME}, 'background', 'Background', undef],
		-bg	  => '-background',
		DEFAULT      => [$self->{MAINFRAME}],
		);

}

# This method creates the images used for the various icons.
# All images are defined in the Tk::MDI::Images package.
# The bitmaps (or pixmaps) created are stored in a hash with
# key names of minimize, maximize, close, restore.

sub _defineButtons {
	my ($w,$style) = @_;
	$w->{IMAGES}=Tk::MDI::Images::createImage($w->toplevel,$style);
}

#      Different focus policies:

#      <click> ClickToFocus - Clicking into a window activates it. This is
#      also the default.

#      <lazy> FocusFollowsMouse - Moving the mouse pointer actively onto a
#      window activates it.

#      <strict> FocusStrictlyUnderMouse - Only the window under the mouse
#      pointer is active. If the mouse points nowhere, nothing has the
#      focus.

#      Note FocusStrictlyUnderMouse is not particulary useful. It is only
#     provided for old-fashined die-hard UNIX people ;-)

# configure methods follow..

sub focus
{
	my ($obj,$f)=@_;
	if (defined $f){
		$obj->{FOCUSPOLICY} = $f;
		$obj->_configure(-focus => $f);

		if ($f eq 'click'||$f eq 'lazy'){
			$obj->{MAINFRAME}->bind('<1>'     => sub { $obj->_unfocusAll });
			$obj->{MAINFRAME}->bind('<Enter>' => '');
			$obj->{MW}->bind('<Leave>'	=> '');
		}
		else{
			$obj->{MAINFRAME}->bind('<Enter>' => sub {$obj->_unfocusAll});
			$obj->{MW}->bind('<Leave>' => sub  {$obj->_unfocusAll});
		}
	}
	return $obj->_cget('-focus');
}

sub menu {
    my ($obj, $m) = @_;

    unless (defined $m) {
	return $obj->{MENUTYPE};
    }

    # check for sanity. If something is wrong, default to 'both'.
    unless (ref($m) eq 'Menu' or $m =~ /^popup|menubar|both|none/) {
		carp "bad argument for '-menu' option. Must be one of: ",
			"'popup', 'menubar', 'both', 'none' or Menu object ref. ",
			"Defaulting to 'both'.";
		$m = 'both';
    }

    $obj->{MENUTYPE} = $m;

    $obj->{MENU} = Tk::MDI::Menu->new(
			-parent    => $obj->{MAINFRAME},
			-parentobj => $obj,
			-mw	=> $obj->{MW},
			-type      => $obj->{MENUTYPE},
	);

}

# This method unfocuses all child windows of the MDI widget.
# It is usually called when the user clicks on the background, or when
# strict focus is requested and nothing is under the mouse.
# This is a private method.
sub _unfocusAll {
	my $obj = shift;

	for my $w (values %{$obj->{WINS}}) {
		$w->_unfocusIt;
	}

	$obj->{FOCUSED} = 0;
}

# This method is called by a child window requesting focus, as a result
# of some user interaction. It causes all other children windows to be
# unfocused.
# This is a private method.
sub _focusMe {
	my ($obj, $index) = @_;

	$obj->_unfocusAll;
	$obj->{FOCUSED} = $index;
}

# This method is called by a child window when it loses focus. Used so that
# the parent can keep track of who is focused.
# This is a private method.
sub _unfocusMe {
	my ($obj, $index) = @_;

	$obj->_unfocusAll;
	$obj->{FOCUSED} = 0;
}

sub add{
#shortcut to newWindow sub..
	my $obj=shift;
	return $obj->newWindow(@_);
}

sub _smartPlacement {
	my $obj = shift;
	my ($FrameH,$FrameW)=($obj->{MAINFRAME}->height,$obj->{MAINFRAME}->width);

	my $w=undef;
	my $h=undef;    

	if ($obj->_cget('-autoresize')){
		($h,$w)=($FrameH*2/3,$FrameW*3/4);
		if (defined $h and defined $w){
			if ($h+$obj->{SMARTXY} > $FrameH || $w+$obj->{SMARTXY}>$FrameW){
				$obj->{SMARTXY}=0;
			}
		}
	}
	else
	{ 
		if (    $obj->{SMARTXY} >= $FrameH-$obj->{SMARTDELTA} ||
			$obj->{SMARTXY} >= $FrameW-$obj->{SMARTDELTA} ){
				$obj->{SMARTXY}=0;
		}
	}
	return ($obj->{SMARTXY},$obj->{SMARTXY},$w,$h);
}


sub _cascade {
	my $obj=shift;
	$obj->{SMARTXY}=0;
	my $focusedWin = 0;
	my ($c,$maxY) = $obj->_getMinParams;
	#Restore any Maximized window.
	$obj->_revertMaxedWindow;
	#only cascade unminimized windows..and make sure to restore the Maximized windows
	foreach my $win (values  %{$obj->{WINS}}){
		next if $win->{ISMIN};

		#if ($win->{ISMAX}){
		#       $win->_restoreFromMax;
		#}

		if ($win->{HASFOCUS}){
			$focusedWin=$win;
			next;
		}

		my ($x,$y,$w,$h)=$obj->_smartPlacement;

		if (defined $w and defined $h){
			if ($x+$w > $obj->{MAINFRAME}->width || $y + $h > $maxY){
				$x = $y = $obj->{SMARTXY} = 0;
			}
		} else {
			if ($x >= $obj->{MAINFRAME}->width - $obj->{SMARTDELTA} ||
				$y > $maxY-$obj->{SMARTDELTA}) {
				$x = $y = $obj->{SMARTXY} = 0;
			}
		}
		$win->_TileMe($x,$y,$w,$h);
		$obj->{SMARTXY}+=$obj->{SMARTDELTA};
	}
	#Leave previously focused window on top..
	if ($focusedWin){
		my ($x,$y,$w,$h)=$obj->_smartPlacement;
		$x = $y = $obj->{SMARTXY} = 0 if ($x+$w > $obj->{MAINFRAME}->width ||
				$y +$h > $maxY);
		$focusedWin->_TileMe($x,$y,$w,$h);
		$obj->{SMARTXY}+=$obj->{SMARTDELTA};	    
	}
}

sub _minimizeAll {
	my $self = shift;
	$self->_revertMaxedWindow;
	foreach my $win (values %{$self->{WINS}}){
		$win->_minimizeWindow unless ($win->{ISMIN});
	}
}

sub _restoreAll {
	my $self = shift;
	$self->_revertMaxedWindow;
	foreach my $win (values %{$self->{WINS}}){
		$win->_restoreFromMin if ($win->{ISMIN});
	}

}

sub newWindow {
	my $obj = shift;
	my %args = @_;
	my $name = $args{-titletext} || "Untitled";
	$name=~s/\s*$/ /;
	$name = $name . $obj->{WINCOUNT}++;

	my ($x,$y,$w,$h) = $obj->_smartPlacement;

	#Disallow any maximized window
	$obj->_revertMaxedWindow;

	my $win = Tk::MDI::ChildWindow->new(
			-x	 => $x,
			-y	 => $y,
			-height    => $h,
			-width     => $w,
			-parent    => $obj->{MAINFRAME},
			-parentobj => $obj,
			-name     => $name,
			-titlebg   => $args{-titlebg},
	);

	$obj->{WINS}{$name}=$win;
	$win->_focusIt;

	if (defined $obj->{MENU}) {
		$obj->{MENU}->_addWindowToList($win);
	}
	$obj->{SMARTXY}+=$obj->{SMARTDELTA};
	return $win->mainFrame;
}

# This method is called by a child window when it is destroyed.

# TBD: the user should be able to specify an anon-sub that gets called
# here when a certain window closes, and the window is killed or not based
# on the return value of the subroutine.
# This is a private method.
sub _destroyMe {
	my ($self,$child) = @_;

	delete $self->{WINS}{$child->{NAME}};
	# need to remove title from menu.
	if (defined $self->{MENU}) {
		$self->{MENU}->_deleteWindowFromList($child);
	}
}

sub _getMinParams
{
# This sub returns the number of window NOT minimized and the maximum
# 'y' value which can be used so as NOT to cover up any minimized windows.
	my $obj = shift;
	my $count = 0;
	my $doNotCoverMe = 0;
	my $height = my $origheight = $obj->{MAINFRAME}->height;

	foreach my $win (values  %{$obj->{WINS}}){
		if ($win->{ISMIN}){
			my ($r) = split('~',$win->{MYSLOT});
			if ($doNotCoverMe < $r){
				$doNotCoverMe = $r;
				$height = $origheight * (1-($doNotCoverMe*0.04));
			}
		}
		else {
			$count++;
		}
	}
	return ($count,$height);
}


# This method is called by the Menu object when the user requests
# to tile the windows.
# This is a private method.

sub _tile
{
	my $obj = shift;
	my $dir = shift;

	#only tile unminimized windows.
	my ($count,$height)=$obj->_getMinParams;
	return unless $count;

	my $width  = $obj->{MAINFRAME}->width;

	#First restore any maximized window to its original spot.
	$obj->_revertMaxedWindow;
	
	if ($dir =~ /h/) {
		# With lots of windows - # of columns?
		my $columns = int(sqrt($count));
		$columns = $count if ($count<4);
		my $colindex = $columns-1;
		my $rows = int($count/$columns);
		my $extrarows = $rows + 1; 
		my $rowindex = $rows - 1;
		my $extra_columnstart = $columns - ($count%$columns);

		my $deltaY = $height / $rows;
		my $extraY = $height / $extrarows;
		my $deltaX  = $width / $columns;

		my $i = my $j = 0; 
		#place left to right first moving from top to bottom.
		for my $w (values %{$obj->{WINS}}) {
			next if ($w->{ISMIN});
			($i >= $extra_columnstart)? ($deltaY=$extraY):($deltaY = $height / $rows);
			$w->_TileMe($i*$deltaX, $j*$deltaY, $deltaX, $deltaY);
				if ($j == $rowindex && $i == $colindex){
					$j++;
					$i=$extra_columnstart;
				}
				elsif ($j < $rowindex && $i == $colindex){
					$i=0;
					$j++;
				}
				else{
					$i++;
				}
		}
	}
	else {
		#allow at least 100 pixels in height.
		my $maxrows = int($height/100);
		my $rows;
		if ($count > $maxrows){
			$rows = $maxrows;
		}
		else {
			$rows = $count;
		}
		my $rowindex = $rows - 1;
		my $columns = int ($count/$rows);
		my $extracolumns = $columns + 1;
		my $colindex = $columns - 1;
		my $extra_rowstart = $rows - ($count%$rows);

		my $deltaY = $height / $rows;
		my $extraX = $width / $extracolumns;
		my $deltaX  = $width / $columns;		


		my $i = my $j = 0; 
		#place top to bottom first then move left to right.
		for my $w (values %{$obj->{WINS}}) {
			next if ($w->{ISMIN});
			($i >= $extra_rowstart) ? ($deltaX=$extraX):($deltaX = $width / $columns);
			$w->_TileMe($j*$deltaX, $i*$deltaY, $deltaX, $deltaY);
				if ($j == $colindex && $i == $rowindex){
					$j++;
					$i=$extra_rowstart;
				}
				elsif ($j < $colindex && $i == $rowindex){
					$i=0;
					$j++;
				}
				else{
					$i++;
				}
		}
	}
}

sub shadow
{
#Uses place geometry manager - instead of form.
	my ($obj,$shadow)= @_;

	my $short=$obj->{EXTBD};
	my $long=10; #for now - this gets adjusted throughout
	if (defined $shadow){
		$obj->{SHADOWON}=$shadow;
		$obj->_configure(-shadow => $shadow);

		if ($shadow){
			$obj->{TOPSHADOW}= $obj->{MAINFRAME}->Frame(-width=>$long, -height=>$short, -bg=>'darkgray');
			$obj->{LEFTSHADOW}= $obj->{MAINFRAME}->Frame(-width=>$short, -height=>$long,-bg=>'darkgray');
			$obj->{BOTSHADOW} = $obj->{MAINFRAME}->Frame(-width=>$long, -height=>$short,-bg=>'darkgray');
			$obj->{RIGHTSHADOW} = $obj->{MAINFRAME}->Frame(-width=>$short, -height=>$long,-bg=>'darkgray');

			foreach (qw/TOPSHADOW LEFTSHADOW BOTSHADOW RIGHTSHADOW/){
				$obj->{$_}->place(-x=>-50,-y=>-50);
			}
		}
		else {
			$obj->{SHADOWON}=0;

			foreach (qw/TOPSHADOW LEFTSHADOW BOTSHADOW RIGHTSHADOW/){
				$obj->{$_}->destroy if (Tk::Exists $obj->{$_});
				delete $obj->{$_};
			}
		}
	}
	return $obj->_cget('-shadow');
}

sub _getShadowRefs
{
	my $obj = shift;
	return ($obj->{TOPSHADOW},$obj->{BOTSHADOW},$obj->{LEFTSHADOW},$obj->{RIGHTSHADOW});
}

sub _win32confineCursor
{
	my $self=shift;
	my $rootx=$self->{MAINFRAME}->rootx;
	my $rooty=$self->{MAINFRAME}->rooty;
	my $width=$self->{MAINFRAME}->width;
	my $height=$self->{MAINFRAME}->height;
    
	my @coords=($rootx,$rooty,$rootx+$width,$rooty+$height);

	my $rect = pack "L4" , @coords;

	if (defined $self->{CLIPCURSOR}){
		$self->{CLIPCURSOR}->Call($rect);
	} 
}

sub _win32releaseCursor
{
	my $self=shift;
	my $null=0;
	if (defined $self->{CLIPCURSOR}){
		$self->{CLIPCURSOR}->Call($null);
	} 
}

# This callback is available by a child window just before
# it is minimized.

sub _findMinimizeSlot {
	my ($self, $child) = @_;
	my $slotfound = 0;
	my $r=0;
	my $c;

	do {
		$r++;
		for ($c=0;$c<=4;$c++){
			next if ($self->{MINSLOT}[$r][$c]);
			$self->{MINSLOT}[$r][$c] = $child;
			$slotfound=1;
			last;
		}
	} until ($slotfound);

	return ($r,$c);
}

# This callback is available by a child window when it is minimized.
# This will be a public method in a future release.

sub IwasMinimized {
	my ($self, $child) = @_;

}

# This callback is triggered when a minimized window is restored or
# maximized.

sub IwasUnMinimized {
	my ($self, $child) = @_;
	my ($r,$c)=split('~',$child->_mySlot);
	$self->{MINSLOT}[$r][$c]=0;
}

# This callback is available by a child window when it is maximized.
# This is planned to be a public method.

sub IwasMaximized {
	my ($self, $child) = @_;
	#Restore the old maximized window to original spot.
	$self->_revertMaxedWindow;
	$self->{CURRENT_MAXWINDOW}=$child;
}

# This callback is triggered when a maximized window is restored or
# minimized.

sub IwasUnMaximized {
	my ($self, $child) = @_;
	$self->{CURRENT_MAXWINDOW}=0;
}

sub _revertMaxedWindow
{
	my $self = shift;
	#Restore any maximized window to its original spot.
	if ($self->{CURRENT_MAXWINDOW}){
		$self->{CURRENT_MAXWINDOW}->_revert;
	}
}

sub _isWindowMaxed { return $_[0]->{CURRENT_MAXWINDOW} }

sub _confineMethod { return $_[0]->{CONFINE} }

sub _getExtBD { return $_[0]->{EXTBD} }

sub _getIntBD { return $_[0]->{INTBD} }


# The following method gets called from the MDI::Menu object.
# It basically implements a drop down menu that gets called
# whenever the user right clicks on the main MDI window.
# The menu is identical to that available through the standard
# menu.

sub _bindToMenu {
    my ($obj, $menu) = @_;

    $obj->{MAINFRAME}->bind('<3>' => sub {
				$menu->Post($obj->{MW}->pointerxy)
				});
}

1;
__END__

=head1 NAME

Tk::MDI - Multiple Document Interface for Tk

=for category Tk Widget Classes

=head1 SYNOPSIS

	use Tk;
	use Tk::MDI;

	$mw = tkinit;
	$mdi = $mw->MDI(
		-style=>'win32',
		-background=>'white');

	$child1 = $mdi->add;
	$text = $child1->Text->pack;
	$text->insert('end',"A text widget");

	$child2 = $mdi->add(-titletext=>'Listbox Title');
	$lb = $child2->Listbox->pack;
	$lb->insert(0,"A Listbox");

	$child3 = $mdi->newWindow(-titlebg=>'white');
	$c = $child3->Scrolled('Canvas',-scrollbars=>'se')->pack;
	$c->create('text',50,50,-text=>"A Canvas");

	MainLoop;

=head1 STANDARD OPTIONS

The following standard widget options are supported:

B<-background/-bg>

=head1 WIDGET SPECIFIC OPTIONS

=over 4

=item Name B<menu>

=item Class B<Menu>

=item Switch B<-menu>

This option controls placement of the MDI menu. The MDI menu acts
as a control for child window placement. It allows for minimizing,
cascading, restoring and tiling child windows of the MDI object.

If this option can be specified in two ways..
If a reference to a user created menu is given, then the MDI menu
will be I<cascaded> to that menu. If no menu reference is given
then a new L<Menu|Tk::Menu> will be created to be accessible according
to the value of this I<-menu> option. In this case, the value shall
be one of: B<menubar>, B<popup>, B<both>, or B<none>.
The default value is B<both>.

The I<-menu> option is I<not> meant to be adjusted via the
configure method. It should really only be used at MDI creation.

=item Name B<focus>

=item Class B<Focus>

=item Switch B<-focus>

This option controls the focus policy of the child windows created
using the B<add> or B<newWindow> method as described below. The
value can be one of: B<click>, B<lazy> or B<strict>.
The default value is B<click>.

=over 4

=item Where:

=over 4

=item I<click>

I<ClickToFocus> - Clicking into a window activates it.

=item I<lazy>

I<FocusFollowsMouse> - Moving the mouse pointer actively onto a
window activates it.

=item I<strict>

I<FocusStrictlyUnderMouse> - Only the window under the mouse pointer
is active. If the mouse points nowhere, nothing has the focus.


=back

=back

=item Name B<shadow>

=item Class B<Shadow>

=item Switch B<-shadow>

Specifies whether or not a I<rubberband> or I<shadow> type rectangle
shall be used on a move or resize of a child window. This value must
be a proper boolean such as B<0> or B<1>.
The default value is: B<1> (i.e. B<on>).

=item Name B<autoresize>

=item Class B<AutoResize>

=item Switch B<-autoresize>

Specifies whether or not a child window should be automatically
resized to fit within the MDI parent frame. This value must be a
proper boolean such as B<0> or B<1>.
The default value is: B<0> (i.e. <off>).

Note: This is best turned on when using all of a similar type of 
widget - such as a Text widget (like a true MDI).

=item Switch B<-style>

Specifies the style of buttons to use in the decorative frame
surrounding the child windows. This will be enhanced in future
releases but as of this time is only supports the following values:
B<win32>, B<kde>, B<default>.
The default value is: B<default>.

NOTE: This currently cannot be changed by the configure method so
it MUST be stated at MDI creation in order to set the button images
properly.


=back

=head1 DESCRIPTION

This module emulates MDI type functionality with a twist.
The twist is ... virtually any Tk widget can be used! Hence,
the 'D' in MDI is somewhat of a misnomer.

The MDI method creates a new MDI window (i.e. a L<Frame|Tk::Frame>) and
returns a blessed reference to the MDI widget. The MDI widget is
created as a direct descendent of the Toplevel or MainWindow of
the calling $widget. The purpose of the MDI widget is to serve as
a container to confine I<child> windows; which can be created at
any time using the methods described below.

The MDI functionality has been designed to mimic as closely as
possible other MDI applications such as PFE and MSWord.

=head1 WIDGET METHODS

The B<MDI> method creates a new object.
This object supports the B<configure> and B<cget> methods
described in L<options|Tk::options> which can be used to enquire and
modify I<most> of the options described above.

The following additional methods are available for MDI widgets:

=over 4

=item I<$child>=I<$mdi>-E<gt>B<add>(?I<option, value, ...?>);

A shortcut to the B<newWindow> method.

=item I<$child>=I<$mdi>-E<gt>B<newWindow>(?I<option, value, ...?>);

Both B<add> and B<newWindow> create a new child window within
the MDI parent. These methods return the reference to a L<Toplevel|Tk::Toplevel>
window. You must then explicitly pack your widgets into this window.
Note: When you pack your widgets - it is a good idea to turn -expand on
and -fill both. This will allow your widgets to fill the Toplevel area
on a resize, cascade or tile.

Where allowable options are:

=over 4

=item B<-titletext>

A text string which will show in the titlebar of the child window.

=item B<-titlebg>

Color of the titlebar background when child window has focus.

=back

=item I<$child>-E<gt>B<destroy>;

Kill the MDI child window.

=back

=head1 CHILD WINDOW BINDINGS

All MDI child windows are confined to the MDI space. This is a standard
feature of MDI. On Win32 - this will work I<best> if you have L<Win32::API|Win32::API>
installed. If it is, then the windows will be confined using the native 
win32 'ClipCursor' API function. Otherwise, a perl only 'hack' is invoked.

=over 4

=item Move

To move a child window, left click on the titlebar and drag. If the I<-shadow>
option is on then only the outline of the window will be shown until you
release the button.

=item Resize

To resize a child window, left click on the outer frame. Drag as per move.

=item Shade

To roll up the child window like a 'shade' - Right click on the titlebar. 
Another right click will restore the window to it's previous position.

=back

=head1 KNOWN BUGS

This should be considered a Beta version. We would like feedback
on any bugs you find, or enhancements you would like to see. Please
read the ToDo list to see what we have planned.

On win32 - sometimes if a child window titlebar lies directly beneath
a menu item, the buttonrelease event from the menu will trigger
on that child window.

Titlebar 'flickers' on Enter and Leave events.

Still do not have keyboard focus working for internal widgets.

Smart placement needs to get smarter.

If run on a dual-monitored system - there may be some bugs in moving
or resizing a child window if the pointer is on the edge of the 
second screen.

=head1 AUTHORS

Ala Qumsieh E<lt>F<aqumsieh@hyperchip.com>E<gt>
Jack Dunnigan E<lt>F<jack.dunnigan@ec.gc.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Ala Qumsieh & Jack Dunnigan.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
