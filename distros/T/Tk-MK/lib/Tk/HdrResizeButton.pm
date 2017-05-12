package Tk::HdrResizeButton;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision    = '$Revision: 1.4 $';
our $CheckinDate = '$Date: 2009/04/06 20:46:00 $';
our $CheckinUser = '$Author: xpix $';

# we need to clean these up right here
$Revision    =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;

#-------------------------------------------------
#-- package Tk::HdrResizeButton ---------------------
#-------------------------------------------------
use vars qw ($VERSION);
$VERSION = '1.5';

#########################################################################
# Tk::HdrResizeButton 
# Summary:  This widget creates a button for use in an HList header which
#           provides methods for resizing a column. This was heavily 
#	    leveraged from Columns.pm by Damion Wilson.
# Author:   Shaun Wandler
# Date:     $Date: 2009/04/06 20:46:00 $
# Revision: $Revision: 1.5 $
#########################################################################=
#####
#
# Updated by Slaven Rezic and Frank Herrmann, Michael Krause
#

# XXX needs lot of work:
# DONE (MK) * position columnbar correctly and only use MoveColumnBar to move it instead
# 	of destroying it and re-creating with CreateColumnBar
# (for what?) * use Subwidget('scrolled') if it exists
# DONE (MK) * don't give error if -command is not specified
# DONE (MK) * don't let the user hide columns (minwidth?)
# DONE (MK) * double-click on column should not more execute the single-click command callback
# DONE (MK) * configurable closedcolWidth, ResizeWidth

use base qw(Tk::Derived Tk::Button);
use strict;

Construct Tk::Widget 'HdrResizeButton';

sub ClassInit
{
	my ($class, $mw) = @_;
	$class->SUPER::ClassInit($mw);
	$mw->bind( $class, '<ButtonRelease-1>', 'ButtonRelease' );
	$mw->bind( $class, '<ButtonPress-1>',   'ButtonPress' );
	$mw->bind( $class, '<Motion>',          'ButtonOver' );
	$mw->bind( $class, '<ButtonRelease-3>', 'ColumnFullSize' );
	$mw->bind( $class, '<Double-1>',        'ButtonDouble1' );

	# Override these ones too
	$mw->bind($class, '<Enter>', 'BttnEnter' );
	$mw->bind($class, '<Leave>', 'BttnLeave' );

	return $class;
}

sub Populate
{
	my ($this, $args) = @_;

	# CREATE THE RESIZE CONTROL
	my $r_Widget;
	my $r_width = delete $args->{-resizerwidth} || 1;
	$r_Widget = $this->Component(
		'Frame'      => 'Trim_R',
		#-background  => 'white',
		#-relief      => 'raised',
		-borderwidth => 1,
		-width       => $r_width,
		-cursor 	 => 'sb_h_double_arrow',
	)->place(
		-bordermode => 'outside',
		-relheight => '1.0',
		-anchor	=> 'ne',
		-relx  	=> '1.0',
	);

	# CREATE THE COLUMNBAR
	$this->{columnBar} = $this->parent->Frame(
		-background  => 'white',
		-relief      => 'raised',
		-borderwidth => 2,
		-width       => 2,
	);

	$r_Widget->bind( '<ButtonRelease-1>'	=> sub { $this->ButtonRelease(1); } );
	$r_Widget->bind( '<ButtonPress-1>'		=> sub { $this->ButtonPress(1); } );
	$r_Widget->bind( '<Motion>' 			=> sub { $this->ButtonOver(1); } );
	$r_Widget->bind( '<Enter>'				=> sub { $this->TrimEnter(); } ); 
	$r_Widget->bind( '<Leave>'				=> sub { $this->TrimLeave(); } );

	# Override these ones too
	$this->bind( '<Enter>'					=> sub { $this->BttnEnter(); } );
	$this->bind( '<Leave>'					=> sub { $this->BttnLeave(); } );

	$this->SUPER::Populate($args);
	$this->ConfigSpecs(
		-column 			=> [ [ 'SELF', 'PASSIVE' ], 'column', 'Column', 0 ],
		-minwidth			=> [ [ 'SELF', 'PASSIVE' ], 'minwidth', 'MinWidth', 50 ], 
		-closedminwidth		=> [ [ 'SELF', 'PASSIVE' ], 'closedminwidth', 'ClosedMinWidth', 10 ], 
    	-command 			=> [ 'CALLBACK',undef,undef, sub {}],
		-activebackground	=> [ [ 'SELF', 'PASSIVE' ], 'activebackground', 'activebackground', $this->SUPER::cget(-background) ],
		-activeforeground	=> [ [ 'SELF', 'PASSIVE' ], 'activeforeground', 'activeforeground', 'red' ],
		-buttondownrelief	=> [ [ 'SELF', 'PASSIVE' ], 'buttondownrelief', 'buttondownrelief', 'groove' ],
		-relief 			=> [ [ 'SELF', 'PASSIVE' ], 'relief', 'relief', 'flat' ],
		-pady				=> [ [ 'SELF', 'PASSIVE' ], 'pady', 'pady', 0 ],
		-padx				=> [ [ 'SELF', 'PASSIVE' ], 'padx', 'padx', 0 ],
		-pady				=> [ [ 'SELF', 'PASSIVE' ], 'pady', 'pady', 0 ],
		-anchor				=> [ [ 'SELF', 'PASSIVE' ], 'anchor', 'Anchor', 'w' ],
		-lastcolumn			=> [ [ 'SELF', 'PASSIVE' ], 'lastcolumn', 'LastColumn', 0 ],
		-takefocus			=> [ [ 'SELF', 'PASSIVE' ], 'takefocus', 'TakeFocus', 1 ],
	);

	# Keep track of last trim widget
	$this->{m_LastTrim} = $r_Widget;
	# Initialize the Enter/Leave level counter
	$this->{m_Level} = 0;
}
# CALLED IF WE ENTER THE TRIM AREA
sub BttnEnter
{
	my $this = shift;
	$this->StateSalvation(1);
	$this->configure(-relief => $this->cget('-buttondownrelief')) if $this->{m_ButtonPress};
}
# CALLED IF WE LEAVE THE TRIM AREA
sub BttnLeave
{
	my $this = shift;
	$this->StateSalvation(-1);
	$this->configure(-relief => $this->{m_relief}) if $this->{m_relief};
}
# CALLED IF WE ENTER THE TRIM AREA
# sub TrimEnter
# {
# 	my $this = shift;
# 	$this->ButtonOver(1);
# 	$this->StateSalvation(2);
# }
sub TrimEnter
{
	my $this = shift;
	if ($this->cget('-lastcolumn')) {
		$this->Subwidget('Trim_R')->configure(-cursor => undef);
	}
	else {
		$this->Subwidget('Trim_R')->configure(-cursor => 'sb_h_double_arrow');
	}
	$this->ButtonOver(1);
	$this->StateSalvation(2);
}
# CALLED IF WE LEAVE THE TRIM AREA
sub TrimLeave
{
	my $this = shift;
	$this->StateSalvation(-2);
	$this->HideColumnBar();
}

# CALLED IF WE CLICK/DOUBLECLICK
sub OpenCloseColumn
{
	my $this = shift;

	my $column = $this->cget('-column');
	if ($this->{m_ColumClosed}{$column}) {
		$this->{m_ColumClosed}{$column} = 0;
		if ($this->{m_LastColumWidth}) {
			$this->parent->columnWidth($column, $this->{m_LastColumWidth});
		}
		else {
			$this->parent->columnWidth($column, '');
			$this->{m_LastColumWidth} = $this->parent->columnWidth($column);
		}
		$this->configure(-anchor => $this->{m_LastAnchor}) if $this->{m_LastAnchor};
	}
	else {
		$this->{m_ColumClosed}{$column} = 1;
		$this->{m_LastColumWidth} = $this->parent->columnWidth($column);
		$this->parent->columnWidth($column,  $this->cget('-closedminwidth'));
		$this->{m_LastAnchor} = $this->cget('-anchor');
		$this->configure(-anchor => 'w');
	}
	
}
# CALLED TO RESIZE A COLUMN TO THE NEEDED EXTENT
sub ColumnFullSize
{
	my $this = shift;
	my $column = $this->cget('-column');
	if ($this->{m_ColumClosed}{$column}) {
		delete $this->{m_LastColumWidth}; # This ensure immediate update
		$this->OpenCloseColumn();
	}
	else {
		$this->parent->columnWidth($column, '');
	}
}

## Event Handlers
sub ButtonPress
{
	my ($this, $p_Trim) = @_;
	$this->{m_LastEvent} = 'ButtonPress';	
	$this->{m_relief} = $this->cget('-relief');
	if ($this->ButtonEdgeSelected() || $p_Trim) {
		$this->{m_EdgeSelected} = 1;
		$this->{m_X} = $this->pointerx() - $this->rootx();
		$this->ButtonOver();
	}
	else {
		$this->configure(-relief => $this->cget('-buttondownrelief'));
		$this->{m_X} = -1;
	}
	$this->{m_ButtonPress} = 1;
}

sub ButtonRelease
{
	my ($this, $p_Trim) = @_;
	delete $this->{m_ButtonPress};
	$this->{m_EdgeSelected} = 0;
	$this->configure(-relief => $this->{m_relief});
	if ($this->{columnBar}) {
		$this->HideColumnBar();
	}
	if ($this->{m_X} >= 0) {
		my $l_NewWidth = ( $this->pointerx() - $this->rootx() );

		my $hlist = $this->parent;
		my $col   = $this->cget('-column');
		# Better resize to minimum than to do nothing
		$l_NewWidth = $this->cget('-minwidth') if ($l_NewWidth + 5) < $this->cget('-minwidth');
		$hlist->columnWidth( $col, $l_NewWidth + 5 );

		$this->GeometryRequest( $l_NewWidth, $this->reqheight() );
	} 
	elsif ( !$this->ButtonEdgeSelected() ) {
		# Run only if we're still over the header and if we're in TRUE Release Mode (No Dbl-Click)
		if ($this->cget('-state') eq 'active') {
			$this->after(500, sub { $this->Callback(-command => $this) if $this->{m_LastEvent} eq 'ButtonPress' } );
		}
	}

	$this->{m_X} = -1;
}

# CALLED IF WE DOUBLECLICK
sub ButtonDouble1
{
	my $this = shift;
	
	# Cancel a scheduled Release-Bttn-1 - attached Event
	$this->{m_LastEvent} = 'DoubleClick';

	# Execute the double-click default action
	$this->OpenCloseColumn();
}


# CHECK IF THE RESIZE CONTROL IS SELECTED
sub ButtonEdgeSelected
{
	my $this = shift;
	return ( $this->pointerx() - $this->{m_LastTrim}->rootx() ) > -1;
}

# CHANGE THE CURSOR OVER THE RESIZE CONTROL
sub ButtonOver
{
	my ($this, $p_Trim) = @_;
	if ( $this->{'m_EdgeSelected'} || $this->ButtonEdgeSelected() || $p_Trim ) {
		$this->MoveColumnBar() if $this->{columnBar};
	}
}
# AVOID ACTIVATING THE BUTTON, IF WE ARE IN THE TRIM
sub StateSalvation
{
	my ($this, $newlevel) = @_;
	if ($newlevel > 0) {
		$this->{m_Level}  |= $newlevel;
	}
	else {
		$this->{m_Level}  &= ~$newlevel;
	}
	if ($this->{m_Level} == 1 and not $this->{m_EdgeSelected}) {
		$this->configure(-state => 'active');
	}
	else {
		$this->configure(-state => 'normal');
	}
}

# Move a column bar which displays on top of the HList widget
# to indicate the eventual size of the column.
sub MoveColumnBar
{
	my $this = shift;

	my $hlist = $this->parent;
	my $height = $hlist->height() - $this->height();
	my $x      = $hlist->pointerx() - $hlist->rootx() + 1; # +1 for move right into gap

	$this->{columnBar}->place(
		'-x'      => $x,
		'-height' => $height - 5,
		'-y'      => $this->height() + 5,
	) unless $this->cget('-lastcolumn');
}
# REMOVES IT FROM DISPLAY without destroying it
sub HideColumnBar
{
	my $this = shift;
	$this->{columnBar}->placeForget();
}

########################################################################
1;
__END__


=head1 NAME

Tk::HdrResizeButton - provides a resizeable button for a HList column header.

=head1 SYNOPSIS

    use Tk;
    use Tk::HList;
    use Tk::HdrResizeButton;

    my $mw = MainWindow->new();

    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('HList',
         -columns=>2, 
         -header => 1
         )->pack(-side => 'left', -expand => 'yes', -fill => 'both');

    # CREATE COLUMN HEADER 0
    my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);
    my $header0 = $hlist->HdrResizeButton( 
          -text => 'Test Name', 
          -relief => 'flat', -pady => 0, 
          -command => sub { print "Hello, world!\n";}, 
          -column => 0
    );
    $hlist->header('create', 0, 
          -itemtype => 'window',
          -widget => $header0, 
          -style=>$headerstyle
    );

    # CREATE COLUMN HEADER 1
    my $header1 = $hlist->HdrResizeButton( 
          -text => 'Status', 
          -command => sub { print "Hello, world!\n";}, 
          -column => 1
    );
    $hlist->header('create', 1,
          -itemtype => 'window',
          -widget   => $header1, 
          -style    => $headerstyle
    );

=head1 DESCRIPTION

The HdrResizeButton widget provides a resizeable button widget for use
in an HList column header.  When placed in the column header, the right
edge of the widget can be selected and dragged to a new location to
change the size of the HList column.  When resizing the column, a 
column bar will also be placed over the HList indicating the eventual
size of the HList column.  A command can also be bound to the button
to do things like sorting the column.
On DoubleClicking a Column it is closed / re-opened. A Right-ButtonClick
will resize the column to the fit the needs of all the column contents. 

The widget takes all the options that a standard Button does.
Note: For a proper operationthe following option MUST be specified during creation:

=over 4

=item B<-column>

The column number that this HdrResizeButton is associated with.
(It has to be provided to resize the appropriate column).

=back

In addition, the following options may be specified:

=over 4

=item B<-command>

The default command is associated with an open/close function for the selected
column. The function is called with a Tk::HdrResizeButton reference for custom usage.

=item B<-activebackground>

The background color used for the column Header during active state (Mouse over Header).

=item B<-activeforeground>

The foreground color used for the column Header during active state (Mouse over Header).

=item B<-buttondownrelief>

The relief used for the column Header Button during selected state (Button pressed).

=item B<-minwidth>

The minwidth is used for the specific column (during resize), default: 30.

=item B<-closedminwidth>

The closedminwidth is used for the specific column (while in "CLOSED" view), default: 10.

=item B<-resizerwidth>

The resizerwidth is the resize sensor-area on the right border of the specific column, default: 1.


=back

=head1 AUTHOR

B<Shaun Wandler> <wandler@unixmail.compaq.com>


=head1 UPDATES

Updated by Slaven Rezic and Frank Herrmann,
Enhanced/Modified by Michael Krause KrauseM_AT_gmx_DOT_net

=over 4

=item DONE (MK) position columnbar correctly and only use MoveColumnBar to move it instead
	of destroying it and re-creating with CreateColumnBar

=item (???) use Subwidget('scrolled') if it exists

=item DONE (MK) don't give error if -command is not specified

=item DONE (MK) don't let the user hide columns (minwidth?)

=item DONE (MK) * double-click on column should not more execute the single-click command callback

=back

=head1 KEYWORDS

Tk::HList

=cut

###
### EOF
###
