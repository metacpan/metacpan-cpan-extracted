######################################## SOH ###########################################
## Function : Additional Tk Class for Listbox-type HList with Data per Item, Sorting
##
## Copyright (c) 2004 - 2009 Michael Krause. All rights reserved.
## Special Thanks to B<Shaun Wandler> <wandler@unixmail.compaq.com>, whose
## Tk::HeaderResizeButton V1.3 has been used here.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
## 
## History  : V0.1	14-Jan-2004 	Class compound from HList, ResizeButton. MK
##            V0.2	20-Jan-2004 	Bugfix 'headerCreate' was not catched and %args->@args. MK
##            V0.3	14-Jul-2005 	Bugfix 'header Height' was not called correctly for TK 804.xx. MK
##            V0.4	13-Oct-2006 	Enhancement based on feedback from Rob Seegel. MK
##            V0.5	06-Apr-2009 	Enhancement based on feedback from Kai Ludick (DblClick on Header always raised HBttn-Cmd-CB). MK
##            V0.6	07-Apr-2009 	Enhancement based on feedback from Kai Ludick (configurable closedcolWidth, ResizeWidth). MK
######################################## EOH ###########################################

##############################################
### Use
##############################################
use Tk::HList;
use Tk::ItemStyle;
use Tk qw(Ev);

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '0.6';

########################################################################
package Tk::HeaderResizeButton;
#########################################################################
# Tk::HeaderResizeButton
# NOTE: This is an improved version of the Tk::ResizeButton
# Summary:  This widget creates a button for use in an HList header which
#           provides methods for resizing a column. This was heavily 
#	    leveraged from Columns.pm by Damion Wilson.
# Author:   Shaun Wandler, Updated by Slaven Rezic and Frank Herrmann, Michael Krause
# Date:     2009/04/07
# Revision: 0.6
#########################################################################=
# Note: For space reason all other documentation of Tk::HeaderResizeButton has
# been removed See Tk::HeaderResizeButton-Pod for details.
#
use base qw(Tk::Derived Tk::Button);

Construct Tk::Widget 'HeaderResizeButton';

sub ClassInit {
    my ($class, $window) = @_;

    $class->SUPER::ClassInit($window);
	$window->bind($class, '<ButtonRelease-1>', 'ButtonRelease');
	$window->bind($class, '<ButtonPress-1>',   'ButtonPress');
	$window->bind($class, '<Motion>',          'ButtonOver');
	$window->bind($class, '<ButtonRelease-3>', 'ColumnFullSize');
	$window->bind($class, '<Double-1>',        'ButtonDouble1');
	# Override these ones too
	$window->bind($class, '<Enter>', 'BttnEnter' );
	$window->bind($class, '<Leave>', 'BttnLeave' );
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

# CALLED IF WE ENTER THE HEADER AREA
sub BttnEnter
{
	my $this = shift;
	#print "BttnEnter\n";
	$this->StateSalvation(1);
	$this->configure(-relief => $this->cget('-buttondownrelief')) if $this->{m_ButtonPress};

}
# CALLED IF WE LEAVE THE HEADER AREA
sub BttnLeave
{
	my $this = shift;
	#print "BttnLeave\n";
	$this->StateSalvation(-1);
	$this->configure(-relief => $this->{m_relief}) if $this->{m_relief};
}
# CALLED IF WE ENTER THE TRIM AREA
sub TrimEnter
{
	my $this = shift;
	if ($this->cget(-lastcolumn)) {
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
	my $column = $this->cget(-column);
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
	my ( $this, $p_Trim ) = @_;
	delete $this->{m_ButtonPress};
	$this->{m_EdgeSelected} = 0;
	$this->configure(-relief => $this->{m_relief});
	if ($this->{columnBar}) {
		$this->HideColumnBar();
	}

	if ($this->{m_X} >= 0) {
		my $l_NewWidth = ( $this->pointerx() - $this->rootx() );
		my $hlist = $this->parent;
		my $col   = $this->cget( -column );
		# Better resize to minimum than to do nothing
		$l_NewWidth = $this->cget(-minwidth) if ($l_NewWidth + 5) < $this->cget( -minwidth );
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
	$this->{m_LastEvent} = 'DoubleClick';
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
	) unless $this->cget(-lastcolumn);
}
# REMOVES IT FROM DISPLAY without destroying it
sub HideColumnBar
{
	my $this = shift;
	$this->{columnBar}->placeForget();
}

1;


# sub EnterFocus
# {
# 	print "reached EnterFocus of HList\n";
#  my $w  = shift;
#  	print "widget is >$w<\n";
# # return unless defined $w;
# # my $Ev = $w->XEvent;
# # my $d  = $Ev->d;
# # $w->Tk::focus() if ($d eq 'NotifyAncestor' ||  $d eq 'NotifyNonlinear' ||  $d eq 'NotifyInferior');
# 	
# }

########################################################################
package Tk::HListplus;

use base qw (Tk::Derived Tk::HList);

Construct Tk::Widget 'HListplus';

# needed to include also the aliased commands
use Tk::Submethods ( 'header'    => [qw(configure cget create delete exists size)] );


#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub CreateArgs
{
    my ($class, $this, $args) = @_;		

	# New for V0.4 auto-increase the Column-num by 1 to have a more Win32 behavior
	$args->{-columns}++ if $args->{-columns};

	return $class->SUPER::CreateArgs($this, $args);
}
sub Populate
{
    my ($this, $args) = @_;		

	my $data_background = delete $args->{-databackground};
	$data_background = $this->cget ('-background') unless defined $data_background;
	$this->{m_headerstyle} = delete $args->{-headerstyle} || $this->ItemStyle ('window', -padx => '0', -pady => '0', );

	#Invoke Superclass fill func
    $this->SUPER::Populate($args);
}

#---------------------------------------------
# OVERRIDE: new header function
#---------------------------------------------
sub header 
{
	# Parameters
	my ($this, $cmd, $column, @args) = @_;
	# Locals
	my (%args, %hlist_args, $key);
	#print "initial header args = >@_<\n" . "- " x 60 .  "\n";

	# Note that we process here only the create command
	if ($cmd eq 'create') {
		%args = @args;
	 	if (defined $args{-itemtype} and $args{-itemtype} eq 'resizebutton') {
			# Rip off all relevant options
			foreach $key (qw(-itemtype -widget -style -borderwidth -headerbackground -relief)) {
				$hlist_args{$key} = delete $args{$key} if defined $args{$key};
			}
			# Take over those that make sense
			$args{relief} = delete $hlist_args{relief} if $hlist_args{relief};
			$args{background} = delete $hlist_args{headerbackground} if $hlist_args{headerbackground};

			# Create a new Resize Button
			my $header = $this->HeaderResizeButton( 
					-column => $column,
					-lastcolumn => ($this->cget(-columns) == $column + 1),
					-highlightthickness => 0,
					%args,
    		);
			$header->bind('all','<Enter>','EnterFocus');
			
			# store it for later cget retrieval
			$this->{m_headerwidget}{$column} = $header;
			
			# Add options for parent class setup
			$hlist_args{-itemtype} = 'window';
			$hlist_args{-widget} = $header;
			$hlist_args{-style} = $this->{m_headerstyle} unless $hlist_args{-style};

			# pass on as new args for parental class
			@args = %hlist_args;
		}
	}
	elsif ($cmd eq 'cget') {
		if ($args[0] eq '-widget') {
			return $this->{m_headerwidget}{$column};
		}
		# all other requests are processed the common way
	} 
	#print "cmd = >$cmd<, column = >$column<, Args is >@args< args: " . scalar(@_) . "<\n";

	# Install the 'normal view after we have something on the screen..
	if (defined $column) {
		return $this->SUPER::header($cmd, $column, @args);
	}
	else {
		return $this->SUPER::header($cmd);
	}
}

########################################################################
1;
__END__


=head1 NAME

Tk::HListplus - A HList that supports resizing, open & close of columns

=head1 SYNOPSIS

    use Tk;
    use Tk::HListplus;

    my $mw = MainWindow->new();


    # CREATE HEADER STYLE 1
    my $headerstyle1 = $mw->ItemStyle('window', -padx => 0, -pady => 0);

    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('HListplus',
         -columns=>3, 
         -header => 1,
		 -headerstyle => $headerstyle1,
    )->pack(-side => 'left', -expand => 'yes', -fill => 'both');

    # CREATE HEADER STYLE 2
    my $headerstyle = $hlist->ItemStyle('window', -padx => 0, -pady => 0);

    $hlist->header('create', 0, 
          -itemtype => 'resizebutton',
          -style => $headerstyle,
          -text => 'Test Name', 
		  -activeforeground => 'red',
    );
    $hlist->header('create', 1, 
          -itemtype => 'resizebutton',
          -style => $headerstyle,
          -text => 'Status', 
          -activebackground => 'orange',
    );

    Tk::MainLoop;
	


=head1 DESCRIPTION

A HList derived widget that has resizable columns, based on Header-ResizeButtons.

=head1 METHODS

=over 4

=item B<headerCreate()>

The create command accepts a new, virtual itemtype 'resizebutton', which
will lead to a Header-button with a right-side located sensor for resizing.
All options suitable for Buttons apply.

In addition, the following options may be specified:

=item B<headerCget()>

This command allows with B<-widget> to retrieve the Headerbutton-Widget Reference.


=back

=head1 OPTIONS

=over 4

=item B<-command>

The default command is associated with an open/close function for the selected
column. The function is called with a Tk::HeaderResizeButton reference for custom usage.

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


=item B<-headerstyle>

An alternative Header style, which will be the default for all columns unless you specify
-style ... for a dedicated header-create() call column.

=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

Thanks for Tk::ResizeButton by B<Shaun Wandler> <wandler@unixmail.compaq.com>,
Slaven Rezic and Frank Herrmann.

This code may be distributed under the same conditions as Perl.

V0.4  (C) October 2006

=cut

###
### EOF
###

