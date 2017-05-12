# This file converted to perltk using the tcl2perl script and much hand-editing.
#   jc 6/26/00
#
# table.tcl --
#
# version align with tkTable 2.7, jeff.hobbs@acm.org
# This file defines the default bindings for Tk table widgets
# and provides procedures that help in implementing those bindings.
#
#--------------------------------------------------------------------------
# tkPriv elements used in this file:
#
# afterId -		Token returned by "after" for autoscanning.
# tablePrev -		The last element to be selected or deselected
#			during a selection operation.
# mouseMoved -		Boolean to indicate whether mouse moved while
#			the button was pressed.
# borderInfo -		Boolean to know if the user clicked on a border
# borderB1 -		Boolean that set whether B1 can be used for the
#			interactiving resizing
#--------------------------------------------------------------------------
## Interactive cell resizing, affected by -resizeborders option
##
package Tk::TableMatrix;

use AutoLoader;
use Carp;
use strict;
use vars( '%tkPriv', '$VERSION');

$VERSION = '1.23';

use Tk qw( Ev );

use base qw(Tk::Widget);

Construct Tk::Widget 'TableMatrix';

bootstrap Tk::TableMatrix;

sub Tk_cmd { \&Tk::tablematrix };

sub Tk::Widget::ScrlTableMatrix { shift->Scrolled('TableMatrix' => @_) }

Tk::Methods("activate", "bbox", "border", "cget", "clear", "configure",
    "curselection", "curvalue", "delete", "get", "rowHeight",
    "hidden", "icursor", "index", "insert",
    "postscript",
    "reread", "scan", "see", "selection", "set",
    "spans", "tag", "validate", "version", "window", "colWidth",
    "xview", "yview");
    
use Tk::Submethods ( 'border'   => [qw(mark dragto)],
		     'clear'    => [qw(cache sizes tags all)],
		     'delete'   => [qw(active cols rows)],
		     'insert'   => [qw(active cols rows)],
		     'scan'     => [qw(mark dragto)],
		     'selection'=> [qw(anchor clear includes set)],
		     'tag'      => [qw(cell cget col configure delete exists
				     includes names row raise lower)],
		     'window'   => [qw(cget configure delete move names)],
		     'xview'  => [qw(moveto scroll)],
		     'yview'  => [qw(moveto scroll)],
			);



sub ClassInit
{
 my ($class,$mw) = @_;

$tkPriv{borderB1} = 1; # initialize borderB1

$mw->bind($class,'<3>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    ## You might want to check for cell returned if you want to
    ## restrict the resizing of certain cells
    $w->border('mark',$Ev->x,$Ev->y);
   }
 );
 

 $mw->bind($class,'<B3-Motion>',['border','dragto',Ev('x'),Ev('y')]);
 $mw->bind($class,'<1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Button1($Ev->x,$Ev->y);
   }
 );
 $mw->bind($class,'<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->B1Motion($Ev->x,$Ev->y);
    
   }
 );
 $mw->bind($class,'<ButtonRelease-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $tkPriv{borderInfo} = "";
    if ($w->exists)
     {
      $w->CancelRepeat;
      $w->activate('@' . $Ev->x.",".$Ev->y);
     }
   }
 );
 $mw->bind($class,'<Shift-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->BeginExtend( $w->index('@' . $Ev->x.",".$Ev->y));
   }
 );


 $mw->bind($class,'<Control-1>',  
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->BeginToggle($w->index('@' . $Ev->x.",".$Ev->y));
   }
 );
 $mw->bind($class,'<B1-Enter>','CancelRepeat');
 $mw->bind($class,'<B1-Leave>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    if( !$tkPriv{borderInfo} ){ 
	    $tkPriv{x} = $Ev->x; $tkPriv{y} = $Ev->y;
	    $w->AutoScan;
    }
   }
 );
 $mw->bind($class,'<2>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->scan('mark',$Ev->x,$Ev->y);
    $tkPriv{x} = $Ev->x; $tkPriv{y} = $Ev->y;
    $tkPriv{'mouseMoved'} = 0;
   }
 );
 $mw->bind($class,'<B2-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $tkPriv{'mouseMoved'} = 1 if ($Ev->x ne $tkPriv{'x'} || $Ev->y ne $tkPriv{'y'});
    $w->scan('dragto',$Ev->x,$Ev->y) if ($tkPriv{'mouseMoved'});
   }
 );
 $mw->bind($class,'<ButtonRelease-2>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Paste($w->index('@' . $Ev->x.",".$Ev->y)) unless ($tkPriv{'mouseMoved'});
   }
 );
 


  ClipboardKeysyms( $mw, $class, qw/ <Copy> <Cut> <Paste> /);
  ClipboardKeysyms( $mw, $class, 'Control-c', 'Control-x', 'Control-v');

############################
 

 $mw->bind($class,'<<Table_Commit>>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    eval
     {
      $w->activate('active');
     }
    ;
   }
 );
 
# Remove this if you don't want cell commit to occur on every Leave for
# the table (via mouse) or FocusOut (loss of focus by table).
$mw->eventAdd( qw[ <<Table_Commit>> <Leave> <FocusOut> ]);

 $mw->bind($class,'<Shift-Up>',['ExtendSelect',-1,0]);
 $mw->bind($class,'<Shift-Down>',['ExtendSelect',1,0]);
 $mw->bind($class,'<Shift-Left>',['ExtendSelect',0,-1]);
 $mw->bind($class,'<Shift-Right>',['ExtendSelect',0,1]);
 $mw->bind($class,'<Prior>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->yview('scroll',-1,'pages');
    $w->activate('@0,0');
   }
 );
 $mw->bind($class,'<Next>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->yview('scroll',1,'pages');
    $w->activate('@0,0');
   }
 );
 $mw->bind($class,'<Control-Prior>',['xview','scroll',-1,'pages']);
 $mw->bind($class,'<Control-Next>',['xview','scroll',1,'pages']);
 $mw->bind($class,'<Home>',['see','origin']);
 $mw->bind($class,'<End>',['see','end']);
 $mw->bind($class,'<Control-Home>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->selection('clear','all');
    $w->activate('origin');
    $w->selection('set','active');
    $w->see('active');
   }
 );
 $mw->bind($class,'<Control-End>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->selection('clear','all');
    $w->activate('end');
    $w->selection('set','active');
    $w->see('active');
   }
 );
 $mw->bind($class,'<Shift-Control-Home>',['DataExtend','origin']);
 $mw->bind($class,'<Shift-Control-End>',['DataExtend','end']);
 $mw->bind($class,'<Select>',['BeginSelect',Ev('index','active')]);
 $mw->bind($class,'<Shift-Select>',['BeginExtend',Ev('index','active')]);
 $mw->bind($class,'<Control-slash>','SelectAll');
 $mw->bind($class,'<Control-backslash>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->selection('clear','all') if ($w->cget(-selectmode) =~ /browse/);
   }
 );
 $mw->bind($class,'<Up>',['MoveCell',-1,0]);
 $mw->bind($class,'<Down>',['MoveCell',1,0]);
 $mw->bind($class,'<Left>',['MoveCell',0,-1]);
 $mw->bind($class,'<Right>',['MoveCell',0,1]);
 $mw->bind($class,'<KeyPress>',['TableInsert',Ev('A')]);

 $mw->bind($class,'<BackSpace>',['BackSpace']);

 $mw->bind($class,'<Delete>',['delete','active','insert']);
 $mw->bind($class,'<Escape>','reread');
 $mw->bind($class,'<Return>',['TableInsert',"\n"]);
 $mw->bind($class,'<Control-Left>',
   sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    my $posn = $w->icursor;
    $w->icursor($posn - 1);
   }
 );

 $mw->bind($class,'<Control-Right>',
    sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    my $posn = $w->icursor;
    $w->icursor($posn + 1);
   }
 );

 $mw->bind($class,'<Control-e>',['icursor','end']);
 $mw->bind($class,'<Control-a>',['icursor',0]);
 $mw->bind($class,'<Control-k>',['delete','active','insert','end']);
 $mw->bind($class,'<Control-equal>',['ChangeWidth','active',1]);
 $mw->bind($class,'<Control-minus>',['ChangeWidth','active',-1]);

# Ignore all Alt, Meta, and Control keypresses unless explicitly bound.
# Otherwise, if a widget binding for one of these is defined, the
# <KeyPress> class binding will also fire and insert the character,
# which is wrong.  Ditto for Tab.


 $mw->bind($class,'<Alt-KeyPress>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    # nothing
   }
 );
 $mw->bind($class,'<Meta-KeyPress>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    # nothing

   }
 );
 $mw->bind($class,'<Control-KeyPress>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    #
   }
 );
 $mw->bind($class,'<Any-Tab>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    #
   }
 );



}



# ::tk::table::GetSelection --
#   This tries to obtain the default selection.  On Unix, we first try
#   and get a UTF8_STRING, a type supported by modern Unix apps for
#   passing Unicode data safely.  We fall back on the default STRING
#   type otherwise.  On Windows, only the STRING type is necessary.
# Arguments:
#   w	The widget for which the selection will be retrieved.
#	Important for the -displayof property.
#   sel	The source of the selection (PRIMARY or CLIPBOARD)
# Results:
#   Returns the selection, or an error if none could be found
#
sub GetSelection{

	my $w = shift;
	my $sel = shift;
	$sel ||= 'PRIMARY';
	
	my $txt;
	if( $Tk::platform eq 'unix'){
		eval{ $txt = $w->SelectionGet( -selection =>  $sel) };

		if( $@){
			warn("Could not find default selection\n");
			return undef;
		}
			
		return $txt;

	}
	else{
	
		eval{ $txt = $w->SelectionGet( -selection => $sel) };

		if( $@){
			warn("Could not find default selection\n");
			return undef;
		}

		return $txt;
		
	}
}
		


# ClipboardKeysyms --
# This procedure is invoked to identify the keys that correspond to
# the "copy", "cut", and "paste" functions for the clipboard.
#
# Arguments:
# copy -	Name of the key (keysym name plus modifiers, if any,
#		such as "Meta-y") used for the copy operation.
# cut -		Name of the key used for the cut operation.
# paste -	Name of the key used for the paste operation.

sub ClipboardKeysyms
{
 my $mw = shift;
 my $class = shift;
 my $copy = shift;
 my $cut = shift;
 my $paste = shift;
 $mw->bind($class,"<$copy>",'Copy');
 $mw->bind($class,"<$cut>",'Cut');
 $mw->bind($class,"<$paste>",'Paste');

}
# TableInsert --
#
#   Insert into the active cell
#
# Arguments:
#   w	- the table widget
#   s	- the string to insert
# Results:
#   Returns nothing
#

sub TableInsert
{
 my $w = shift;
 my $s = shift;
 $w->insert('active','insert',$s) if ($s ne '' ) ;
}
# ::tk::table::BackSpace --
#
#   BackSpace in the current cell
#
# Arguments:
#   w	- the table widget
# Results:
#   Returns nothing
#
sub BackSpace{
	
    my $w = shift;
    my $Ev = $w->XEvent;
    my $posn = $w->icursor;
    $w->delete('active',$posn - 1) if( $posn > -1);
}

# Button1 --
#
# This procedure is called to handle selecting with mouse button 1.
# It will distinguish whether to start selection or mark a border.
#
# Arguments:
#   w	- the table widget
#   x	- x coord
#   y	- y coord
# Results:
#   Returns nothing
#
sub Button1 {

	my $w = shift;
	my ( $x, $y ) = @_;

	# borderInfo is null if the user did not click on a border
	if ( $tkPriv{borderB1} == 1 ) {
		$tkPriv{borderInfo} = $w->borderMark( $x, $y );
	}
	else {
		$tkPriv{borderInfo} = "";
	}

	if ( ! $tkPriv{borderInfo} ) {

		#
		# Only do this when a border wasn't selected
		#
		if ( $w->exists ) {
			$w->BeginSelect( $w->index( '@' . "$x,$y" ) );
			$w->focus;
		}
		$tkPriv{x}          = $x;
		$tkPriv{y}          = $y;
		$tkPriv{mouseMoved} = 0;
	}
}

# B1Motion --
#
# This procedure is called to start processing mouse motion events while
# button 1 moves while pressed.  It will distinguish whether to change
# the selection or move a border.
#
# Arguments:
#   w	- the table widget
#   x	- x coord
#   y	- y coord
# Results:
#   Returns nothing
#
sub B1Motion {

	my $w = shift;

	my ( $x, $y ) = @_;

	# If we already had motion, or we moved more than 1 pixel,
	# then we start the Motion routine

	if ( $tkPriv{borderInfo}  ) {

		#
		# If the motion is on a border, drag it and skip the rest
		# of this binding.
		#
		$w->borderDragto( $x, $y );

	}
	else {

		#
		# If we already had motion, or we moved more than 1 pixel,
		# then we start the Motion routine
		#
		if ( $tkPriv{mouseMoved}
		      || abs( $x - $tkPriv{x} ) > 1
		      || abs( $y - $tkPriv{y} ) > 1 ) {

			$tkPriv{mouseMoved} = 1;
		}
		if ( $tkPriv{mouseMoved} ) {
			$w->Motion( $w->index( '@' . "$x,$y" ) );
		}
	}
}
# BeginSelect --
#
# This procedure is typically invoked on button-1 presses. It begins
# the process of making a selection in the table. Its exact behavior
# depends on the selection mode currently in effect for the table;
# see the Motif documentation for details.
#
# Arguments:
# w	- The table widget.
# el	- The element for the selection operation (typically the
#	one under the pointer).  Must be in row,col form.

sub BeginSelect
{
 my $w = shift;
 my $el = shift;
 my $r;
 my $c;
 my $inc;
 my $el2;
 return unless( scalar( ($r,$c) = split(",",$el)) ==2); # Get Rol Col or return
 my $selectmode = $w->cget('-selectmode');
 if ($selectmode eq 'multiple')
  {
   if ($w->tag('includes','title',$el))
    {
     ## in the title area
     if ($r < ($w->cget('-titlerows') + $w->cget('-roworigin')) )
      {
       ## We're in a column header
       if ($c < ( $w->cget('-titlecols') + $w->cget('-colorigin')))
        {
         ## We're in the topleft title area
         $inc = 'topleft';
         $el2 = 'end';
        }
       else
        {
         $inc = $w->index('topleft','row').",$c";
         $el2 = $w->index('end','row').",$c";
        }
      }
     else
      {
       ## We're in a row header
       $inc = "$r,".$w->index('topleft','col');
       $el2 = "$r,".$w->index('end','col');
      }
    }
   else
    {
     $inc = $el;
     $el2 = $el;
    }
   if ($w->selection('includes',$inc))
    {
     $w->selection('clear',$el,$el2);
    }
   else
    {
     $w->selection('set',$el,$el2);
    }
  }
 elsif ($selectmode eq 'extended')
  {
   $w->selection('clear','all');
   if ($w->tag('includes','title',$el))
    {
     if ($r < ($w->cget('-titlerows') + $w->cget('-roworigin')))
      {
       ## We're in a column header
       if ($c < ( $w->cget('-titlecols') + $w->cget('-colorigin')) )
        {
         $w->selection('set',$el,'end');
        }
       else
        {
         $w->selection('set',$el,$w->index('end','row').",$c");
        }
      }
     else
      {
       ## We're in a row header
       $w->selection('set',$el,"$r,".$w->index('end','col'));
      }
    }
   else
    {
     $w->selection('set',$el);
    }
   $w->selection('anchor',$el);
   $tkPriv{'tablePrev'} = $el;
  }
 elsif ($selectmode eq 'default')
  {
   unless ($w->tag('includes','title',$el))
    {
     $w->selection('clear','all');
     $w->selection('set',$el);
     $tkPriv{'tablePrev'} = $el;
    }
   $w->selection('anchor',$el);
  }
}
# Motion --
#
# This procedure is called to process mouse motion events while
# button 1 is down. It may move or extend the selection, depending
# on the table's selection mode.
#
# Arguments:
# w	- The table widget.
# el	- The element under the pointer (must be in row,col form).

sub Motion
{
 my $w = shift;
 my $el = shift;
 my $r;
 my $c;
 my $elc;
 my $elr;
 unless (exists($tkPriv{'tablePrev'}))
  {
   $tkPriv{'tablePrev'} = $el;
   return;
  }
 return if ($tkPriv{'tablePrev'} eq $el );
 my $selectmode = $w->cget('-selectmode');
 if ($selectmode eq 'browse')
  {
   $w->selection('clear','all');
   $w->selection('set',$el);
   $tkPriv{'tablePrev'} = $el;
  }
 elsif ($selectmode eq 'extended')
  {
   # avoid tables that have no anchor index yet.
   my $indexAnchor;
   eval{ $indexAnchor = $w->index('anchor') };
   return if( $@ || !$indexAnchor);

   ($r,$c) = split(",",$tkPriv{tablePrev});
   ($elr,$elc) = split(",",$el);

   if ($w->tag('includes','title',$el))
    {
     if ($r < ($w->cget('-titlerows') + $w->cget('-roworigin')) )
      {
       ## We're in a column header
       if ($c < ( $w->cget('-titlecols') + $w->cget('-colorigin')) )
        {
         ## We're in the topleft title area
         $w->selection('clear','anchor','end');
        }
       else
        {
         $w->selection('clear','anchor',$w->index('end','row').",$c");
        }
       ##### perltk: Removed comma
       $w->selection('set','anchor',$w->index('end','row').",$elc");
      }
     else
      {
       ## We're in a row header
       $w->selection('clear','anchor',"$r,".$w->index('end','col'));
       $w->selection('set','anchor',"$elr,".$w->index('end','col'));
      }
    }
   else
    {
     $w->selection('clear','anchor',$tkPriv{'tablePrev'});
     $w->selection('set','anchor',$el);
    }
   $tkPriv{'tablePrev'} = $el;
  }
}
# BeginExtend --
#
# This procedure is typically invoked on shift-button-1 presses. It
# begins the process of extending a selection in the table. Its
# exact behavior depends on the selection mode currently in effect
# for the table; see the Motif documentation for details.
#
# Arguments:
# w - The table widget.
# el - The element for the selection operation (typically the
# one under the pointer). Must be in numerical form.

sub BeginExtend
{
 my $w = shift;
 my $el = shift;
 $w->Motion($el) if ($w->cget(-selectmode) eq 'extended' && $w->selectionIncludes('anchor'));
}
# BeginToggle --
#
# This procedure is typically invoked on control-button-1 presses. It
# begins the process of toggling a selection in the table. Its
# exact behavior depends on the selection mode currently in effect
# for the table; see the Motif documentation for details.
#
# Arguments:
# w - The table widget.
# el - The element for the selection operation (typically the
# one under the pointer). Must be in numerical form.

sub BeginToggle
{
 my $w = shift;
 my $el = shift;
 my $r;
 my $c;
 my $end;
 if ( $w->cget( -selectmode ) =~ /extended/i )
  {
   $tkPriv{'tablePrev'} = $el;
   $w->selection('anchor',$el);
   if ($w->tag('includes','title',$el))
    {
     # scan $el %d,%d r c
     ($r,$c) = split( ",",$el);
     if ($r < ($w->cget('-titlerows') + $w->cget('-roworigin')) )
      {
       ## We're in a column header
       if ($c < ($w->cget('-titlecols') + $w->cget('-colorigin')))
        {
         ## We're in the topleft title area
         $end = 'end';
        }
       else
        {
         $end = $w->index('end','row');
        }
      }
     else
      {
       ## We're in a row header
       $end = "$r,".$w->index('end','row');
      }
    }
   else
    {
     ## We're in a non-title cell
     $end = $el;
    }
   if ($w->selection('includes',$end))
    {
     $w->selection('clear',$el,$end);
    }
   else
    {
     $w->selection('set',$el,$end);
    }
  }
}
# AutoScan --
# This procedure is invoked when the mouse leaves an table window
# with button 1 down. It scrolls the window up, down, left, or
# right, depending on where the mouse left the window, and reschedules
# itself as an "after" command so that the window continues to scroll until
# the mouse moves back into the window or the mouse button is released.
#
# Arguments:
# w - The table window.

sub AutoScan
{
 my $w = shift;
 my $x;
 my $y;

 return unless ($w->exists);
 $x = $tkPriv{'x'};
 $y = $tkPriv{'y'};
 
 if ($y >= $w->SUPER::height) # we don't want our height here, we want the 
 				# actual height of the window
  {
   $w->yview('scroll',1,'units');
  }
 elsif ($y < 0)
  {
   $w->yview('scroll',-1,'units');
  }
 elsif ($x >= $w->SUPER::width)
  {
   $w->xview('scroll',1,'units');
  }
 elsif ($x < 0)
  {
   $w->xview('scroll',-1,'units');
  }
 else
  {
   return;
  }
 $w->Motion($w->index('@' . $x.','.$y));
 $tkPriv{'afterId'} = $w->after(50,[$w,'AutoScan']);
}
# MoveCell --
#
# Moves the location cursor (active element) by the specified number
# of cells and changes the selection if we're in browse or extended
# selection mode.  If the new cell is "hidden", we skip to the next
# visible cell if possible, otherwise just abort.
#
# Arguments:
# w - The table widget.
# x - +1 to move down one cell, -1 to move up one cell.
# y - +1 to move right one cell, -1 to move left one cell.

sub MoveCell
{


 my $w = shift;
 my $x = shift;
 my $y = shift;
 my $c;
 my $cell;
 my $r;
 my $true;
 eval { $r = $w->index('active','row') }; return if( $@);
 
 $c = $w->index('active','col');
 # set cell [$w index [incr r $x],[incr c $y]]
 $cell = $w->index(($r += $x).",".($c += $y));
 while ( ($true = $w->index('active')) eq '')
  {
   # The cell is in some way hidden
   if ($true eq $w->index('active'))
    {
     # The span cell wasn't the previous cell, so go to that
     $cell = $true;
     last;
    }
   if ($x > 0)
    {
     ++ $r;
    }
   elsif ($x < 0)
    {
     $r += -1;
    }
   if ($y > 0)
    {
     ++ $c;
    }
   elsif ($y < 0)
    {
     $c += -1;
    }
   if ($cell eq $w->index($r.",".$c))
    {
     $cell = $w->index("$r,$c");
    }
   else
    {
     # We couldn't find a non-hidden cell, just don't move
     return;
    }
  }
 $w->activate($cell);
 $w->see('active');
 if ($w->cget('-selectmode') eq 'browse')
  {
   $w->selection('clear','all');
   $w->selection('set','active');
  }
 elsif ($w->cget('-selectmode') eq 'extended')
  {
   $w->selection('clear','all');
   $w->selection('set','active');
   $w->selection('anchor','active');
   $tkPriv{'tablePrev'} = $w->index('active');
  }
}
# ExtendSelect --
#
# Does nothing unless we're in extended selection mode; in this
# case it moves the location cursor (active element) by the specified
# number of cells, and extends the selection to that point.
#
# Arguments:
# w - The table widget.
# x - +1 to move down one cell, -1 to move up one cell.
# y - +1 to move right one cell, -1 to move left one cell.

sub ExtendSelect
{
 my $w = shift;
 my $x = shift;
 my $y = shift;
 my $c;
 my $r;
 #### Perltk notes: (should be 'ne' instead of 'eq' ???
 return unless (  $w->cget(-selectmode) eq 'extended');
 eval { $r = $w->index('active','row'); }; return if($@);
 $c = $w->index('active','col');
 $w->activate( ($r += $x).",".($c += $y));
 $w->see('active');
 $w->Motion($w->index('active'));
}
# DataExtend
#
# This procedure is called for key-presses such as Shift-KEndData.
# If the selection mode isnt multiple or extend then it does nothing.
# Otherwise it moves the active element to el and, if we're in
# extended mode, extends the selection to that point.
#
# Arguments:
# w - The table widget.
# el - An integer cell number.

sub DataExtend
{
 my $w = shift;
 my $el = shift;
 my $mode;
 $mode = $w->cget('-selectmode');
 if ($mode =~ /extended/i )
  {
   $w->activate($el);
   $w->see($el);
   $w->Motion($el) if ($w->selection('includes','anchor'));
  }
 elsif ($mode =~ /multiple/i)
  {
   $w->activate($el);
   $w->see($el);
  }
}
# SelectAll
#
# This procedure is invoked to handle the "select all" operation.
# For single and browse mode, it just selects the active element.
# Otherwise it selects everything in the widget.
#
# Arguments:
# w - The table widget.

sub SelectAll
{
 my $w = shift;
 if ( $w->cget(-selectmode) =~ /^(single|browse)$/)
  {
   $w->selection('clear','all');
   $w->selection('set','active');
   $w->TableMatrixHandleType($w->index('active'));
  }
 else
  {
   $w->selection('set','origin','end');
  }
}
# ChangeWidth --
# Adjust the widget of the specified cell by $a.
#
# Arguments:
# w - The table widget.
# i - cell index
# a - amount to adjust by

sub ChangeWidth
{
 my $w = shift;
 my $i = shift;
 my $a = shift;
 my $tmp;
 my $width;
 $tmp = $w->index($i,'col');
 if (($width = $w->colWidth($tmp)) >= 0)
  {
   $w->colWidth($tmp,$width += $a);
  }
 else
  {
   $w->colWidth($tmp,$width += -$a);
  }
}
# Copy --
# This procedure copies the selection from a table widget into the
# clipboard.
#
# Arguments:
# w -		Name of a table widget.

sub Copy
{
 my $w = shift;
 if ($w->SelectionOwner() eq $w)
  {
   $w->clipboardClear;
   eval
    {
     $w->clipboardAppend($w->GetSelection);
    }
   ;
  }
}
# Cut --
# This procedure copies the selection from a table widget into the
# clipboard, then deletes the selection (if it exists in the given
# widget).
#
# Arguments:
# w -		Name of a table widget.

sub Cut
{
 my $w = shift;
 if ($w->SelectionOwner() eq $w)
  {
   $w->clipboardClear;
   eval
    {
     $w->clipboardAppend($w->GetSelection);
     $w->curselection('');# Clear whatever is selected
     $w->selectionClear();
    }
   ;
  }
}
# Paste --
# This procedure pastes the contents of the clipboard to the specified
# cell (active by default) in a table widget.
#
# Arguments:
# w -		Name of a table widget.
# cell -	Cell to start pasting in.

sub Paste
{
 my $w = shift;
 my $cell = shift || ''; ## Perltk not sure if translated correctly
 my $data;
 if ($cell ne '')
  {
   eval{ $data = $w->GetSelection(); }; return if($@);
  }
 else
  {
   eval{ $data = $w->GetSelection('CLIPBOARD'); }; return if($@);
   $cell = 'active';
  }
 $w->PasteHandler($w->index($cell),$data);
 $w->focus if ($w->cget('-state') eq 'normal');
}
# PasteHandler --
# This procedure handles how data is pasted into the table widget.
# This handles data in the default table selection form.
# NOTE: this allows pasting into all cells, even those with -state disabled
#
# Arguments:
# w -		Name of a table widget.
# cell -	Cell to start pasting in.

sub PasteHandler
{

 my $w = shift;
 my $cell = shift;
 my $data = shift;
 #
 # Don't allow pasting into the title cells
 #
 return if( $w->tagIncludes('title', $cell));
 my $rows;
 my $cols;
 my $r;
 my $c;
 my $rsep;
 my $csep;
 my $row;
 my $line;
 my $col;
 my $item;
 $rows = $w->cget('-rows') - $w->cget('-roworigin');
 $cols = $w->cget('-cols') - $w->cget('-colorigin');
 $r = $w->index($cell,'row');
 $c = $w->index($cell,'col');
 $rsep = $w->cget('-rowseparator');
 $csep = $w->cget('-colseparator');
 ## Assume separate rows are split by row separator if specified
 ## If you were to want multi-character row separators, you would need:
 # regsub -all $rsep $data <newline> data
 # set data [join $data <newline>]
 my @data;
 @data = split($rsep,$data) if ($rsep ne ''); 
 $row = $r;
 foreach $line (@data)
  {
   last if ($row > $rows);
   $col = $c;
   ## Assume separate cols are split by col separator if specified
   ## Unless a -separator was specified
   my @line = split($csep, $line) if ($csep ne ''); 
   ## If you were to want multi-character col separators, you would need:
   # regsub -all $csep $line <newline> line
   # set line [join $line <newline>]
   foreach $item (@line)
    {
     last if ($col > $cols);
     $w->set("$row,$col",$item);
     ++ $col;
    }
   ++ $row;
  }
}


#############################################################
##  CancelRepeat
# This procedure is invoked to cancel an auto-repeat action described
# by $Tk::TableMatrix::tkPriv{afterId}.  It's used by several widgets to auto-scroll
# the widget when the mouse is dragged out of the widget with a
# button pressed.


sub CancelRepeat{
	my $w = shift;
	 
	my $id = delete $tkPriv{'afterId'}; 
	$w->afterCancel($id) if($id);
		 
}



1;

__END__
