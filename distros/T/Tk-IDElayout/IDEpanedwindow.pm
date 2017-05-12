=head1 NAME 

Tk::IDEpanedwindow - Subclass of L<Tk::Panedwindow> to Control Pane Resize Behavior

=head1 SYNOPSIS

    use Tk::IDEpanedwindow;

    # Create panedwindow (Just like Tk::Panedwindow)
    $panedwidnow = $widget->IDEpanedwindow( ? options ? );

    # Pack the widget
    $panedwidnow->pack(qw/-side top -expand yes -fill both /);

    # Create two frames to insert
    my $label1 = $panedwidnow->Label(-text => "This is the\nleft side", -background => 'yellow');
    my $Frame2 = $panedwidnow->Frame();
    
    # Insert the frames, with expand factors = 1 (both frames will grow/shrink with the size
    #       of the window)
    $pwH->add($label1, -expandfactor => 1, $Frame2, -expandfactor => 1);


=head1 DESCRIPTION

This is a subclass of the L<Tk::Panedwindow> widget that adds a I<expandfactors> option 
that controls how the paned-windows are resized when the overall widget is resized. 

The parent class L<Tk::Panedwindow> only changes the last pane when the entire widget is resized. 
Using the I<-expandfactors> option of this widget, you can control how each paned-window is resized when the overall widget is resized.
	
Note: The idea for the I<-expandfactors> option is borrowed from the TCL/TK widget I<TixPanedWindow>.

=head1 OPTIONS

In addition to the options from the parent class L<Tk::Panedwindow>, this widget provides the following options:

=over 1

=item expandfactors

Array ref of expand factors to use for each pane in the widget.
        
Each Expand Factor must be a non-negative number. The default value is 0. 
The expand/shrink factor is used to calculate how much each pane should grow or shrink when the size of the PanedWindow
main window is changed. When the main window expands/shrinks by n pixels, 
then pane i will grow/shrink by about n * factor(i) / summation(factors), where factor(i) is the expand/shrink factor of pane i
and summation(factors) is the summation of the expand/shrink factors of all the panes. 
If summation(factors) is 0.0, however, only the last visible pane will be grown or shrunk.

Note: The behavior of this I<-expandfactors> option is borrowed from the TCL/TK widget I<TixPanedWindow>.

=item fractSizes

Array ref of fractional (i.e. less than one) sizes left over from the last resize of the pane frames.
        
Even though frame sizes are number of pixels (integers), we keep track of the fractional part of the calculated
frame sizes from resize-event to resize-event. This keeps the sizes of the frames in proportion to each other better
than throwing away the fractional part would.

=back 

=head1 ATTRIBUTES

=over 1

=item slaves

Array ref of L<Tk::Widget> objects in each frame of the panedwindow.

=back

=head1 Methods

=cut

package Tk::IDEpanedwindow;
our ($VERSION) = ('0.33');

use Carp;
use strict;


use Tk;

use base qw/ Tk::Derived Tk::Panedwindow/;

our ($DEBUG); 

Tk::Widget->Construct("IDEpanedwindow");




sub Populate {
    my ($cw, $args) = @_;
     
    $cw->SUPER::Populate($args);

    # Initialize the slaves attribute
    $cw->{slaves} = [];
    
    $cw->{fractSizes} = [];
    
    $cw->ConfigSpecs( 
		      -expandfactors => [ qw/PASSIVE expandfactors expandfactors/, [] ],
    );
    
    my ($totalW, $totalH) = (0,0);
    
    # Add Bindings
    $cw->bind('<Configure>', sub{ 
	    
            return unless ($cw->ismapped); # Don't do anything until widget is actually displayed
            
	    my ($newTotalW, $newTotalH) = ($cw->width, $cw->height);
            
            #print "newTotalW/H $newTotalW/$newTotalH  totalW/H = $totalW/$totalH\n";
	    return if(  $totalH == $newTotalH && $newTotalW == $totalW);
            
            if( $totalW == 0 && $totalH == 0){ # Initially just set the totalW/H variables
                    $totalW = $newTotalW;
                    $totalH = $newTotalH;
                    return;
            }
            
            #print "new H $newTotalH  totalH = $totalH\n";
            
            # Get all widgets managed by pw2
            my @widgets = $cw->slaves;
            #print "sizeof widgets = ".scalar(@widgets)."\n";
            
            #print "widgets = ".join(", ", @widgets)."\n";
            my @heights = ();
            
            my $sizeMethod; # Method used to get widget size, depends on orientation
            $sizeMethod = "height" if( $cw->cget(-orient) =~ /vert/);
            $sizeMethod = "width"  if( $cw->cget(-orient) =~ /horiz/);

            foreach my $widget(@widgets){
                    push @heights, $widget->$sizeMethod();
                    #print $widget->geometry."\n";
            }
            #print "Heights = ".join(", ", @heights)."\n";
            
            # Get the total height of the panewindow widget (but will be 1 initially before mapped?)
	    my $height = $cw->$sizeMethod();
            
	    
	    #print "SashCords = ".join(", ", @sashCoords)." height = $height\n";
	    if($height > 1){
                    my $expandFactors = $cw->cget(-expandfactors);
                    my @newHeights = $cw->_getNewSizes( $height, [@heights], [@$expandFactors]);
                    $cw->adjustSizes([@newHeights]);
                    
	#	    $pw2->sashPlace(0, $sashCoords[0], $height * $ratio);
		    #print "new Sash Location = ".$height*$ratio."\n";
            }

           
	    ($totalW, $totalH) = ($newTotalW, $newTotalH);
    }
    );
}


#######################################################################

=head2 add

Over-ridden add method add a new widget to the collection managed by the L<Tk::IDEpanedwindow>.
        
This method adds a -expandfactor option to the normal options recognized by the parent L<Tk::Panedwindow>. 

B<Usage:>

   $widget->add(?window ...? ?option value ...?);


=cut

sub add{
	
	my $self = shift;
	my @args = @_;
	
	# Parse the args
        my @widgets;
        my %widgetArgs;
        my $widget; # current widget that options apply to
        while(@args){
                $widget = shift @args;
                unless( ref($widget) && $widget->isa("Tk::Widget")){
                        croak("Error: arg '$widget' supplied to Tk::IDEpanedwindow::add is not a Tk Widget\n");
                }
                push @widgets, $widget;
                
                # Make hash entry for the args of this widget
                my $argsHash = $widgetArgs{"$widget"} = {}; 

                while(@args && $args[0] =~ /^\-/ ){ # Process any arguments
                        my $key =   shift @args;
                        my $value = shift @args;
                        $argsHash->{$key} = $value;
                }
        }
        
        my $expandfactors = $self->cget(-expandfactors);
        
        my $slaves = $self->{slaves};
        my $fractSizes = $self->{fractSizes};
        
        ## Process the args of each widget
        foreach $widget(@widgets){
                my $expandfactor = delete $widgetArgs{"$widget"}{-expandfactor} || 0;
                
                # Handle where to put the expandfactor, based on -before or -after args
                if( defined($widgetArgs{"$widget"}{-before})){ # 
                        my $before = $widgetArgs{"$widget"}{-before};
                        my $beforeIndex;
                        my $index = 0;
                        foreach (@$slaves){ # Find index of the $before widget
                                if( $_ eq $before ){
                                        $beforeIndex = $index;
                                        last;
                                }
                        }
                        croak("Error Can't find -before widget $before in slaves list\n") unless defined($beforeIndex);
                        
                        # Update strucutes in the correct place
                        splice @$expandfactors, $beforeIndex, 0, $expandfactor;
                        splice @$slaves, $beforeIndex, 0, $widget;
                        splice @$fractSizes, $beforeIndex, 0, 0;
                }
                elsif( defined($widgetArgs{"$widget"}{-after})){ # 
                        my $after = $widgetArgs{"$widget"}{-after};
                        my $afterIndex;
                        my $index = 0;
                        foreach (@$slaves){ # Find index of the $before widget
                                if( $_ eq $after ){
                                        $afterIndex = $index;
                                        last;
                                }
                        }
                        croak("Error Can't find -after widget $after in slaves list\n") unless defined($afterIndex);
                        
                        splice @$expandfactors, $afterIndex + 1, 0, $expandfactor;
                        splice @$slaves, $afterIndex + 1, 0, $widget;
                        splice @$fractSizes, $afterIndex + 1, 0, 0;
                }
                else{ # Normal add at the end
                                
                        push @$expandfactors, $expandfactor;
                        push @$slaves, $widget;
                        push @$fractSizes, 0;
                }
        }
        
        # Save back the populated expandfactors
        $self->configure(-expandfactors => $expandfactors);
        
        # Call the parent widget  ####
        ##   Build the args to call the parent (minus any expandfactors)
        my @parentArgs;
        foreach $widget(@widgets){
                push @parentArgs, $widget;
                my $options = $widgetArgs{"$widget"};
                if( keys %$options){ # Add any options for this widget
                        push @parentArgs, %$options;
                }
        }
        
        $self->SUPER::add(@parentArgs);
                                
}

#######################################################################

=head2 forget

Over-ridden forget method to delete a widget from the paned-window.
        
This deletes the widget from our own I<slaves> list before calling the parent method.

B<Usage:>

   $widget->forget($window);


=cut

sub forget{
	
	my $self = shift;
        
        my $window = shift;
        
         
        my $expandfactors = $self->cget(-expandfactors);
        
        my $slaves = $self->{slaves};
        my $fractSizes = $self->{fractSizes};
        
        # Find widget in slaves
        my $matchIndex = -1;
        my $i = 0;
        foreach my $slave(@$slaves){
                if( $slave eq $window){
                        $matchIndex = $i;
                }
                $i++;
        }
        
        if( $matchIndex > -1){ # Get rid of this window from our lists, if a match found
                 splice(@$slaves, $matchIndex, 1);
                 splice(@$fractSizes, $matchIndex, 1);
                 splice(@$expandfactors, $matchIndex, 1);
                 
                 # Save back the populated expandfactors
                 $self->configure(-expandfactors => $expandfactors);
        }
        
        $self->SUPER::forget($window);
}
                
##################################################

=head2 slaves

Gets (and optionally sets) the slaves attribute. 
        
B<Usage:>

	my @slaves = $self->slaves();    # Get slaves
	
	$self->slaves(@slaves);          # Set slaves


=cut

sub slaves{
    my $self = shift;
    
    if (defined $_[0]) {
    	    my @slaves = @_;
            my $slaves = $self->{slaves};
            @$slaves = @slaves;
    }
    
    my $slaves = $self->{slaves};
    return @$slaves;
    
}

#####################################################################

=head2 _getNewSizes

Internal method to get / calculate the new widget Sizes (Width or height) of a panewindow widget,
based on total pw size, widget sizes, and expand factors.
        
This is called when the size of the panedwindow widget changes.

B<Usage:>

   @newSizes = $self->_getNewSizes($newSize, $sizes);
   
        where:   $newSize:   Total new size of the panewindow widget
                               (Along the paned direction)
                 $sizes:     Array ref of old sizes (i.e. not yet adjusted
                                 for the new total-size) for each window
                                 managed by the panedwindow.

=cut

# Sub to get / calculate the new widget Sizes (Width or height) of a panewindow widget,
#   based on total pw size, widget sizes, and expand factors
sub _getNewSizes{
        my ($pw, $newSize, $sizes) = @_;
        
        my $expandFactors = $pw->cget(-expandfactors);
                
        ### Calculate total size using current sizes
        my $oldTotalSize = 2; # PW always pads top and bottom by two
        my $sashPad = $pw->cget(-sashpad);
        my $sashW   = $pw->cget(-sashwidth);
        
        my $Sindex = 0;
        foreach my $size(@$sizes){
                $oldTotalSize += $size;
                unless( $Sindex == $#$sizes){ # Add sash width, unless this is the last one
                        $oldTotalSize += ($sashPad + $sashW + $sashPad);
                }
                $Sindex++;
        }
        $oldTotalSize += 2; # PW always pads top and bottom by two
        
        # Calc New Space Delta
        my $spaceDelta = $newSize - $oldTotalSize;
        #print "####### newHeight = $newSize, totalHeight $oldTotalSize Space Delta = $spaceDelta\n";
        #print "$pw orient ".$pw->cget(-orient)." ExpandFactors = ".join(", ", @$expandFactors)."\n";   
        # Normalize expand factors
        my @expandFactors = @$expandFactors; # Copy for us to mess with
        my $expandSum = 0;
        foreach (@expandFactors){ $expandSum+=$_; };
        
        # If all factors zero, make the last expandFactor 1 ( like default panedwindow behaviour)
        if( $expandSum < .0001){
                $expandSum = 1;
                $expandFactors[-1] = 1;
        }
        
        
        my @normExpand;
        foreach (@$expandFactors){ push @normExpand, $_/$expandSum };

        # Calulate new heights
        my @newSizes;
        $Sindex = 0;
        my ($newS, $newSfract); # New Size (rounded), and new Fractional size (not rounded)
        my $expandFact;
        my $fractSizes = $pw->{fractSizes};
        foreach my $s (@$sizes){
                my $fractSize = $fractSizes->[$Sindex]; # Fractional size for the current frame
                $expandFact = $normExpand[$Sindex];
                
                $newSfract = $s + $expandFact*$spaceDelta + $fractSize; # Calc new size, including left-over fraction from last times
                
                $newS = sprintf("%.0f", $newSfract); # Round to get real size
                
                # Save left-over fraction for next time
                $fractSizes->[$Sindex] = $newSfract - $newS;
                
                push @newSizes, $newS;
                $Sindex++;
        }
        
        #print "Old Sizes = ".join(", ", @$sizes)." New Sizes = ".join(", ", @newSizes)."\n";
        return @newSizes;
}

################################################################3

=head2 adjustSizes

Method to adjust the sizes of each pane in the paned-window direction.

B<Usage:>

   $self->adjustSizes($newSizes);
   
        where:   $newSizes:   Array ref of new sizes  for each window
                                 managed by the panedwindow.

=cut

sub adjustSizes{
        my ($pw, $newHeights) = @_;

        ### Calculate sashCoords
        my $sashCoord = 2; # PW always pads top and bottom by two
        my $sashPad = $pw->cget(-sashpad);
        my $sashW   = $pw->cget(-sashwidth);
        my $orient = $pw->cget(-orient);
        #return if($orient eq 'vertical');
        
        my $Hindex = 0;
        foreach my $height(@$newHeights){
                $sashCoord += $height;
                unless( $Hindex == $#$newHeights){ # Add sash width, unless this is the last one
                        $sashCoord += $sashPad; # Add padding to get to location of sash
                        #print "## Setting SashCoord $Hindex to $sashCoord\n";
                        #print "orient = ".$pw->cget(-orient)."\n";
                        
                        # Set sashcord based on orientation (horiz or vert)
                        $pw->sashPlace($Hindex, 2, $sashCoord) if( $orient =~ /vert/);
                        $pw->sashPlace($Hindex, $sashCoord, 2) if( $orient =~ /horiz/);
                        $sashCoord += ($sashW + $sashPad); # Add sashwidth and sashpad to get past the sash
                }
                $Hindex++;
        }
}

1;
