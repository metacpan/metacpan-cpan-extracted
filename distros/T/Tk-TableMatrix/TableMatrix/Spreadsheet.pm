
=head1 NAME

Tk::TableMatrix::Spreadsheet - Table Display with Spreadsheet-like bindings.

=head1 SYNOPSIS

  use Tk;
  use Tk::TableMatrix::Spreadsheet;



  my $t = $top->Scrolled('Spreadsheet', -rows => 21, -cols => 11, 
                              -width => 6, -height => 6,
			      -titlerows => 1, -titlecols => 1,
			      -variable => $arrayVar,
			      -selectmode => 'extended',
			      -titlerows => 1,
			      -titlecols => 1,
			      -bg => 'white',
                    );

=head1 DESCRIPTION

L<Tk::TableMatrix::Spreadsheet> is a L<Tk::TableMatrix>-derived widget that implements
some bindings so the resulting widget behaves more like a spreadsheet.

B<Bindings Added:>

=over 1

=item *

Row/Col resize handles appear when the cursor is placed
over a row/col border line in the rol/col title area. 

Dragging these handles will resize the row or column. If multiple rows or columns
are selected, then the new row/col size will apply to all row/cols selected.

Note: With the base Tk::TableMatrix, it is possible to resize the row/cols by dragging
on any cell border. To be more spreadsheet-like, Tk::TableMatrix::Spreadsheet  defaults to enable row/col
resizing only thru the title row/col dragging. To override this default behavoir, set the -resizeborder option to
'both' at startup.

=item *

A popup menu for row/col insert/delete appears when the mouse is right-clicked in the
row/col title areas. 

=item *

Cells activate (i.e. the contents become edit-able) only when the cell is double-clicked
or the F2 button is pressed. The default L<Tk::TableMatrix> behavior is for the
cell to be activated when the cell is single-clicked.

=item *

The Escape key causes any changes made to a cell to be canceled and the current
selection cleared.

=item *

The return key causes the the current cell to move down.

=item *

The tab (or shift tab) key causes the current cell to be moved to the right (left).

=item *

The delete key will delete the current selection, if no cell is currently active.

=item *

The Mouse button 2 (middle button) paste from the PRIMARY. (Control-v pastes from the
clipboard).

=back

=head1 Additional Information

Widget methods, options, etc, are inherited from the L<Tk::TableMatrix> widget. See its 
docs for additional information.

=cut



package Tk::TableMatrix::Spreadsheet;

use Carp;


use Tk;
use Tk::TableMatrix;
use Tk::Derived;

use base qw/ Tk::Derived Tk::TableMatrix/;

$VERSION = '1.23';


Tk::Widget->Construct("Spreadsheet");


sub ClassInit{
	my ($class,$mw) = @_;

	$class->SUPER::ClassInit($mw);
	
	#  Bind our motion routine to change cursors for row/column resize
	$mw->bind($class,'<Motion>',['GeneralMotion',$mw]);

	# Over-ride default button release binding
	#  so a cell won't activate by just clicking
	$mw->bind($class,'<ButtonRelease-1>',['Button1Release', $mw]);

	# Edit (activate) a cell if it is double-clicked
	#   Or F2 is pressed
	$mw->bind($class,'<Double-1>',
		sub
		 {
		  my $w = shift;
		  my $Ev = $w->XEvent;
		  if ($w->exists)
		   {
		    $w->CancelRepeat;
		    $w->activate('@' . $Ev->x.",".$Ev->y);
		   }
		 }
	);
	$mw->bind($class,'<F2>',
		sub
		 {
		  my $w = shift;
		  my $Ev = $w->XEvent;
		  if ($w->exists)
		   {
		    $w->CancelRepeat;
		    my $location = '@' . $Ev->x.",".$Ev->y;
		    #print "location = $location\n";
		    if( $w->selectionIncludes($location)){
		    	$w->activate('@' . $Ev->x.",".$Ev->y);
		    }
		   }
		 }
	);




	$mw->bind($class,'<Escape>',
		sub
		 {
		  my $w = shift;
		  $w->reread; # undo any changes if editing a cell
    		  my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);
		  $w->activate($upperLeft);
		  $w->selectionClear('all');
		  
		 }
	);


	# Make the return key enter and move down
	$mw->bind($class,'<Return>',['MoveCell',1,0]);
	$mw->bind($class,'<KP_Enter>',['MoveCell',1,0]);
	
	# Make the tab key enter and move right
 	$mw->bind($class,'<Tab>',
			sub{ 
				my $w = shift;
				$w->MoveCell(0,1);
				Tk->break;
			}
	);
 	$mw->bind($class,'<Shift-KP_Tab>',['MoveCell',0,-1]);

        # Make the delete key delete the selection, if no active cell
 	$mw->bind($class,'<Delete>',
		sub{
			my $self = shift;
			my $active;
			# Get the current active cell, if one exists
			eval { $active = $self->index('active'); }; 

			$active = '' if( $@); # No Active cell found;

			# No Active cell if it is set to the upper left column (esc key pressed)
    			my $upperLeft = $self->cget(-roworigin).",".$self->cget(-colorigin);

			$active = '' if( $active eq $upperLeft); # No Active cell found;
			
			if( $active eq ''){  # No Active Cell, delete the selection
				   eval
				    {
				     $self->curselection(undef);# Clear whatever is selected
				     $self->selectionClear();
				     }
			}
			else{  # There is a current active cell, perform delete in that
				$self->deleteActive('insert');
			}
		}
		
	);
	
	# Button2 release pastes from PRIMARY (control v pastes from clipboard
	 $mw->bind($class,'<ButtonRelease-2>',
		  sub
		   {
		    my $w = shift;
		    my $Ev = $w->XEvent;
		    $w->Paste($w->index('@' . $Ev->x.",".$Ev->y),'PRIMARY') unless ($Tk::TableMatrix::tkPriv{'mouseMoved'});
		   }
		 );


};


sub Populate {
    my ($cw, $args) = @_;
    
    # Set Default Args:
    $args->{-bg} = 'white' unless defined( $args->{-bg});
    
    $args->{-colstretchmode} = 'unset' unless defined( $args->{-colstretchmode});

    # Default behavior is to not allow cell resizing, just at the row/col titles (like Excel)
    $args->{-resizeborders}  = 'none' unless defined( $args->{-resizeborders});
    
    
    $cw->SUPER::Populate($args);
    
    # default Tags
    $cw->tagConfigure('active', -bg => 'gray90', -relief => 'sunken', -fg => 'black');
    $cw->tagConfigure( 'title', -bg => 'gray85', -fg => 'black', -relief => 'sunken');
   
   
    # setup Popup Menu (right mouse-button press) for common operations
    my $popup = $cw->Menu('-tearoff' => 0);
    $popup->command('-label' => 'Insert', -bg => 'gray85', '-command' => ['insertRowCol',$cw] );
    $popup->command('-label' => 'Delete', -bg => 'gray85','-command' => ['deleteRowCol',$cw] );
    $popup->command('-label' => 'Clear Contents', -bg => 'gray85','-command' => ['curselection', $cw,''] );
 
 
 
 
    # Bind a sub for button 3 press
    $cw->bind('<ButtonPress-3>', 

	sub {
	

	    	my $Ev = $cw->XEvent;

		# Don't Do anything if we are on a cell border
		#  This keeps the right-click menu from pop-ing up
		#  when starting a cell re-size
		my @border = $cw->border('mark',$Ev->x,$Ev->y);
		# print "border = ".join(", ",@border)." size = ".scalar(@stuff)."\n";
		
		# return if on a border or if not in edit mode
	        return if( scalar(@border) || ( $cw->cget(-state) =~ /disabled/i ));
		

		my $inTitleArea = 0;  # Flag = 1 if we are in a title Area
		my $inSelectedArea = 0; # Flag = 1 if we are in a selected area

		my ($x,$y) = ($Ev->x, $Ev->y);	
			
		my $pointerLoc = $cw->index('@'."$x,$y");
		$cw->{pointerLoc} = $pointerLoc; # Save pointer location for the insert/delete row routines
					         # After the local menu pops up and a item is selected, the pointer
						 #  location won't be valid anymore
		
		# print "Pointer over = '$pointerLoc'\n";
		
		if( $cw->tagIncludes('title',$pointerLoc) && $pointerLoc ne '0,0' ){
			# print "Pointer over a title area\n";
			$inTitleArea = 1;
			
		}
		if( $cw->selectionIncludes($pointerLoc)){
			$inSelectedArea = 1;
			# print "In Selected Area\n";
		}

		if( $inTitleArea && !$inSelectedArea){ # select the row/col if
						       # in title area and not selected
			$cw->BeginSelect($pointerLoc);
		}
			
		if( $inTitleArea ){
			$popup->Popup('-popover' => 'cursor', '-popanchor' => 'nw');
		}
		
	}
     );

    
}

# Sub to insert row/cols
sub insertRowCol{

	my $cw = shift;

	my $pointerLoc = $cw->{pointerLoc}; # use the pointer locatin from before the popup window came up
	my ($r,$c) = split(",",$pointerLoc);
	#print "pointerLoc = $r, $c\n";
	
	if( $r <= 0){ # Insert Col
		my %cols;
		@cols{map /(\d+)$/, $cw->tagCell('sel')} = 1;
		my @cols = sort {$a <=> $b} keys %cols;
		
		my $minCol = $cols[0];
		my $colCount = $cols[-1] - $minCol + 1;
		$cw->insertCols($minCol,-$colCount);
		
		# Make selection and clear
		my $lastRow = $cw->index('end','row');
		$cw->selectionSet("0,$minCol","$lastRow,".$cols[-1]);
		$cw->curselection('');		
	}
	elsif( $c <= 0 ){
		my %rows;
		@rows{map /^(\d+)/, $cw->tagCell('sel')} = 1;
		my @rows = sort {$a <=> $b} keys %rows;
		
		my $minRow = $rows[0];
		my $rowCount = $rows[-1] - $minRow + 1;
		$cw->insertRows($minRow,-$rowCount);
		
		# Make selection and clear
		my $lastCol = $cw->index('end','col');
		$cw->selectionSet("$minRow,0",$rows[-1].",$lastCol");
		$cw->curselection('');		
		
	}
	
}

# Sub to delete row/cols
sub deleteRowCol{

	my $cw = shift;

	my $pointerLoc = $cw->{pointerLoc}; # use the pointer locatin from before the popup window came up
	my ($r,$c) = split(",",$pointerLoc);
	#print "pointerLoc = $r, $c\n";
	
	if( $r <= 0){ # Delete Col
		my %cols;
		@cols{map /(\d+)$/, $cw->tagCell('sel')} = 1;
		my @cols = sort {$a <=> $b} keys %cols;
		
		my $minCol = $cols[0];
		my $colCount = $cols[-1] - $minCol + 1;
		$cw->deleteCols($minCol,$colCount);
		
		# Make selection
		my $lastRow = $cw->index('end','row');
		$cw->selectionSet("0,$minCol","$lastRow,".$cols[-1]);
	}
	elsif( $c <= 0 ){
		my %rows;
		@rows{map /^(\d+)/, $cw->tagCell('sel')} = 1;
		my @rows = sort {$a <=> $b} keys %rows;
		
		my $minRow = $rows[0];
		my $rowCount = $rows[-1] - $minRow + 1;
		$cw->deleteRows($minRow,$rowCount);
		
		# Make selection
		my $lastCol = $cw->index('end','col');
		$cw->selectionSet("$minRow,0",$rows[-1].",$lastCol");
		
	}
	
}

# General Motion routine. Sets the border cursor to <-> if on a row border.
#  or vertical resize cursor if on a col border

sub GeneralMotion{

	my $self  = shift;
	my $Ev = $self->XEvent;

	my $rc = $self->index('@' . $Ev->x.",".$Ev->y);
	return unless($rc);
	
	my ($row,$col) = split(',',$rc);
	my $rowColResize = $self->{rowColResize};  # Flag = 1 if cursor has been changed for a row/col resize
	my $rowColResizeOldCursor = $self->{rowColResizeOldCursor};          #  name of old cursor that was changed;
	my $rowColResizeOldBDCursor = $self->{rowColResizeBDOldCursor};          #  name of old BD cursor that was changed;
	
	my @border = $self->border('mark',$Ev->x,$Ev->y);
	if( scalar(@border) ){  # we are on a border
		my ($r,$c) = @border;
		
		# print "In motion $r, $c: $row, $col\n";
		
		# my $currentBDCursor = $self->cget(-bordercursor);

		if( ($col <= 0) && ($r =~ /\d/)  ){
			# print "Row Border = $r\n";
			# print "Setting Row Border \n";
			unless($rowColResize){
				$self->{rowColResizeOldCursor} = $self->cget(-cursor);
				$self->{rowColResizeBDOldCursor} = $self->cget(-bordercursor);
				$self->configure(-cursor => 'sb_v_double_arrow',
					-bordercursor => 'sb_v_double_arrow');
				$self->{rowColResize} = 1;
				$self->{rowColResizeRow} = $r;
				$self->{rowColResizeCol} = undef;
			}
			
		}
		elsif( ($row <= 0) && ($c =~ /\d/) ){
			# print "Col Border = $c\n";
			unless($rowColResize){
				$self->{rowColResizeOldCursor} = $self->cget(-cursor);
				$self->{rowColResizeBDOldCursor} = $self->cget(-bordercursor);
				$self->configure(-cursor => 'sb_h_double_arrow',
					-bordercursor => 'sb_h_double_arrow');
				$self->{rowColResize} = 1;
				$self->{rowColResizeRow} = undef;
				$self->{rowColResizeCol} = $c;
			}

		}
		
	}
	else{
		if( $rowColResize && !($self->{rowColResizeDrag}) ){  # Change cursor back if it has been changed, and
									# we aren't currently doing a row/col resize drag.
			#print "Setting to $oldCursor\n";
			$self->configure(-cursor => $rowColResizeOldCursor,
				-bordercursor => $rowColResizeOldBDCursor);
			$self->{rowColResize} = 0;
		}

	}
			
		
}

######################################################################3
## Over-ridden beginselect. Sets the rowColResizeDrag to indicate
## that we are doing a row or column resize operation
sub borderDragto{
	my $self = shift;
	my @args = @_;
	
       if( !$self->{rowColResizeDrag}){
	       #print "StartDrag\n";
	       $self->{oldResizeBorders} = $self->cget(-resizeborders); # save the value of resizeborders so we can restore it later
	       $self->configure(-resizeborders => 'both');
       }
	$self->{rowColResizeDrag} = 1;  # Flag = 1 if we are currently doing a row/col resize drag
	$self->SUPER::borderDragto(@args);
}

##################################################################
# Over-ridden Motion routine. Does a row/col resize if
#   row/col resize cursors are active
#    This is needed for linux for the row resize to work
#      Not sure why
sub Motion{
	my $self  = shift;
	my $rc = shift;

	if( $self->{rowColResize}){ # Do a row/col resize if cursors active
		my $Ev = $self->XEvent;
		
		if( !$self->{rowColResizeDrag}){   # Same as the borderDragTo, somethings this gets called first
			#print "StartDrag\n";
	       		$self->{oldResizeBorders} = $self->cget(-resizeborders); # save the value of resizeborders so we can restore it later
	      	 	$self->configure(-resizeborders => 'both');
		}
		$self->{rowColResizeDrag} = 1;  # Flag = 1 if we are currently doing a row/col resize drag
		$self->SUPER::borderDragto($Ev->x,$Ev->y);
	}
	else{
		
		$self->SUPER::Motion($rc);
	}
}
			
#############################################################
## Over-ridden beginselect. Doesn't select if we are doing a row/col resize
sub BeginSelect{
	my $self  = shift;
	my $rc = shift;
	
	return if( $self->{rowColResize}); # Don't Select if currently doing a row/col resize
	
	# print "Calling inherited BeginSelect\n";
	$self->SUPER::BeginSelect($rc);
	
}


#############################################################
## Over-ridden TableInsert. 
##  If a  key is pressed and a cell is not activated. Activate the
##    current cell and insert the key pressed
sub TableInsert{
	my $self  = shift;
	my $key = shift;

	# my $Ev = $self->XEvent;

	# Activate the current anchor position, if 
	#  key pressed, and no cell currently active
	
	# Get the current active cell, if one exists
	eval { $active = $self->index('active'); }; 
		
	$active = '' if( $@); # No Active cell found;

	# No Active cell if it is set to the upper left column (esc key pressed)
    	my $upperLeft = $self->cget(-roworigin).",".$self->cget(-colorigin);

	$active = '' if( $active eq $upperLeft); # No Active cell found;

	if( $key ne '' && $active eq '' ){
        	my $anchor = $self->index('anchor');
		$self->activate($anchor);
		$self->deleteActive(0,'end'); # delete text from the cell
	}
		
	$self->SUPER::TableInsert($key);
	
}


#############################################################
## Over-ridden MoveCell. 
##  This method performs moving cells in a more Excel-like way:
##   1) Moving cell when one is active unactivates the cell and then selects (not activates)
##      the new cell
##   2) Moving cell when none is active moves the anchor point cell, if one exits.
##   3)  Does nothing otherwise

sub MoveCell{

	my $w = shift;
	my $x = shift; # Delta X for moving
	my $y = shift; # Delta y for moving
	my $c;
	my $cell;      # new cell index
	my $true;
	my $r;
	
	my $fromCell; # Cell to move from (Could be an active cell, if present, or selection anchor point
		      #  if present.
		      
	my $active;    # Current active cell

	# Get the current active cell, if one exists
	eval { $active = $w->index('active'); }; 

	$active = '' if( $@); # No Active cell found;

	# No Active cell if it is set to the upper left column (i.e. esc key pressed)
    	my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);

	$active = '' if( $active eq $upperLeft); # No Active cell found;

	if( $active eq ''){  # no active cell found, see if there is a selection
		my $anchor = $w->index('anchor');

				
		unless( defined($anchor) ){
			# print "Anchor not defined\n";
			return;
		}
		
		$fromCell = $anchor;
	}
	else{
		$fromCell = $active;
	}
			

	($r,$c) = split(',',$fromCell);
	# my $currentCell = "$r,$c";

	$cell = $w->index(($r += $x).",".($c += $y));


	$w->activate($upperLeft) if( $active ne '');
	$w->see($cell);
	if ($w->cget('-selectmode') eq 'browse')
	 {
	  $w->selection('clear','all');
	  $w->selection('set',$cell);
	 }
	elsif ($w->cget('-selectmode') eq 'extended')
	 {
	  $w->selection('clear','all');
	  $w->selection('set',$cell);
	  $w->selection('anchor',$cell);
	  $Tk::TableMatrix::tkPriv{'tablePrev'} = $cell;
	 }
}	
	

#############################################################
## Over-ridden Paste. 
##  This method performs pasting cells in a more Excel-like way:
##   Paste Data will be pasted into the current selection anchor point
##     if no current cell is active, otherwise it pastes starting at the active
##       cell.
##
##   If no current active cell, and no anchor point, does nothing.
sub Paste{
	 my $w = shift;
	 my $cell = shift || ''; 
	 my $source = shift || 'CLIPBOARD';  # Default is to paste from the clipboard
	 my $data;
	 
	 # Check for active cell or anchor cell:
	 unless($cell){


		my $active;    # Current active cell

		# Get the current active cell, if one exists
		eval { $active = $w->index('active'); }; 

		$active = '' if( $@); # No Active cell found;

		# No Active cell if it is set to the upper left column (i.e. esc key pressed)
    		my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);

		$active = '' if( $active eq $upperLeft); # No Active cell found;

		if( $active eq ''){  # no active cell found, see if there is a selection
			$cell = $w->index('anchor');

			return unless( $cell); # don't paste if no anchor point and no active

		}
		else{
			$cell = $active;
		}

	 }
	 
	 eval{ $data = $w->SelectionGet(-selection => $source); }; return if($@);
 	 $w->PasteHandler($cell,$data);
 	 $w->focus if ($w->cget('-state') eq 'normal');
}


#############################################################
#
# Sub called when button 1 released. 
#   Takes care or row/col border drags. 
#     Also checks to see if more than one row/col is selected during
#     a row/col resize, so those row/cols will be resized as well
sub Button1Release{
    my $w  = shift;
    my $Ev = $w->XEvent;
    #print "Button Release 1\n";
    if ( $w->{rowColResizeDrag} ) {   # Row/Col resize finishing up
        my @selRowCol = $w->curselection;
        if ( $w->{rowColResizeRow} ) { # Row risize, check for other rows selected
            my $row = $w->{rowColResizeRow};

            my $newRowHeight = $w->rowHeight($row);
            #print "Resized row $row to height" . $newRowHeight . "\n";

           # Find other selected rows (must be contiguous selected from the drag row)
            my $rowOrg = $w->cget( -roworigin );
            my $colOrg = $w->cget( -colorigin );
            my $rowMax = $rowOrg + $w->cget( -rows ) - 1;    # max row in table
            my $firstDataRow =
              $rowOrg + $w->cget( -titlerows );              # first Data Row
            my $firstDataCol =
              $colOrg + $w->cget( -titlecols );              # first Data Col
            my @otherRowsSelected;
            foreach my $row ( ( $row + 1 ) .. $rowMax ) {    # Increasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$row,$firstDataCol") );
                push @otherRowsSelected, $row;
            }
            foreach my $row ( reverse( $firstDataRow .. ( $row - 1 ) ) )
            {                                                # Decreasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$row,$firstDataCol") );
                push @otherRowsSelected, $row;
            }

            # Set New row height for other rows
            if (@otherRowsSelected) {

                #  Set args to row => height, row => height ...
                my @rowHeightArgs =
                  map { $_ => $newRowHeight } @otherRowsSelected;
                $w->rowHeight(@rowHeightArgs);
            }
        }
        elsif ( $w->{rowColResizeCol} ) { # Col risize, check for other Cols selected
            my $col = $w->{rowColResizeCol};

            my $newColWidth = $w->colWidth($col);
            #print "Resized col $col to width" . $newColWidth . "\n";

           # Find other selected cols (must be contiguous selected from the drag col)
            my $rowOrg = $w->cget( -roworigin );
            my $colOrg = $w->cget( -colorigin );
            my $colMax = $colOrg + $w->cget( -cols ) - 1;    # max col in table
            my $firstDataRow =
              $rowOrg + $w->cget( -titlerows );              # first Data Row
            my $firstDataCol =
              $colOrg + $w->cget( -titlecols );              # first Data Col
            my @otherColsSelected;
            foreach my $col ( ( $col + 1 ) .. $colMax ) {    # Increasing cols
                #print "Checking for inclusion of $firstDataRow,$col\n";
                last unless ( $w->selectionIncludes("$firstDataRow,$col") );
                push @otherColsSelected, $col;
            }
            foreach my $col ( reverse( $firstDataCol .. ( $col - 1 ) ) )
            {                                                # Decreasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$firstDataRow,$col") );
                push @otherColsSelected, $col;
            }

            # Set Col width height for other rows
            if (@otherColsSelected) {

                #  Set args to row => height, row => height ...
                my @colWidthArgs =
                  map { $_ => $newColWidth } @otherColsSelected;
                $w->colWidth(@colWidthArgs);
            }
        }
    }

    if($w->{rowColResizeDrag}){
    
        # restore the value of resize borders to what is was before
	if( my $oldResizeborders = $w->{oldResizeBorders}){
    		$w->configure(-resizeborders => $oldResizeborders);
		delete $w->{oldResizeBorders};
	}
    
    	#print "Drag Finished\n";
    }
    
    $w->{rowColResizeDrag} = 0;        # reset row/col resize dragging flag
    $w->{rowColResizeRow}  = undef;    # reset row resize flag
    $w->{rowColResizeCol}  = undef;    # reset col resize flag
    if ( $w->exists ) {
        $w->CancelRepeat;

    }
}


1;

