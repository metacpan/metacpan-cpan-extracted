######################################## SOH ###########################################
## Function : Alternate version for Tk:Optionbox with scroller, better for larger amounts
##            of selectable items
##
## Copyright (c) 2008 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V0.01	27-Feb-2008 	Class derived from original Optionbox. MK
##            V0.02 03-Mar-2008 	First usable version
##
######################################## EOH ###########################################
package Tk::PopUpSelectBox;
use Tk;

########################################################################
# ResizeCBox is a a slightly modified version of Damion K. Wilson's
# CornerBox (derived from Tk-DKW-0.03) Thanx.
########################################################################

package Tk::PopUpSelectBox::ResizeCBox;

use Tk::Canvas;
use Tk::Frame;

use vars qw ($VERSION);
use base qw (Tk::Frame);

$VERSION = '0.01';

#---------------------------------------------
use constant TRIMCOUNT	=> '3';
use constant MINSIZE_X	=> '100';
use constant MINSIZE_Y	=> '50';

#---------------------------------------------
Tk::Widget->Construct ('ResizeCBox');

#---------------------------------------------
sub Populate
{
	my ($this, $args) = @_;

	# retrieve extra option
	my $size = $this->{_size} = delete $args->{-size} || 20; $size = 15 if $size < 15;

    $this->SUPER::Populate (@_);

	#Widget Creation
	my $canvas = $this->Canvas(
    	-borderwidth => 0,
    	-highlightthickness => 0,
		-height => $size,
    	-width => $size,
	)->pack(
    	-fill => 'both',
    	-expand => '1',
	);
	$this->Advertise('canvas' => $canvas);

    $canvas->Tk::bind ('<ButtonPress-1>' => [\&Press, $this]);
    $canvas->Tk::bind ('<B1-Motion>' => [\&Resize, $this]);
    $canvas->Tk::bind ('<Configure>' => [\&Configure, $this]);
    $this->Tk::bind ('<Enter>' => [\&Enter, $this]);
    $this->Tk::bind ('<Leave>' => [\&Leave, $this]);

    return $this;
}

#---------------------------------------------
sub Configure
{
    my ($canvas, $this) = @_;

    return unless ($this->IsMapped());

    my $height = $this->height();
    my $width = $this->width();
	my $trimcount = TRIMCOUNT();

    $canvas->configure(-scrollregion => [0, 0, $width, $height]);

    unless (defined ($this->{'m_TrimList'})) {
        my $highColor = $this->Darken ($this->cget ('-background'), 150);
        my $lowColor = $this->Darken ($this->cget ('-background'), 60);

		my $scale = $this->{_size} / 2 * 3;
        for (my $l_Index = 0; $l_Index < $trimcount; ++$l_Index) {
            push (@{$this->{'m_TrimList'}},
                $canvas->create ('line', $scale, 0, 0, $scale, '-fill' => $highColor),
                $canvas->create ('line', $scale, 1, 1, $scale, '-fill' => $lowColor),
              );
		}
	}

    for (my $l_Index = 0; $l_Index <= $#{$this->{'m_TrimList'}}; $l_Index += 2) {
        my ($l_Light, $l_Dark) = @{$this->{'m_TrimList'}} [$l_Index .. ($l_Index + 1)];
        my $l_Divisor = (($l_Index + 2) / 2) - 1;

        $canvas->coords($l_Light,
            $width, ($height / ($trimcount + 1)) * $l_Divisor,
            ($width / ($trimcount + 1)) * $l_Divisor, $height,
          );

        $canvas->coords($l_Dark,
            $width, (($height / ($trimcount + 1)) * $l_Divisor) + 2,
            ($width / (($trimcount + 1)) * $l_Divisor) + 2, $height,
          );
	}
}

#---------------------------------------------
sub Enter
{
    $_[0]->{'m_Cursor'} = $_[0]->cget ('-cursor');
    $_[0]->configure ('-cursor' => ($^O =~ /^(MSWin32|DOS)$/ ? 'size_nw_se' : 'bottom_right_corner'));
}

#---------------------------------------------
sub Leave
{
    $_[0]->configure ('-cursor' => $_[0]->{'m_Cursor'} || 'arrow');
}

#---------------------------------------------
sub Press
{
    $_[1]->{'-deltax'} = $_[1]->pointerx();
    $_[1]->{'-deltay'} = $_[1]->pointery();
}

#---------------------------------------------
sub Resize
{
    my @geometry = split (/[+x]/, $_[1]->toplevel()->geometry());

	# Take care that we stay in the visible area
	my $x = $_[1]->pointerx();
	if ($x < 0) {
		$geometry [0] = $_[1]->{'-deltax'};
	}
	else {
	    $geometry [0] += ($x - $_[1]->{'-deltax'});
	    $_[1]->{'-deltax'} = $x;
	}
	
	my $y = $_[1]->pointery();
	if ($y < 0) {
		$geometry [1] = $_[1]->{'-deltay'};
	}
	else {
	    $geometry [1] += ($y - $_[1]->{'-deltay'});
	    $_[1]->{'-deltay'} = $y;
	}

	# Force absolute min-sizes of the steered window
	$geometry [0] = MINSIZE_X() if $geometry [0] < MINSIZE_X();
	$geometry [1] = MINSIZE_Y() if $geometry [1] < MINSIZE_Y();

	# Set the new geometry
    $_[1]->toplevel()->geometry($geometry [0] . 'x' . $geometry [1]);
}

1;

########################################################################
# For changing some aspects here we clone the TK-Tree Widget
########################################################################
package Tk::PopUpSelectBox::SelectTree;

use vars qw($VERSION);
$VERSION = '0.01';

use Tk qw(Ev);
use Tk::Derived;
use Tk::HList;
use base  qw(Tk::Derived Tk::HList);

#---------------------------------------------
Tk::Widget->Construct ('SelectTree');

my $minus_data = <<'minus_data_EOP';
	/* XPM */
	static char *xpm[] = {
	"13 13 2 1",
	". c none",
	"X c black",
	".............",
	".............",
	".............",
	"XXXXXXXXXXXXX",
	".XX.......XX.",
	"..XX.....XX..",
	"...XX...XX...",
	"....XX.XX....",
	".....XXX.....",
	"......X......",
	".............",
	".............",
	".............",
};
minus_data_EOP

my $minus_arm_data = <<'minus_arm_data_EOP';
	/* XPM */
	static char *xpm[] = {
	"13 13 3 1",
	". c none",
	"X c black",
	"a c red",
	".............",
	".............",
	".............",
	"XXXXXXXXXXXXX",
	".XXXXXXXXXXX.",
	"..XXXXXXXXX..",
	"...XXXXXXX...",
	"....XXXXX....",
	".....XXX.....",
	"......X......",
	".............",
	".............",
	".............",
	};
minus_arm_data_EOP

my $plus_data = <<'plus_data_EOP';
	/* XPM */
	static char *xpm[] = {
	"13 13 2 1",
	". c none",
	"X c black",
	"...X.........",
	"...XX........",
	"...XXX.......",
	"...X.XX......",
	"...X..XX.....",
	"...X...XX....",
	"...X....XX...",
	"...X...XX....",
	"...X..XX.....",
	"...X.XX......",
	"...XXX.......",
	"...XX........",
	"...X.........",
	};
plus_data_EOP

my $plus_arm_data = <<'plus_arm_data_EOP';
	/* XPM */
	static char *xpm[] = {
	"13 13 3 1",
	". c none",
	"X c black",
	"a c red",
	"...X.........",
	"...XX........",
	"...XXX.......",
	"...XXXX......",
	"...XXXXX.....",
	"...XXXXXX....",
	"...XXXXXXX...",
	"...XXXXXX....",
	"...XXXXX.....",
	"...XXXX......",
	"...XXX.......",
	"...XX........",
	"...X.........",
	};
plus_arm_data_EOP

my %indicators;
my %indicators_data = ('minus', $minus_data, 'minusarm', $minus_arm_data,
					   'plus', $plus_data, 'plusarm', $plus_arm_data);

#---------------------------------------------
sub ClassInit {
	my ($class, $window) = (@_);
	$class->SUPER::ClassInit($window);

	# Note these keyboard-Keys are only usable, if the widget gets 'focus'
	$window->bind($class, '<ButtonRelease-1>', sub { # print "DBG: reached function [BR-Release] with >@_<, called by >", caller, "<\n";
													  my $this = shift;
													  my $path = ($this->infoSelection)[0];
													  if (defined $path and $this->infoChildren($path)) {
														  my $mode = $this->getmode($path);
														  if ($mode eq 'open') { $this->open($path) }
														  elsif ($mode eq 'close') { $this->close($path) }
													  }
													}
	);

	# Auto-Select entries while hovering in the list/tree
    $window->bind($class, '<Motion>', sub {    my $this = shift;
												my $e = $this->XEvent;
												my $y = $e->y;
												my $inx = $this->nearest($y);
												if (defined $inx) {
													$this->anchorClear();
													$this->selectionClear();
													$this->selectionSet($inx);
												}
										    }
	);

 	# Keyboard selection
	$window->bind($class,'<KeyPress>', ['KeyPress', Ev('A')]);
}

#---------------------------------------------
sub Populate
{
	my ($this, $args) = @_;

	$this->SUPER::Populate($args);

	$this->ConfigSpecs(
        -ignoreinvoke => ['PASSIVE',  'ignoreInvoke', 'IgnoreInvoke', 0],
        -opencmd      => ['CALLBACK', 'openCmd',      'OpenCmd', 'OpenCmd' ],
        -indicatorcmd => ['CALLBACK', 'indicatorCmd', 'IndicatorCmd', 'IndicatorCmd'],
        -closecmd     => ['CALLBACK', 'closeCmd',     'CloseCmd', 'CloseCmd'],
        -indicator    => ['SELF', 'indicator', 'Indicator', 1],
        -indent       => ['SELF', 'indent', 'Indent', 15],
        -width        => ['SELF', 'width', 'Width', 20],
        -itemtype     => ['SELF', 'itemtype', 'Itemtype', 'imagetext'],
		-foreground   => ['SELF'],
	);

	# preset indicator images
	foreach (qw(plus plusarm minus minusarm)) {
    	$indicators{$_} = $this->Pixmap(-data => $indicators_data{$_});
	}
}

#---------------------------------------------
sub autosetmode
{
	shift->setmode();
}

#---------------------------------------------
sub IndicatorCmd
{
	my ($this, $ent, $event) = @_;

	my $mode = $this->getmode($ent);

	if ($event eq '<Arm>') {
		if ($mode eq 'open') {
			$this->_indicator_image($ent, 'plusarm');
		}
		else {
			$this->_indicator_image($ent, 'minusarm');
		}
	}
	elsif ($event eq '<Disarm>') {
		if ($mode eq 'open') {
			$this->_indicator_image($ent, 'plus');
		}
		else {
			$this->_indicator_image($ent, 'minus');
		}
	}
	elsif ($event eq '<Activate>') {
		$this->Activate($ent, $mode);
		$this->Callback(-browsecmd => $ent);
	}
}

#---------------------------------------------
sub close
{
	my ($this, $ent) = @_;
	my $mode = $this->getmode($ent);
	$this->Activate($ent, $mode) if ($mode eq 'close');
}

#---------------------------------------------
sub open
{
	my ($this, $ent) = @_;
	my $mode = $this->getmode($ent);
	$this->Activate($ent, $mode) if ($mode eq 'open');
}

#---------------------------------------------
sub getmode
{
	my ($this, $ent) = @_;

	return ('none') unless $this->indicatorExists($ent);

	my $img = $this->_indicator_image($ent);
	return ('open') if ($img eq 'plus' || $img eq 'plusarm');
	return ('close');
}

#---------------------------------------------
sub setmode
{
	my ($this, $ent, $mode) = @_;
	unless (defined $mode) {
		$mode = 'none';
		my @args;
		push(@args,$ent) if defined $ent;
		my @children = $this->infoChildren(@args);
		if (@children) {
			$mode = 'close';
			foreach my $c (@children) {
				$mode = 'open' if $this->infoHidden($c);
				$this->setmode($c);
			}
		}
	}

	if (defined $ent) {
		if ($mode eq 'open') {
			$this->_indicator_image($ent, 'plus');
		}
		elsif ($mode eq 'close') {
			$this->_indicator_image($ent, 'minus');
		}
		elsif ($mode eq 'none') {
			$this->_indicator_image($ent, undef);
		}
	}
}

#---------------------------------------------
sub Activate
{
	my ($this, $ent, $mode) = @_;
	if ($mode eq 'open') {
		$this->Callback(-opencmd => $ent);
		$this->_indicator_image($ent, 'minus');
	}
	elsif ($mode eq 'close') {
		$this->Callback(-closecmd => $ent);
		$this->_indicator_image($ent, 'plus');
	}
	else {
	}
}

#---------------------------------------------
sub OpenCmd
{
	my ($this, $ent) = @_;
	# The default action
	foreach my $kid ($this->infoChildren($ent)) {
		$this->show(-entry => $kid);
	}
}

#---------------------------------------------
sub CloseCmd
{
	my ($this, $ent) = @_;

	# The default action
	foreach my $kid ($this->infoChildren($ent)) {
		$this->hide(-entry => $kid);
	}
}

#---------------------------------------------
sub Command
{
	my ($this, $ent) = @_;

	return if $this->{Configure}{-ignoreInvoke};

	$this->Activate($ent, $this->getmode($ent)) if $this->indicatorExists($ent);
}

#---------------------------------------------
sub _indicator_image
{
	my ($this, $ent, $image) = @_;
	my $data = $this->privateData();
	if (@_ > 2) {
		if (defined $image) {
			$this->indicatorCreate($ent, -itemtype => 'image') unless $this->indicatorExists($ent);
			$data->{$ent} = $image;
			#$this->indicatorConfigure($ent, -image => $this->Getimage($image));
			$this->indicatorConfigure($ent, -image => $indicators{$image});
		}
		else {
			$this->indicatorDelete($ent) if $this->indicatorExists($ent);
			delete $data->{$ent};
		}
	}
	return $data->{$ent};
}



#----------------------------------------------------------------------
#               Accelerator key bindings
#----------------------------------------------------------------------
# inspired by tkIconList_KeyPress --
#
# Gets called when user enters an arbitrary key in the listbox.
#
sub KeyPress
{
    my ($w, $key) = @_;

    $w->{'_HLAccel'} .= $key;
    $w->Goto($w->{'_HLAccel'});
    eval { $w->afterCancel($w->{'_HLAccel_afterid'}) };
    $w->{'_HLAccel_afterid'} = $w->after(500, ['Reset', $w]);
}
sub Goto
{
    my ($w, $text) = @_;
	
	# Locals
	my (@children, $pattern, $selitem);

    return if (not defined $text or $text eq '');
	@children = $w->collectChildren();

	$pattern = qr/^(?i)$text/;
	foreach (@children) {
		$entry = $w->itemCget($_, 0, '-text');
		if ($entry =~ $pattern) {
			$selitem = $_;
			last
		}
	}
    if ($selitem) {
		$w->selectionClear();
		$w->selectionSet($selitem);
		$w->anchorSet($selitem);
		$w->see($selitem);
 		$w->Callback(-browsecmd =>$selitem);
   }
}
sub collectChildren
{
    my ($w, $item) = @_;

	# Locals
	my (@children, @grandchilds);
	@children = $w->infoChildren($item);
	foreach (@children) {
		push @grandchilds, $w->collectChildren($_)
	}
	return @children, @grandchilds;
}

sub Reset {
    my $w = shift;
    undef $w->{'_HLAccel'};
}

1;



########################################################################
# Here we start with the Real Widget
########################################################################


package Tk::PopUpSelectBox;

##############################################
### Use
##############################################
use Storable qw(freeze);
use Tk;

use Tk::Button;
use Tk::Tree;

use Carp qw(:DEFAULT cluck);

use vars qw ($VERSION);
use base qw(Tk::Frame);
use strict;

$VERSION = '1.0';


#---------------------------------------------
use constant DEFAULT_SEPARATOR	=> '.';
use constant MIN_BLOCK_TIME	=> '250'; # in ms


#---------------------------------------------
Tk::Widget->Construct ('PopUpSelectBox');


my $cbx_arrow = << 'cbx_arrow_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	/* columns rows colors chars-per-pixel */
	"11 14 2 1",
	"  c black",
	". c gray100",
	/* pixels */
	"...........",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	".         .",
	"..       ..",
	"...     ...",
	"....   ....",
	"..... .....",
	"...........",
	".         .",
	".         ."
	};
cbx_arrow_EOP

my $arrowdownwin = << 'arrowdownwin_EOP';
	/* XPM */
	static char *arrowdownwin[] = {
	/* columns rows colors chars-per-pixel */
	"9 13 2 1",
	"  c black",
	". c gray100",
	/* pixels */
	".........",
	".........",
	".........",
	".........",
	".........",
	"..     ..",
	"...   ...",
	".... ....",
	".........",
	".........",
	".........",
	".........",
	"........."
	};
arrowdownwin_EOP


#---------------------------------------------
sub Populate {
	# Parameters
	my ($this, $args) = @_;

	# Locals
	my ($var, $bttn, $tl, $list, $separator, %defaults);
	local $_;

	# check for special options
	$this->{'_ignoreExisting'} = delete $args->{-ignoreExisting};
	$separator = delete $args->{-separator} || DEFAULT_SEPARATOR();
	$this->{separator} = $separator;

	# Create a Closure for saving the current value
	$var = delete $args->{-variable};
	unless ($var) {
		my $gen = undef;
		$var = \$gen;
	}
	
	# Createa the widget
    $this->Tk::Frame::Populate($args);

    # store the os-style
    $this->{_style} = delete $args->{-style} || $Tk::platform;

    #my $bitmap = '@' . Tk->findINC($this->{_style} eq 'MSWin32' ? 'arrowdownwin.xbm' : 'cbxarrow.xbm');
    my $image = $this->Pixmap(-data => ($this->{_style} eq 'MSWin32' ? $arrowdownwin : $cbx_arrow));
	$bttn = $this->Button(
#			-bitmap => $bitmap,
			-image => $image,
			-relief => 'flat',
			-bd => 0,
			-padx => -1,
			-pady => -1,
	)->pack(-side => 'right', -anchor => 's');
    $this->Advertise('arrow' => $bttn);

    # popup shell for listbox with values.
    $tl = $this->Toplevel(-bd => 2, -relief => ($this->{_style} eq 'MSWin32' ? "solid" : "raised"));
    $tl->overrideredirect(1);
	$tl->minsize(30,30);
    $tl->withdraw;
	#my $fr = $tl->Frame(-relief => 'sunken', -borderwidth => 2)->pack(qw(-fill both -expand 1));
    #my $sl = $fr->Scrolled('SelectTree',
    my $sl = $tl->Scrolled('SelectTree',
		-scrollbars => 'e',
		-separator => $separator,
		-borderwidth => 0, -relief => 'flat',
		-selectmode => 'single',
		-command => sub {
							my $path = shift;
							my $tree = $this->{_tree};	
							my $mode = $tree->getmode($path);
							# Eventually open or close te child-tree
							if ($mode eq 'open') {
								$tree->open($path);
							}
							elsif ($mode eq 'close') {
								$tree->close($path);
							}
						},
 	)->pack(-expand => 1, -fill => 'both');
	#
    if ($this->{_style} eq 'MSWin32' and $Tk::platform eq 'MSWin32') {
		$sl->configure(-bg => 'SystemWindow', -relief => "flat");
    }
	my $tree = $this->{_tree} = $sl->Subwidget('scrolled');
	$tree->configure();

	# Position the Resizer in the lower right area of the scroller
	$sl->Subwidget('ysbslice')->ResizeCBox(-size => 15)->pack(
		-side => 'bottom', -anchor => 'se', -before => $sl->Subwidget('yscrollbar'), 
	);
	# Brush up the scroller
 	$sl->Subwidget('yscrollbar')->configure(-relief => 'flat', -width => 10, -borderwidth => 2);

	# Propagate the internal structure	
    $this->Advertise('window' => $tl);

    # other initializations
    # set bind tags
    $this->bindtags([$this, 'Tk::PopUpSelectBox', $this->toplevel, 'all']);

    # bindings for the button and entry
    $bttn->bind('<1>',[$this, 'button_down']);
    $bttn->toplevel->bind('<ButtonRelease-1>', [$this, 'button_restore']);
    $bttn->bind('<space>', [$this, 'space']);

    # bindings for listbox
    $tree->bind('<ButtonRelease-1>', sub { $this->list_selected(@_) });
    $tree->bind('<Escape>' => [$this, 'list_close']);
    $tree->bind('<Return>' => [$this, 'return', $tree]);
    $tree->bind('<Enter>' => sub { $this->{'_inside'} = 1 });
    $tree->bind('<Leave>' => sub { $this->{'_inside'} = 0 });

    # allow click outside the popped up listbox to pop it down.
    $this->bind('<1>','button_down');

    $this->{'_popped'} = 0;
    $this->Delegates(get => $bttn, DEFAULT => $bttn);

	# Setup DEFAULT Configs
	%defaults = (
    	-selectborderwidth	=> [$tree, 'selectBorderwidth', 'SelectBorderwidth', '1'],
    	-selectbackground	=> [$tree, 'selectBackground', 'SelectBackground', '#ececec'],
    	-selectforeground	=> [$tree, 'selectForeground', 'SelectForeground', 'Black'],
    	-activebackground	=> [$bttn, 'activeBackground', 'ActiveBackground', '#ececec'],
    	-activeforeground	=> [$bttn, 'activeForeground', 'ActiveForeground', 'Black'],
    	-takefocus			=> ['SELF', 'takefocus', 'Takefocus', 1],
    	-highlightthickness	=> ['SELF', 'highlightThickness', 'HighlightThickness', 1],
    	-borderwidth		=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-relief				=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'raised'],
    	-anchor				=> [['SELF', 'PASSIVE'], 'anchor', 'Anchor', 'w'],
    	#-ignoreExisting		=> [['SELF', 'PASSIVE'], 'ignoreExisting', 'IgnoreExisting', '0'],
    	-listbackground		=> [{-background => $tree}, 'background', 'Background', '#ececec'],
    	-font				=> ['DESCENDANTS', 'font', 'Font', 'Helvetica 12 bold'],
    	-variable 			=> ['PASSIVE', 'variable', 'Variable', $var],
    	-activate 			=> ['PASSIVE', 'activate', 'Activate', 1],
    	-separator 			=> ['PASSIVE', 'separator', 'Separator', $separator],
    	-options 			=> ['METHOD',  undef, undef, undef],
    	-command 			=> ['CALLBACK',undef,undef,undef],
    	-validatecommand	=> ['PASSIVE', 'validatecommand', 'ValidateCommand', sub {0}],

        -listwidth			=> [qw/PASSIVE  listWidth   ListWidth/,   undef],
        -listmaxheight		=> [qw/PASSIVE listMaxHeight ListMaxHeight 0/],
        -listcmd			=> [qw/CALLBACK listCmd     ListCmd/,     undef],
        -autolistwidth		=> [qw/PASSIVE autoListWidth AutoListWidth/, 1],
        -autolimitheight	=> [qw/PASSIVE autoLimitHeight AutoLimitHeight 1/],
        -state				=> [qw/METHOD   state       State         normal/],
    	-listheight 		=> ['METHOD',  undef, undef, undef],
        -image 				=> [ {-image => $bttn}, qw/arrowImage ArrowImage/, undef],
		-arrowimage			=> '-image',
		-rows				=> '-listheight',
		-buttontakefocus	=> [{-takefocus => $bttn}, 'buttonTakefocus', 'ButtonTakefocus', 1],
		-bitmap 			=> [{-bitmap => $bttn}, 'bitmap', 'Bitmap', 'question'],
		DEFAULT 			=> [$bttn]

	);	
	$this->ConfigSpecs(%defaults);

	$this->bind('<ButtonPress-3>'   => [$this => 'b3prs', Ev('x'), Ev('y')]);
	$this->bind('<ButtonRelease-3>' => [$this => 'b3rls', Ev('X'), Ev('Y')]);

	# Reset internal storage
	$this->{'_item_count'} = 0;
	$this->{'_item_width'} = 0;
	$this->{'_item_table'} = {};

}
	
#---------------------------------------------
sub listheight
{
    #print "DBG: reached function [listheight] with >@_<, called by >", caller, "<\n";
	my ($this, $height) = @_;

	my $oldh = $this->{_tree}->cget('-height');
   	$this->{_tree}->configure('-height' => $height + 1) if $height;
	return ($oldh);
}

#---------------------------------------------
sub state {
    my $this = shift;

    my $button = $this->Subwidget('arrow');

    if (@_) {
        $button->configure(-state => shift);
    }
	else {
        return $button->cget('-state');
    }
}

#---------------------------------------------
sub space
{
    my $this = shift;

	$this->button_down;
	$this->{'_savefocus'} = $this->focusCurrent;
	$this->Subwidget('list')->focus;
}

#---------------------------------------------
sub button_down
{
    #print "DBG: reached function [button_down] with >@_<, called by >", caller, "<\n";
    my $this = shift;
    return if $this->cget('-state') eq 'disabled';

    if ($this->{'_popped'}) {
		$this->list_popdown;
		$this->{'_button_restore'} = 0;
    } else {
		$this->popup;
		$this->{'_button_restore'} = 1;
    }
}

#---------------------------------------------
# triggered the listbox after selection
sub list_selected
{
	#print "DBG: reached function [list_selected] with >@_<, called by >", caller, "<\n";
    my $this = shift;
	return if $this->{'_popping'};
	
	if ($this->{'_inside'}) {
    	my $tree = $this->{_tree};
		my $path = ($tree->infoSelection)[0];

		# Do not take this click as a real selection, if it is a subhierarchy
		my @children = $tree->infoChildren($path);	
		if (@children) {
			#print "DBG: variable [\@children] = >@children<\n";
			my ($len, $child); $len = 0;
			foreach (@children) {
				if (length($_) > $len) {
					$child = $_;
					$len = length($_);
				}
			}
			# Show the last child if there is enough space in the list
			my $tmp1 = $tree->cget('-height');
			if (@children > $tree->cget('-height')) {
				$tree->see($children[0]);
			}
			else {
				$tree->see($children[-1]);
			}

			my $width = $this->fontMeasure($this->cget('-font'), $child);
			if ($this->cget('-autolistwidth') and defined $path and $path ne "") {
				my $geom = $tree->toplevel->geometry;
				my ($w, $h, $x, $y) = $geom =~ /(\d+)x(\d+)([+-]\d+)([+-]\d+)/;
				$w = int($width * 1.5) + ($tree->indicatorSize($path))[0];
				
				# if listbox is too far right, pull it back to the left
				$x = $this->vrootwidth - $w - 5 if (($x + $w) > $this->vrootwidth);

				# if listbox is too far left, pull it back to the right
				$x = 0 if $x < 0;
				$x = '+' . $x if ($x =~ /^\d/o);
				#print "DBG: variable [\$x] = >$x<\n";
				$tree->toplevel->geometry($w . 'x' . $h . $x . $y);
				#print "DBG: variable [\@geometry] = >@geometry<\n";
			}
			return;
		}

		my $value = $tree->infoData($path);
		$this->set_option($tree->itemCget($path, 0, '-text'), $value, $path);
	
		# ....
		$this->list_popdown();
	}
	#print "DBG: end function [list_selected]\n";
}
#---------------------------------------------
# close the listbox after restoring the button
sub list_release
{
    #print "DBG: reached function [list_release] with >@_<, called by >", caller, "<\n";
	my ($this, $x, $y) = @_;

	unless ($this->{'_inside'}) {
		$this->button_restore;
		$this->list_close($x, $y);
	}
}

#---------------------------------------------
# close the listbox after clearing selection
sub list_close
{
    #print "DBG: reached function [list_close] with >@_<, called by >", caller, "<\n";
    my $this = shift;

    my $tree = $this->{_tree};
    $tree->selectionClear();
    $this->list_popdown;
}

#---------------------------------------------
# pop down the listbox
sub list_popdown
{
    #print "DBG: reached function [list_popdown] with >@_<, called by >", caller, "<\n";
    my $this = shift;

    if ($this->{'_savefocus'} && Tk::Exists($this->{'_savefocus'})) {
		$this->{'_savefocus'}->focus;
		delete $this->{'_savefocus'};
    }
    if ($this->{'_popped'}) {
		my $c = $this->Subwidget('window');
		$this->{'_geometry'} = $c->geometry;
		$c->withdraw;
		$this->grabRelease;
		if (ref $this->{'_grabinfo'} eq 'CODE') {
			$this->{'_grabinfo'}->();
			delete $this->{'_grabinfo'};
		}
		# Restore the focus
	    $this->{'_focus'}->focus() if $this->{'_focus'};
		undef $this->{'_focus'};

		$this->{'_popped'} = 0;
    }
	$this->button_restore;
}

#---------------------------------------------
# Pressed ENTER bttn
sub return
{
    #print "DBG: reached function [return] with >@_<, called by >", caller, "<\n";
    my $this = shift;

    my $tree = $this->{_tree};
	my $path = $tree->infoSelection();
	my $value = $tree->infoData($path);
	$this->set_option($tree->itemCget($path, 0, '-text'), $value, $path);

	$this->list_popdown();
}

#---------------------------------------------
# This hack is to prevent the ugliness of the arrow being depressed.
sub button_restore
{
    #print "DBG: reached function [button_restore] with >@_<, called by >", caller, "<\n";
    my $this = shift;

    my $b = $this->Subwidget('arrow');
    if ($this->{'_button_restore'}) {
		$b->butUp;
		delete $this->{'_button_restore'};
    }
}

#---------------------------------------------
# displaying the selection list
sub popup
{
    #print "DBG: reached function [popup] with >@_<, called by >", caller, "<\n";
    my $this = shift;

    unless ($this->{'_popping'} or $this->{'_popped'}) {
		$this->{'_popping'} = 1;

		$this->Callback(-listcmd => $this);
		my $c = $this->Subwidget('window');
		my $a = $this->Subwidget('arrow');

		my $y1 = $a->rooty + $a->height / 2;
		my $bd = $c->cget(-bd) + $c->cget('-highlightthickness');
		# using the real listbox reqheight rather than the
		# container frame one, which does not change after resizing the
		# listbox
		my $ht = $this->{_tree}->reqheight + 4 * $bd + 2;
		$ht = $this->{_tree}->height + 4 * $bd + 2 if $this->{'_geometry'};
		$ht = 50 if $ht < 20;
		#print "DBG: variable [\$ht] = >$ht<\n";

		my $x1 = $a->rootx;
		
		my ($width, $x2);
		if (defined $this->cget('-listwidth')) {
	    	$width = $this->cget('-listwidth');
	    	$x2 = $x1 + $width;
		}
		else {
	    	$x2 = $a->rootx + $a->width;
	    	$width = $x2 - $x1;
		}
    	my $rw = $c->reqwidth;
    	if ($rw < $width) {
    	    $rw = $width
    	}
		else {
    	    if ($rw > $width * 3) {
    			$rw = $width * 3;
    	    }
    	    if ($rw > $this->vrootwidth) {
    			$rw = $this->vrootwidth;
    	    }
    	}
    	$width = $rw;

		# if listbox is too far right, pull it back to the left
		$x1 = $this->vrootwidth - $width if $x2 > $this->vrootwidth;

		# if listbox is too far left, pull it back to the right
		$x1 = 0 if $x1 < 0;


		# if listbox is below bottom of screen, pull it up.
		# check the Win32 taskbar, if possible
		my $rootheight;
		if ($Tk::platform eq 'MSWin32' and $^O eq 'MSWin32') {
	    	eval {
			require Win32Util; # XXX should not use a non-CPAN widget
			$rootheight = (Win32Util::screen_region($this))[3];
	    	};
		}
		$rootheight = $this->vrootheight unless defined $rootheight;


		my $y2 = $y1 + $ht;
		if ($y2 > $rootheight) {
	    	$y1 = $y1 - $ht - ($a->height - 5);
		}
		$this->after(MIN_BLOCK_TIME(), sub { $this->{'_popping'} = 0 });

		$y1 = 0 if $y1 < 0;
		if ($this->{'_geometry'}) {
			my @geometry = $this->{'_geometry'} =~ /(\d+)x(\d+)([+-]\d+)([+-]\d+)/;
			$rw = $geometry[0]; $ht = $geometry[1];
		}

		#print "DBG: variable [\$rw] = >$rw< [\$ht] = >$ht< [\$x1] = >$x1< [\$y1] = >$y1< \n";
		$c->geometry(sprintf('%dx%d+%d+%d', $rw, $ht, $x1, $y1));
		$c->deiconify;
		$c->raise;
		$this->{'_popped'} = 1;

		# highlight current selection
		# TODO - needed ?
		
		$c->configure(-cursor => 'arrow');
		$this->{'_grabinfo'} = $this->grabSave;
		$this->grabGlobal; #block all in system
		#$this->grab; # block only other windows in app
		
		# move the focus into the list to ease keyboard usage
	    $this->{'_focus'} = $this->focusCurrent();
		$this->{_tree}->focus();
    }
    #print "DBG: end function [popup]\n";
}
# Screen-move methods.

sub b3prs {
    my ($self, $x, $y) = @_;
    $self->{ofx} = $x;
    $self->{ofy} = $y;
} # end b3prs

sub b3rls {
    my($self, $X, $Y) = @_;
    $X -= $self->{ofx};
    $Y -= $self->{ofy};
    $self->geometry("+${X}+${Y}");
} # end b3rls

#---------------------------------------------
{
my ($List, $Separator, $FingerPrint); # Use global instead of func-arg for speed
	sub add_options
	{
		#print "DBG: reached function [add_options] with >@_<, called by >", caller, "<\n";

		# Parameters
    	my ($this, @args) = @_;

		# Locals
		my ($old, $var, $items, $test);

		#-----------------------------------------------------------------------------
		if (ref $args[0] eq 'ARRAY') {
			$items = $args[0];
		}
		elsif (@args) {
			$items = \@args;
		}

		#-----------------------------------------------------------------------------
		# Check if we already prepared exactly the same tree
		$test = freeze($items);
		return if $FingerPrint and $FingerPrint eq $test and $this->{'_item_count'} > 0;
		$FingerPrint = $test;
		#print "building new tree...\n";

		# Fake a busy state 
		my $a = $this->Subwidget('arrow');
		my $old_cursor = $a->cget('-cursor'); $a->configure(-cursor => 'watch');
		$a->update();

		$var = $this->cget('-variable');
		# Store old selection
		$old = $$var;

		# Clear & Fill the list with new values
		$List = $this->{_tree};
		$Separator = $List->cget('-separator');

		$List->delete('all');
		$this->{'_item_count'} = 0;
		$this->{'_item_width'} = 0;
		$this->{'_item_table'} = {};

		
		$this->_add_option('', $items);
		#-----------------------------------------------------------------------------
		#print "DBG: variable [$this->{'_item_count'}] = >", $this->{'_item_count'}, "<\n";		
		
    	$this->limitheight() if $this->cget('-autolimitheight'); 
		$this->updateListWidth() if $this->cget('-autolistwidth');

		$a->configure(-cursor => $old_cursor);
		$a->update();
	}

	#-----------------------------------------------------------------------------
	sub _add_option
	{
    	#print "DBG: reached function [_add_option] with >@_<, called by >", caller, "<\n";
		# Parameters
    	my ($this, $parent, $items) = @_;

		my ($item, $path, $label, $value, $width);

		foreach $item (@$items) {
			if (ref $item) {
				($label, $value) = @$item
			}
			else {
				$label = $value = $item
			}

			if (ref $label) {
				if ($parent eq '') {
					$path = $label->[0];
				}
				else {
					$path = $parent . $Separator . $label->[0];
				}
				$List->add($path, -text => $label->[0], -data => undef) unless $List->infoExists($path);
				$this->_add_option($path, $label->[1]);
				$List->Activate($path, 'close');
				$this->{'_item_count'}++ unless $parent; #count only toplevel entries
			}
			else {
				if ($parent eq '') {
					$path = $label;
				}
				else {
					$path = $parent . $Separator . $label;
				}
				if ($List->infoExists($path)) {
					croak "Entry already exists!\n" unless $this->{'_ignoreExisting'}; 
				}
				else {
					$List->add($path, -text => $label, -data => $value);
					#print "DBG: variable [\$path] = >$path< [\$label] = >$label< [\$value] = >$value<\n";
					# Update internal storages
					$this->{'_item_count'}++ unless $parent; #count only toplevel entries
					$this->{'_item_table'}{$path} = $value;
					$width = $this->fontMeasure($this->cget('-font'), $label);
					$this->{'_item_width'} = $width if $width > $this->{'_item_width'};
				}
			}
		}
		#print "end function [_add_option]\n";
	}
}
#-----------------------------------------------------------------------------
sub limitheight
{
    my $this = shift;

    my $listheight = shift || $this->{'_item_count'};
	#print "DBG: variable 1 [\$listheight] = >$listheight<\n";
	my $listmaxheight = $this->cget('-listmaxheight');
    $listheight = $this->cget('-listmaxheight') if $listmaxheight > 0 and $listheight > $listmaxheight;
    $this->configure(-listheight => $listheight) if ($listheight > 0);
}

#-----------------------------------------------------------------------------
sub updateListWidth
{
    #print "DBG: reached function [updateListWidth] with >@_<, called by >", caller, "<\n";
    my $this = shift;

	my $width = $this->{'_item_width'};
	#print "DBG: variable [\$width] = >$width<\n";
    if ($this->{'_item_width'} > 10) { # be sane
		$this->configure(-listwidth => $this->{'_item_width'} + 5); # + XXX for scrollbar
    }
}

#---------------------------------------------
sub set_option
{
    #print "DBG: reached function [set_option] with >@_<, called by >", caller, "<\n";
	# Parameters
	my ($this, $label, $value, $full_label) = @_;
	# Locals
	my ($failed, $validatecommand, $variable, $textvariable, $old_label, $old_value);
	
	# Some presettings
	$value = $label if @_ == 2;
	$full_label = $label unless $full_label;
	return if $full_label eq "";

	$validatecommand = $this->cget('-validatecommand');
	$textvariable = $this->cget('-variable');
	$variable = $this->cget('-variable');

	$old_value = $variable ? $$variable : $this->{OldValue};
	$old_label = $$textvariable;
	
	# Perform validate operation, if available
	do { $failed = &$validatecommand ($this, $value, $label, $full_label, $old_value, $old_label) } if $validatecommand;
	
	#Do the changes
	unless ($failed) {
		$$variable = $value if $variable;
		$this->{OldValue} = $value;
		$$textvariable = $label;

		my $list = $this->{_tree};
		$list->selectionClear();
		$list->selectionSet($full_label);
		$list->see($full_label);

		# Now invoke the callback
		$this->{CallBackActive} = 1;
		$this->Callback(-command => $value, $label, $full_label);
		delete $this->{CallBackActive};
	}
}

#---------------------------------------------
sub options
{
	my ($this, $opts) = @_;
	if (@_ > 1) {
		if ($this->{CallBackActive}) {
			cluck "\nTk::PopupSelectionBox Error: Found an illegal recursion loop: from Callback() to options() which is not allowed!\nAuto-shutting-down now, please let the developer fix this!";
			kill 9, $$;
		}
		$this->add_options($opts);
	}
	else {
		#return $this->_cget('-options');
	}

}
#---------------------------------------------
sub itemtable
{
	my $this = shift;
	my %itemtable = $this->{'_item_table'} ? %{$this->{'_item_table'}} : ();

	return wantarray ? %itemtable : \%itemtable;
}

########################################################################
1;
__END__


=head1 NAME

Tk::PopUpSelectBox - A new scrolled pop-up selection-widget (with MULTI-level selections) 

=head1 SYNOPSIS

    use Tk;
    use Tk::PopUpSelectBox

    my $current_class;
    my @all_classes = qw(cat dog bird);
    my $demo_xpm;
	
    my $mw = MainWindow->new();
	
    # prepare some graphics
    setup_pixmap();

    # create a demo 
    my $popupselectbox = $mw->PopUpSelectBox (
        -text     => "Class",
        -image    => $demo_xpm, # use this line for personal pics or
        #-bitmap  => '@' . Tk->findINC('cbxarrow.xbm'));
        -command  => \&class_cb,
        -options  => [ @all_classes ],
        -variable => \$current_class, 
		-tearoff  => '1',
		-listmaxheight => 10,
		-activate => '0',
   )->pack;
	
    Tk::MainLoop;
	
    sub class_cb
    {
        print "class_cb called with [@_], \$current_class = >$current_class<\n";
    }
    sub setup_pixmap
    {
        my $cbxarrow_data = <<'cbxarrow_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	"11 14 2 1",
	". c none",
	"  c black",
	"...........",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	".         .",
	"..       ..",
	"...     ...",
	"....   ....",
	"..... .....",
	"...........",
	".         .",
	".         ."
	};
cbxarrow_EOP

        $demo_xpm = $mw->Pixmap(-data => $cbxarrow_data);
    }
	

=head1 DESCRIPTION

A new dialog style widget that can replace the custom Optionbox whenever the itemlist is too long.
Useful in applications that want to use a more flexible option menu. 
It's a 1:1 replacement for the custom Optionbox, supporting the same Options / commands.

You can tie a scalar-value to the Optionbox widget, enable/disable it,
assign a callback, that is invoked each time the Optionbox is changed,
as well as set Option-values and configure any of the options
understood by Tk::Frame(s) like -relief, -bg, ... .
(see docs of TK::Optionmenu) for details

=head1 METHODS

=over 4

=item B<set_option()>

'set_option($newvalue)' allows to set/reset the widget methodically,
$newvalue will be aplied to the labeltext (if visible) and the internal
variable regardless if it is a list previously store in options.

NOTE: You should prefer interacting with the widget via a variable.


=item B<add_options()>

'add_options(@newoptions)' allows to enter additonal options that will be
displayed in the pull-down menu list.

You should prefer to use a Configure ('-options' => ...).

NOTE: Unless You specify -activate => 0 for the widget each time you use
add_options the first item will be set to be the current one and any assigned
callback gets called.

=item B<popup()>

'popup()' allows to immediately popup the menu to force the user
to do some selection.

=item B<itemtable()>

'itemtable()' retrieves a list of all current selection items.
Requesting a listcontext retrieves a label/value based hash, retrieving
a scalar retrieves a hash-ref. NOTE the B<-separator> setting for
the hierarchical delimiter wherever applied.

=back


=head1 OPTIONS

=over 4

=item B<-variable>

'-variable' allows to specify a reference to a scalar-value.
Each time the widget changes by user interaction, the variable
is changed too. Every variable change is immediately mapped in the
widget too.


=item B<-command>

'-command' can be used to supply a callback for processing after
each change of the Option value.
This callback receives as parameters 'current' value + label + full-label
for hierarcical (sub)lists. NOTE the B<-separator> setting for
the hierarchical delimiter applied for full-label.

=item B<-image>

'-image' can be used to supply a personal bitmap for the menu-button.
In difference to the original Optionmenu the std. menu-indicator is
switched off, if a graphic/bitmap is used , although it might
be re-enabled manually with a B<'-indicatoron =\> 1'> setting.
If no image and no bitmap is specified the text given with B<'-text'>
or the current selected optiontext is displayed in the button.

=item B<-options>

'-options' expects a reference to a list of options.

plain format: label, label, [ label, value ], [ label, value ], [ label, value ], ...
multi-level selection: The methodology is the same as before:
Whenever instead of a label an Array-reference is found it is suggested as a subitem-list.
It is poosible to mix plain items, items with spec'd values other than the label in any level.
example: label, label, [ label, value ], [[keylabel, \@subopts], undef], [ label, value ],
See the supplied example for further information.

=item B<-activate>

'-activate' expects 0/1 and rules whether the first item applied with -options gets
set 'current'. see NOTE above.

=item B<-listmaxheight> or B<-rows>

'-listmaxheight' defines the height of the selection list. default is 20.

=item B<-separator>

'-separator' defines the separator character that is used for the internal representation
of the tree delimiter. Invoking a callback via set_options the target function get [value,
label & full-hierarchical label]. The f-h-label uses the specified separator. Default is '.'

=item B<-autolistwidth>

'-autolistwidth' expects 0/1 and defines whether the pop'd up list will dynamically adapt its width.

=item B<-autolimitheight>

'-autolistwidth' expects 0/1 and defines whether the pop'd up list will not be heigher than the value
definable via '-listmaxheight'

=item B<-validatecommand>

'-validatecommand' defines a Callback function to evaluate the current selection.
It is invoked with B<the_widget>, B<value>, B<label>, B<full_label>, B<old_value> and B<old_label>.
Returning B<FALSE> will reject the current selection.

=back

Please see the TK:Optionmenu docs for details on all other aspects
of these widgets.


=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V0.02  (C) March 2008

=cut

###
### EOF
###

