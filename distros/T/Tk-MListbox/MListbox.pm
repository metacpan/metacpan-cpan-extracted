## MListbox Version 1.11 (26 Dec 2001)
##
## Original Author: Hans J. Helgesen, Dec 1999  
## Maintainer: Rob Seegel (versions 1.10+)
##
## This version is a maintenance release of Hans' MListbox widget.
## I have tried to avoid adding too many new features and just ensure 
## that the existing ones work properly.
## 
## Please post feedback to comp.lang.perl.tk or email to RobSeegel@aol.com
##
## This module contains four classes. Of the four MListbox is
## is the only one intended for standalone use, the other three:
## CListbox, MLColumn, HButton are accessible as Subwidgets, but
## not intended to be used in any other way other than as 
## components of MListbox
##
##############################################################################
## CListbox is similar to an ordinary listbox, but with the following 
## differences:
## - Calls an -updatecommand whenever something happens to it.
## - Horizontal scanning is disabled, calls -xscancommand to let parent widget
##   handle this.
{
    package Tk::CListbox;
    use base qw(Tk::Derived Tk::Listbox);

    Tk::Widget->Construct('CListbox');
    
    sub Populate {
        my ($w, $args) = @_;
        $w->SUPER::Populate($args);
        $w->ConfigSpecs(
            -background    => [qw/SELF background Background/, $Tk::NORMAL_BG],
            -foreground    => [qw/SELF foreground Foreground/, $Tk::NORMAL_FG],
            -updatecommand => ['CALLBACK'],
            -xscancommand  => ['CALLBACK']
        );
    }
   
    sub selectionSet {
        my ($w) = @_;
        $w->Callback(-updatecommand=>$w->can('SUPER::selectionSet'),@_);
    }
    sub selectionClear {
        my ($w)=@_;
        $w->Callback(-updatecommand=>$w->can('SUPER::selectionClear'),@_);
    }
    sub selectionAnchor {
        my ($w)=@_;
        $w->Callback(-updatecommand=>$w->can('SUPER::selectionAnchor'),@_);
    }
    sub activate {
        my ($w)=@_;
        $w->Callback(-updatecommand=>$w->can('SUPER::activate'),@_);
    }
    sub see {
        my ($w)=@_;
        $w->Callback(-updatecommand=>$w->can('SUPER::see'),@_);
    }
    sub yview {
        my ($w)=@_;
        $w->Callback(-updatecommand=>$w->can('SUPER::yview'),@_);     
    }
    sub scan {
        my ($w,$type,$x,$y) = @_;
        # Disable horizontal scanning.
        if ($type eq 'mark') {
	    $w->{'_scanmark_x'} = $x;
        }
        $w->Callback(-updatecommand=>$w->can('SUPER::scan'),
	    $w, $type, $w->{'_scanmark_x'}, $y
        );
        $w->Callback(-xscancommand=>$type,$x);
    }
}

##############################################################################
## HButton is like an ordinary Button, but with an addition option:
## -pixelwidth
## The new configure method makes sure the pixelwidth is always retained.
{
    package Tk::HButton;
    use base qw(Tk::Derived Tk::Button);   
    Tk::Widget->Construct('HButton');
    
    sub Populate {
        my ($w, $args) = @_;
        $w->SUPER::Populate($args);
        $w->ConfigSpecs(
            -pixelwidth => ['PASSIVE'],
            -background    => [qw/SELF background Background/, $Tk::NORMAL_BG],
            -foreground    => [qw/SELF foreground Foreground/, $Tk::NORMAL_FG]
	);
    }

    sub configure {
        my $w = shift;
        my (@ret) = $w->SUPER::configure(@_);
        unless (@ret) {
	    if (defined(my $pixels = $w->cget('-pixelwidth'))) {
	        $w->GeometryRequest($pixels,$w->reqheight);
	      }
	}
        return @ret;
    }
}

###############################################################################
## MLColumn implements a single column in the MListbox. MLColumn is a composite
## containing a heading (an HButton), a listbox (CListbox) and a frame which  
## frame which serves as a draggable separator 
{
    package Tk::MLColumn;
    use base qw(Tk::Frame);
    Tk::Widget->Construct('MLColumn');
    
    sub Populate {
	my ($w, $args) = @_;
	$w->SUPER::Populate($args);
       
        ## MLColumn Components
        ## $sep - separator - Frame
        ## $hdr - heading    - HButton
        ## $f   - frame     - Frame	
        ## $lb  - listbox   - CListbox

	my $sep = $w->Component(
            Frame   => 'separator',
            -height => 1
        )->pack(qw/-side right -fill y -anchor w/);

	$sep->bind( "<B1-Motion>", 
            [$w=>'adjustMotion']);
	$sep->bind("<ButtonRelease-1>", 
            [$w=>'Callback','-configurecommand']);

	my $f = $w->Component(
            Frame => "frame"
	)->pack(qw/-side left -anchor e -fill y -expand 1/);
	
	my $hdr = $f->HButton(
            -takefocus=>0,
	    -padx=>0,
	    -width=>1,
	    -borderwidth=>2,
            -highlightthickness=>0
        )->pack(qw/-side top -anchor n -fill x/);
	$w->Advertise("heading" => $hdr);
	
	my $lb = $f->CListbox(
	    -highlightthickness=>0,
	    -relief=>'flat',
	    -bd=>0,
	    -exportselection=>0,
	    -takefocus=>0
        )->pack(qw/-side top -anchor n -expand 1 -fill both/);
	$w->Advertise("listbox" => $lb);
   	
	$w->Delegates (DEFAULT => $lb);
	


	$w->ConfigSpecs(
	    -background     => [[$f, $hdr, $lb], 
                                qw/background Background/, $Tk::NORMAL_BG],
            -comparecommand => ['CALLBACK', undef, undef,
                sub{$_[0] cmp $_[1]}],
	    -configurecommand => ['CALLBACK'],

	    -font           => [[$hdr, $lb], qw/font Font/, undef],
            -foreground     => [[$hdr, $lb],
                                qw/foreground Foreground/, $Tk::NORMAL_FG],
	    -separatorwidth => [{-width => $sep}, 
                                qw/separatorWidth Separator 1/],
	    -separatorcolor => [{-background => $sep}, 
                                qw/sepaatorColor Separator black/],
	    -resizeable     => [qw/METHOD resizeable Resizeable 1/],
	    -sortable       => [qw/PASSIVE sortable Sortable 1/],
	    -text           => [$hdr],
	    -updatecommand  => [$lb],
	    -textwidth      => [{-width => [$lb, $hdr]}],
	    DEFAULT         => [$lb]
	);
	$w->ConfigAlias(
	    -comparecmd => '-comparecommand',
	    -width      => '-textwidth'
        );

    }

######################################################################
## MLColumn Configuration methods (call via configure/cget). 
######################################################################

    sub resizeable {
        my ($w, $value) = @_;
        return $w->{Configure}{-resizeable} unless
            defined $value;
        $w->Subwidget("separator")->configure(
            -cursor => ($value ? 'sb_h_double_arrow' : 'xterm')
        );
    }

    sub compare {
        my ($w,$a,$b) = @_;
        $w->Callback(-comparecommand => $a, $b);
    }

    sub setWidth {
        my ($w, $pixels) = @_;
        $pixels -= $w->Subwidget("separator")->width;
        return 
            unless $pixels >= 0;
    
        $w->Subwidget("listbox")->GeometryRequest(
            $pixels,$w->Subwidget("listbox")->height);
        $w->Subwidget("heading")->configure(-pixelwidth=>$pixels);
    }

######################################################################
## MLColumn Private  methods (Do not depend on these methods being present)
######################################################################

## Adjust size of column.
    sub adjustMotion {
        my ($w) = @_;    
        $w->setWidth($w->pointerx - $w->rootx);
    }

} ## END PRELOADING OF MLColumn

######################################################################
## Package: Tk::MListbox
## Purpose: Multicolumn widget used to display tabular data
##          This widget has the ability to sort data by column,
##          hide/show columns, and the ability to change the order
##          of columns on the fly

package Tk::MListbox;
use strict;
use Carp;
use vars qw($VERSION);
$VERSION = '1.11';

use Tk;

## Overidden Scrolled method to suit the purposes of MListbox
## I want -columns to be configured LAST no matter what.
## I know full well that I'm overriding the Scrolled method
## and I don't need a warning broadcasting the fact.

no warnings;
sub Tk::Widget::Scrolled {
    my ($parent, $kind, %args) = @_;
 
    my $colAR;
    $colAR = delete $args{'-columns'} if $kind eq "MListbox";

    ## Find args that are Frame create time args
    my @args = Tk::Frame->CreateArgs($parent,\%args);
    my $name = delete $args{'Name'};
    push(@args,'Name' => $name) if (defined $name);
    my $cw = $parent->Frame(@args);
    @args = ();

    ## Now remove any args that Frame can handle
    foreach my $k ('-scrollbars',map($_->[0],$cw->configure)) {
        push(@args,$k,delete($args{$k})) if (exists $args{$k})
    }
    ## Anything else must be for target widget - pass at widget create time
    my $w  = $cw->$kind(%args);

    ## Now re-set %args to be ones Frame can handle
    ## RCS NOTE: I've also slightly modified the ConfigSpecs
    %args = @args;
    $cw->ConfigSpecs(
        '-scrollbars' => [qw/METHOD   scrollbars Scrollbars se/],
        '-background' => [$w, qw/background Background/, undef],
        '-foreground' => [$w, qw/foreground Foreground/, undef],
    );
    $cw->AddScrollbars($w);
    $cw->Default("\L$kind" => $w);
    $cw->Delegates('bind' => $w, 'bindtags' => $w, 'menu' => $w);
    $cw->ConfigDefault(\%args);
    $cw->configure(%args);
    $cw->configure(-columns => $colAR) if $colAR;
    return $cw;
}
use warnings;

require Tk::Pane;
use base qw(Tk::Frame);
Tk::Widget->Construct('MListbox');

sub ClassInit {
    my ($class,$mw) = @_;
    $mw->bind($class,'<Configure>',['_yscrollCallback']);
    $mw->bind($class,'<Down>',['_upDown',1]);
    $mw->bind($class,'<Up>',  ['_upDown',-1]);
    $mw->bind($class,'<Shift-Up>',  ['_extendUpDown',-1]);
    $mw->bind($class,'<Shift-Down>',['_extendUpDown',1]);
    $mw->bind($class,'<Control-Home>','_cntrlHome');
    $mw->bind($class,'<Control-End>','_cntrlEnd');
    $mw->bind($class,'<Shift-Control-Home>',['_dataExtend',0]);
    $mw->bind($class,'<Shift-Control-End>',['_dataExtend',Ev('index', 'end')]);
    $mw->bind($class,'<Control-slash>','_selectAll');
    $mw->bind($class,'<Control-backslash>','_deselectAll');
}

## Do some slightly tricky stuff: The -columns option, if called is
## guaranteed to be confiugred last of all the options submitted.
## NOTE: The args hash is cleared out if a columns option is sent
## so that all the options won't be reconfigured again immediately
## after this method finishes. ALso, if Scrolled is called, then
## the -columns option will never make it down to this level so 

sub InitObject {
    my ($w, $args) = @_;

    my $colAR = delete $args->{'-columns'};
    $w->Populate($args);
    $w->ConfigDefault($args);
    if ($colAR) {
        $w->configure(%$args);
        $w->configure(-columns => $colAR);
        %$args = ();
    }
}

sub Populate {
    my ($w, $args) = @_;

#    $w->SUPER::Populate($args);   

    $w->{'_columns'} = [];          ## Array of MLColumn objects 
    $w->{'_sortcol'} = -1;          ## Column used for sorting
    $w->{'_sort_descending'} = 0;   ## Flag for ascending/desc. sort order
    $w->{'_top'} = 0;
    $w->{'_bottom'} = 0;

    my $pane = $w->Component(
        Pane => "pane",
        -sticky => 'nsew'
    )->pack(-expand=>1,-fill=>'both');

    my $font;
    if ($Tk::platform eq 'MSWin32') {
        $font = "{MS Sans Serif} 8";
    } else {
        $font = "Helvetica -12 bold";
    }

    $w->ConfigSpecs(
        -background        => [qw/METHOD background Background/, 
		              $TK::NORMAL_BG ],
        -columns           => [qw/METHOD/],
	-configurecommand  => [qw/CALLBACK/],
        -font              => [qw/METHOD font Font/, $font],
        -foreground        => [qw/METHOD foreground Foreground/,
                              $Tk::NORMAL_FG ],
	-height            => [qw/METHOD height Height 10/],
	-moveable          => [qw/PASSIVE moveable Moveable 1/],
        -resizeable        => [qw/METHOD resizeable Resizeable 1/],
        -selectbackground  => [qw/METHOD selectBackground Background/, 
			      $Tk::SELECT_BG],
        -selectborderwidth => [qw/METHOD selectBorderwidth Borderwidth 1/],
        -selectforeground  => [qw/METHOD selectForeground Foreground/,
			      $Tk::SELECT_FG],
        -selectmode        => [qw/METHOD selectMode Mode browse/],
        -separatorcolor    => [qw/METHOD separatorColor Separator black/],
        -separatorwidth    => [qw/METHOD separatorWidth Separator 1/], 
	-sortable          => [qw/METHOD sortable Sortable 1/],
        -takefocus         => [qw/PASSIVE takeFocus Focus 1/],
        -textwidth         => [qw/METHOD textWidth Width 10/],
        -width             => [qw/METHOD width Width/, undef],
      	-xscrollcommand    => [$pane],
	-yscrollcommand    => ['CALLBACK'],  
    );

    $w->ConfigAlias(
        -selectbg => "-selectbackground",
        -selectbd => "-selectborderwidth",
	-selectfg => "-selectforeground",
        -sepcolor => "-separatorcolor",
        -sepwidth => "-separatorwidth",
    );
}

######################################################################
## Configuration methods (call via configure). 
######################################################################

## Background is a slightly tricky option, this option would be a 
## great candidate for "DESCENDANTS", except for the separator subwidget in
## each column set by separatorcolor which I'd prefer not to set in such
## a clumsy way. All other background colors are fair game, but I'd like 
## to leave open the possibility for other exceptions such as separator. 
## Besides I prefer that composite subwidgets manage their own component parts
## as much as possible.

sub background { 
    my ($w, $val) = @_;
    return $w->{Configure}{'-background'}
        unless $val;
  
    ## Ensure that the base Frame, pane and columns (if any) get set
    Tk::configure($w, "-background", $val);
    $w->Subwidget("pane")->configure("-background", $val);
    $w->_configureColumns("-background", $val);
}

## columns needs to be called last during creation time if set and I 
## went to a great deal of trouble to guarantee this. The reason
## being is that it needs to use many of the other configurations to
## use as defaults for columns, and the ability to override any of them
## for individual columns. If these options (that the columns override)
## were called afterwards, then the reverse would happen. All the default
## would override the individually specified options.

sub columns {
    my ($w, $vAR) = @_;
    return $w->{Configure}{'-columns'} unless
        defined $vAR;
    $w->columnDelete(0, 'end');
    map {$w->columnInsert('end', @$_)} @$vAR; 
}

sub font              { shift->_configureColumns('-font', @_) }
sub foreground        { shift->_configureColumns('-foreground', @_) }
sub height            { shift->_configureColumns('-height', @_) }
sub resizeable        { shift->_configureColumns('-resizeable', @_) }
sub selectbackground  { shift->_configureColumns('-selectbackground', @_) }
sub selectborderwidth { shift->_configureColumns('-selectborderwidth', @_) }
sub selectforeground  { shift->_configureColumns('-selectforeground', @_) }
sub selectmode        { shift->_configureColumns('-selectmode', @_) }
sub separatorcolor    { shift->_configureColumns('-separatorcolor', @_ ) }
sub separatorwidth    { shift->_configureColumns('-separatorwidth', @_ ) }
sub sortable          { shift->_configureColumns('-sortable', @_) }
sub textwidth         { shift->_configureColumns('-textwidth', @_) }

sub width {
    my ($w, $v) = @_;

    return $w->{Configure}{'-width'} unless defined $v;
    if ($v == 0) {
        $w->afterIdle(['_setWidth', $w]);
    } else {
        $w->Subwidget('pane')->configure(-width => $v);
    }
}

######################################################################
## Private  methods (Do not depend on these methods being present)
##
## For all methods which have _firstVisible, the method is delegated 
## to the first visible (packed) Listbox
######################################################################

## This is the main callback that is bound to the subwidgets
## when using any of the public bind methods, The defined 
## defined callback ($cb) is called from within it

sub _bindCallback {
    my ($w, $cb, $sw, $ci, $yCoord) = @_;

    my $iHR = { '-subwidget' => $sw, '-column' => $ci };
    if (defined($yCoord)) {
        $iHR->{'-row'} = $w->_getEntryFromY($sw, $yCoord);
    }
    if (ref $cb eq 'ARRAY') {
	my ($code,@args) = @$cb;
	return $w->$code($iHR, @args);
    } else {
	return $w->$cb($iHR);
    }
}

## bind subwidgets is used by other public bind methods to
## apply a callback to an event dequence of a particular subwidget 
## within each of the columns. Any defined callbacks are passed
## to the _bindCallback which is actually the callback that gets
## bound. 

sub _bindSubwidgets {
    my ($w,$subwidget,$sequence,$callback) = @_;
    my $col = 0;
    
    return (keys %{$w->{'_bindings'}->{$subwidget}})
        unless (defined $sequence);

    unless (defined $callback) {
	$callback = $w->{'_bindings'}->{$subwidget}->{$sequence};
	$callback = '' unless defined $callback;
	return $callback;
    }
    
    if ($callback eq '') {
	foreach (@{$w->{'_columns'}}) {
	    $_->Subwidget($subwidget)->Tk::bind($sequence,'');
	}
	delete $w->{'_bindings'}->{$subwidget}->{$sequence};
	return '';
    }
    my @args = ('_bindCallback', $callback);
    foreach (@{$w->{'_columns'}}) {
        my $sw = $_->Subwidget($subwidget);
        if ($sw->class ne "CListbox") {
	    $sw->Tk::bind($sequence, [$w => @args, $sw, $col++]);
	} else {
	    $sw->Tk::bind($sequence, [$w => @args, $sw, $col++, Ev('y')]);
        }
    }
    $w->{'_bindings'}->{$subwidget}->{$sequence} = $callback;
    return '';
}

## handles config options that should be propagated to all MLColumn 
## subwidgets. Using the DEFAULT setting in ConfigSpecs would be one 
## idea, but the pane subwidget is also a child, and Pane will not 
## be able to handle many of the options being passed to this method.

sub _configureColumns {
    my ($w, $option, $value) = @_;
    return $w->{Configure}{$option}
        unless $value;

    foreach (@{$w->{'_columns'}}) {
	$_->configure("$option" => $value);
    }
}

sub _cntrlEnd  { shift->_firstVisible->Cntrl_End; }

sub _cntrlHome { shift->_firstVisible->Cntrl_Home; }

sub _dataExtend {
    my ($w, $el) = @_;
    my $mode = $w->cget('-selectmode');
    if ($mode eq 'extended') {
        $w->activate($el);
        $w->see($el);
        if ($w->selectionIncludes('anchor')) {
            $w->_firstVisible->Motion($el)
        }
    } elsif ($mode eq 'multiple') {
        $w->activate($el);
        $w->see($el)
    }
}

sub _deselectAll {
    my $w = shift;
    if ($w->cget('-selectmode') ne 'browse') {
        $w->selectionClear(0, 'end');
    }
}

## implements sorting and dragging & drop of a column
sub _dragOrSort {
    my ($w, $c) = @_;
 
    unless ($w->cget('-moveable')) {
	if ($c->cget('-sortable')) {
	    $w->sort (undef, $c);
	}
	return;
    }
    
    my $h=$c->Subwidget("heading");  # The heading button of the column.
    
    my $start_mouse_x = $h->pointerx;
    my $y_pos = $h->rooty;  # This is constant through the whole operation.
    my $width = $h->width;
    my $left_limit = $w->rootx - 1;
    
    # Find the rightmost, visible column
    my $right_end = 0;
    foreach (@{$w->{'_columns'}}) {
	if ($_->rootx + $_->width > $right_end) {
	    $right_end = $_->rootx + $_->width;
	}
    }	    
    my $right_limit = $right_end + 1;
   
    # Create a "copy" of the heading button, put it in a toplevel that matches
    # the size of the button, put the toplevel on top of the button.
    my $tl=$w->Toplevel; 
    $tl->overrideredirect(1);
    $tl->geometry(sprintf("%dx%d+%d+%d",
			  $h->width, $h->height, $h->rootx, $y_pos));

    my $b=$tl->HButton
	(map{defined($_->[4]) ? ($_->[0]=>$_->[4]) : ()} $h->configure)
	    ->pack(-expand=>1,-fill=>'both');
    
    # Move the toplevel with the mouse (as long as Button-1 is down).
    $h->bind("<Motion>", sub {
	my $new_x = $h->rootx - ($start_mouse_x - $h->pointerx);
	unless ($new_x + $width/2 < $left_limit ||
		$new_x + $width/2 > $right_limit) 
	{
	    $tl->geometry(sprintf("+%d+%d",$new_x,$y_pos));
	}
    });

    $h->bind("<ButtonRelease-1>", sub {
	my $rootx = $tl->rootx;
	my $x = $rootx + ($tl->width/2);
	$tl->destroy;    # Don't need this anymore...
	$h->bind("<Motion>",'');  # Cancel binding

	if ($h->rootx == $rootx) {	
	    # Button NOT moved, sort the column....
	    if ($c->cget('-sortable')) {
		$w->sort(undef, $c);
	    }
	    return;
	}
		
	# Button moved.....
	# Decide where to put the column. If the center of the dragged 
	# button is on the left half of another heading, insert it -before 
	# the column, otherwise insert it -after the column.
	foreach (@{$w->{'_columns'}}) {
	    if ($_->ismapped) {
		my $left = $_->rootx;
		my $right = $left + $_->width;
		if ($left <= $x && $x <= $right) {
		    if ($x - $left < $right - $x) {
			$w->columnShow($c,-before=>$_);
		    } else {
			$w->columnShow($c,'-after'=>$_);
		    }
		    $w->update;
		    $w->Callback(-configurecommand => $w);
		}
	    }
	}
    });
}

sub _extendUpDown {
    my ($w, $amount) = @_;
    if ($w->cget('-selectmode') ne 'extended') {
        return;
    }
    $w->activate($w->index('active')+$amount);
    $w->see('active');
    $w->_motion($w->index('active'))
}

## Many of the methods in this package are very similar in that they
## delagate calls to the MLColumn widgets. Because widgets can be
## be moved around (repacked) and hidden (packForget), any
## one widget may not be the "best" to be delegating calls to. The
## _columns variable holds an array of the columns but the order of 
## this array does not correspond to the order in which they might 
## by displayed, therefore this method is used to return the first
## "visible" or packed MLColumn. RCS Note: It might be reasonable to
## make this a public method as it could conceivably useful to someone
## who might want to subclass this widget or use their own bindings.
sub _firstVisible {
    my $w = shift;
    foreach my $c (@{$w->{'_columns'}}) {
	return $c if $c->ismapped;
    }
    return $w->{'_columns'}->[0];
}

sub _getEntryFromY {
    my ($cw, $sw, $yCoord) = @_;
    my $nearest = $sw->nearest($yCoord);
 
    return $nearest
        if ($nearest < ($sw->size() - 1));
    
    my ($x, $y, $w, $h) = $sw->bbox($nearest);
    my $lastY = $y + $h;
    return -1 
        if ($yCoord > $lastY);
    return $nearest;
}

## Used to distribute method calls which would otherwise be called for
## for one CListbox (Within a column), Each CListbox is a modified 
## Listbox whose methods end up passing the code and arguments that need
## to be called to this method where they are invoked for each column
## It's an interesting, although complex, interaction and it's worth 
## tracing to follow the program flow.

sub _motion    { shift->_firstVisible->Motion(@_) }
sub _selectAll { shift->_firstVisible->SelectAll; }

sub _selectionUpdate {
    my ($w, $code, $l, @args) = @_;

    if (@args) {
	foreach (@{$w->{'_columns'}}) {
	    &$code($_->Subwidget("listbox"), @args);
	}
    } else {
	&$code($w->{'_columns'}->[0]->Subwidget("listbox"));
    }
}

## dynamically sets the width of the widget by calculating
## the width of each of the currently visible columns. 
## This is generally called during creation time when -width
## is set to 0.

sub _setWidth {
    my ($w) = shift;
    my $width = 0;
    foreach my $c (@{$w->{'_columns'}}) {
        my $lw = $c->Subwidget('heading')->reqwidth;
        my $sw = $c->Subwidget('separator')->reqwidth;
        $width += ($lw + $sw);
    }
    $w->Subwidget('pane')->configure(-width => $width);
}



sub _upDown { shift->_firstVisible->UpDown(@_) }

sub _yscrollCallback  {
    my ($w, $top, $bottom) = @_;

    unless ($w->cget(-yscrollcommand)) {
	return;
    }

    unless (defined($top)) {
	# Called internally
	my $c = $w->_firstVisible;
	if (Exists($c) && $c->ismapped){
	    ($top,$bottom) = $c->yview;
	} else {
	    ($top,$bottom) = (0,1);
	}
    } 
    
    if ($top != $w->{'_top'} || $bottom != $w->{'_bottom'}) {
	$w->Callback(-yscrollcommand=>$top,$bottom);
	$w->{'_top'} = $top;
	$w->{'_bottom'} = $bottom;
    }
}

######################################################################
## Exported (Public) methods (listed alphabetically)
######################################################################

## Activate a row
sub activate { shift->_firstVisible->activate(@_)}

sub bindColumns    {  shift->_bindSubwidgets('heading',@_) }
sub bindRows       {  shift->_bindSubwidgets('listbox',@_) }
sub bindSeparators {  shift->_bindSubwidgets('separator',@_) }

sub columnConfigure {
    my ($w, $index, %args) = @_;
    $w->columnGet($index)->configure(%args);
}

## Delete a column.
sub columnDelete {
    my ($w, $first, $last) = @_;

    for (my $i=$w->columnIndex($first); $i<=$w->columnIndex($last); $i++) {
	$w->columnGet($i)->destroy;
    }
    @{$w->{'_columns'}} = map{Exists($_) ? $_ : ()} @{$w->{'_columns'}};
}

sub columnGet {
    my ($w, $from, $to) = @_;
    if (defined($to)) {
	$from= $w->columnIndex($from);
	$to = $w->columnIndex($to);
	return @{$w->{'_columns'}}[$from..$to];
    } else {
	return $w->{'_columns'}->[$w->columnIndex($from)];
    }
}

sub columnHide {
    my ($w, $first, $last) = @_;
    $last = $first unless defined $last;

    for (my $i=$w->columnIndex($first); $i<=$w->columnIndex($last); $i++) {
	$w->columnGet($i)->packForget;
    }
}

## Converts a column index to a numeric index. $index might be a number,
## 'end' or a reference to a MLColumn widget (see columnGet). Note that
## the index return by this method may not match up with it's current
## visual location due to columns being moved around

sub columnIndex {    
    my ($w, $index, $after_end) = @_;

    if ($index eq 'end') {
	if (defined $after_end) {
	    return $#{$w->{'_columns'}} + 1;
	} else {
	    return $#{$w->{'_columns'}};
	}
    } 
    
    if (ref($index) eq "Tk::MLColumn") {
	foreach (0..$#{$w->{'_columns'}}) {
	    if ($index eq $w->{'_columns'}->[$_]) {
		return $_;
	    }
	}
    } 

    if ($index =~ m/^\s*(\d+)\s*$/) {
	return $1;
    }    
    croak "Invalid column index: $index\n";
}

## Insert a column. $index should be a number or 'end'. 
sub columnInsert {
    my ($w, $index, %args) = @_;
   
    $index = $w->columnIndex($index,1);
    my %opts = ();
    
    ## Copy these options from the megawidget.
    foreach (qw/-background -foreground -font -height 
        -resizeable -selectbackground -selectforeground 
        -selectborderwidth -selectmode -separatorcolor
        -separatorwidth -sortable -textwidth/) 
    {
	$opts{$_} = $w->cget($_) if defined $w->cget($_);
    }
    ## All options (and more) might be overridden by %args.
    map {$opts{$_} = $args{$_}} keys %args;
    
    my $c = $w->Subwidget("pane")->MLColumn(%opts, 
        -yscrollcommand  =>  [ $w => '_yscrollCallback'],
	-configurecommand => [ $w => 'Callback', '-configurecommand', $w],
	-xscancommand =>     [ $w => 'xscan' ],
	-updatecommand =>    [ $w => '_selectionUpdate']
    );
    
    ## RCS: Review this later - questionable implementation
    ## Fill the new column with empty values, making sure all columns have
    ## the same number of rows.
    unless (scalar(@{$w->{'_columns'}}) == 0) {
	foreach (1..$w->size) {
	    $c->insert('end','');
	}
    }  
    $c->Subwidget("heading")->bind("<Button-1>", [ $w => '_dragOrSort', $c]);
    
    my $carr = $w->{'_columns'};
    splice(@$carr,$index,0,$c);

    ## Update the selection to also include the new column.
    map {$w->selectionSet($_, $_)} $w->curselection
        if $w->curselection;

    ## Copy all bindings that are created by calls to 
    ## bindRows, bindColumns and/or bindSeparators.
    ## RCS: check this out, on the next pass
    foreach my $subwidget (qw/listbox heading separator/) {
	foreach (keys %{$w->{'_bindings'}->{$subwidget}}) {
	    $c->Subwidget($subwidget)->Tk::bind($_, 
                [
                    $w => 'bindCallback', 
                    $w->{'_bindings'}->{$subwidget}->{$_},
                    $index
                ]
            );
	}
    }
    
    if (Tk::Exists($w->{'_columns'}->[$index+1])) {
	$w->columnShow($index, -before=>$index+1);
    } else {
	$w->columnShow($index);
    }
    return $c;
}

sub columnPack {
    my ($w, @packinfo) = @_;
    $w->columnHide(0,'end');
    foreach (@packinfo) {
	my ($index, $width) = split /:/;
	$w->columnShow ($index);
	if (defined($width) && $width =~ /^\d+$/) {
	    $w->columnGet($index)->setWidth($width)
	}
    }
}

sub columnPackInfo {
    my ($w) = @_;

    ## Widget needs to have an update call first, otherwise
    ## the method will not return anything if called prior to
    ## MainLoop - RCS

    $w->update;
    map {$w->columnIndex($_) . ':' . $_->width} 
       sort {$a->rootx <=> $b->rootx}
          map {$_->ismapped ? $_ : ()} @{$w->{'_columns'}};
}    

sub columnShow {
    my ($w, $index, %args) = @_;
    
    my $c = $w->columnGet($index);
    my @packopts = (-anchor=>'w',-side=>'left',-fill=>'both');
    if (defined($args{'-before'})) {
	push (@packopts, '-before'=>$w->columnGet($args{'-before'}));
    } elsif (defined($args{'-after'})) {
	push (@packopts, '-after'=>$w->columnGet($args{'-after'}));
    }
    $c->pack(@packopts);
}

sub curselection { shift->_firstVisible->curselection(@_)}

sub delete {
    my $w = shift;
    foreach (@{$w->{'_columns'}}) {
	my $saved_width = $_->width;
        $_->delete(@_);
	if ($_->ismapped) {
	    $_->setWidth($saved_width);
	}
    }
    $w->_yscrollCallback;
}
    
sub get {
    my @result = ();
    my ($colnum,$rownum) = (0,0);
    
    foreach (@{shift->{'_columns'}}) {
	my @coldata = $_->get(@_);
	$rownum = 0;
	map {$result[$rownum++][$colnum] = $_} @coldata;
	$colnum++;
    }
    @result;
}

sub getRow {
    my @result = map {$_->get(@_)} @{shift->{'_columns'}};
    if (wantarray) {
	@result;
    } else {
	$result[0];
    }
}
    
sub index { shift->_firstVisible->index(@_)}

sub insert {
    my ($w, $index, @data) = @_;
    my ($rownum, $colnum);
    
    my $rowcnt = $#data;
    
    # Insert data into one column at a time, calling $listbox->insert
    # ONCE for each column. (The first version of this widget call insert
    # once for each row in each column).
    # 
    foreach $colnum (0..$#{$w->{'_columns'}}) {	
	my $c = $w->{'_columns'}->[$colnum];
	
	# The listbox might get resized after insert/delete, which is a 
	# behaviour we don't like....
	my $saved_width = $c->width;

	my @coldata = ();

	foreach (0..$#data) {
	    if (defined($data[$_][$colnum])) {
		push @coldata, $data[$_][$colnum];
	    } else {
		push @coldata, '';
	    }
	}
	$c->insert($index,@coldata);
	
	if ($c->ismapped) {
	    # Restore saved width.
	    $c->setWidth($saved_width);
	} 
    }    
    $w->_yscrollCallback;
}

## These methods all delegate to the first visible column's
## Listbox. Refer to Listbox docs and description for _firstVisible

sub nearest           { shift->_firstVisible->nearest(@_)}
sub see               { shift->_firstVisible->see(@_)}
sub selectionAnchor   { shift->_firstVisible->selectionAnchor(@_)}
sub selectionClear    { shift->_firstVisible->selectionClear(@_)}
sub selectionIncludes { shift->_firstVisible->selectionIncludes(@_)}
sub selectionSet      { shift->_firstVisible->selectionSet(@_)}
sub size              { shift->_firstVisible->size(@_)}

sub sort {
    my ($w, $descending, @indexes) = @_;
    
    # Hack to avoid problem with older Tk versions which do not support
    # the -recurse=>1 option.
    $w->Busy;   # This works always (but not very good...)
    Tk::catch {$w->Busy(-recurse=>1)};# This works on newer Tk versions,
                                      # harmless on old versions.
     
    @indexes = (0..$#{$w->{'_columns'}}) unless @indexes;

    # Convert all indexes to integers.
    map {$_=$w->columnIndex($_)} @indexes;
    
    # This works on Solaris, but not on Linux???
    # Store the -comparecommand for each row in a local array. In the sort,
    # the store command is called directly in stead of via the MLColumn
    # subwidget. This saves a lot of callbacks and function calls.
    #
    # my @cmp_subs = map {$_->cget(-comparecommand)} @{$w->{'_columns'}};
    
    # If sort order is not defined
    unless (defined $descending) {
	if ($#indexes == 0 &&
	    $w->{'_sortcol'} == $indexes[0] &&
	    $w->{'_sort_descending'} == 0)
	{
	    # Already sorted on this column, reverse sort order.
	    $descending = 1;
	} else {
	    $descending = 0;
	}
    }

    # To retain the selection after the sort we have to save information
    # about the current selection before the sort. Adds a dummy column
    # to the two dimensional data array, this last column will be true
    # for all rows that are currently selected.
    my $dummy_column = scalar(@{$w->{'_columns'}});

    my @data = $w->get(0,'end');
    foreach ($w->curselection) {
	$data[$_]->[$dummy_column] = 1;  # Selected...
    }
    
    @data = sort {
	local $^W = 0;
	foreach (@indexes) {
	    my $res = do {
		if ($descending) {
		    # Call via cmp_subs works fine on Solaris, but no
		    # on Linux. The column->compare method is much slower...
		    #
		    # &{$cmp_subs[$_]} ($b->[$_],$a->[$_]);
		    $w->{'_columns'}->[$_]->compare($b->[$_],$a->[$_]);
		} else {
		    # &{$cmp_subs[$_]} ($a->[$_],$b->[$_]);
		    $w->{'_columns'}->[$_]->compare($a->[$_],$b->[$_]);
		}
	    };
	    return $res if $res;
	}
	return 0;
    } @data;
        
    # Replace data with the new, sorted list.
    $w->delete(0,'end');
    $w->insert(0,@data);

    my @new_selection = ();
    foreach (0..$#data) {
	if ($data[$_]->[$dummy_column]) {
	    $w->selectionSet($_,$_);
	}
    }

    $w->{'_sortcol'} = $indexes[0];
    $w->{'_sort_descending'} = $descending;
    
    $w->Unbusy; #(-recurse=>1);
}

# Implements horizontal scanning. 
sub xscan {
    my ($w, $type, $x) = @_;

    if ($type eq 'dragto') {
	my $dist = $w->{'_scanmark_x'} - $w->pointerx;
	
	# Looks like there is a bug in Pane: If no -xscrollcommand
	# is defined, xview() fails. This is fixed by this hack:
	#
	my $p = $w->Subwidget("pane");
	unless (defined ($p->cget(-xscrollcommand))) {
	    $p->configure(-xscrollcommand => sub {});
	}
	$p->xview('scroll',$dist,'units');
    }
    $w->{'_scanmark_x'} = $w->pointerx;
}

sub xview { shift->Subwidget("pane")->xview(@_) }
sub yview { shift->_firstVisible->yview(@_)}

1;
__END__

















