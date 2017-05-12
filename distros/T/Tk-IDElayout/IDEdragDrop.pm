package Tk::IDEdragDrop;
require Tk::Toplevel;
require Tk::Label;
use Tk::IDEdragShadowToplevel;


our ($VERSION) = ('0.33');

use base  qw( Tk::DragDrop);

our($DEBUG);

=head1 NAME 

Tk::IDEdragDrop - Tk::DragDrop subclass for IDE Drag/Drop Behavoir

=head1 DESCRIPTION

This is a L<Tk::DragDrop> derived widget with some additional features:

=over 1

=item *

The widget responds to button-release events when dragged outside the Tk window.

For example, dragging a target outside the Tk window (e.g. onto the desktop) and releasing the mouse button
doesn't leave the the Drag-Drop token in limbo, like the parent class. 

This feature is needed for the IDE so that windows can be dragged outside the main window (onto the desktop)
and be reparented to a top-level window. (e.g. tabs from IDEtabFrame widget can be dragged to
the desktop to become top-level windows).

=back


=head1 SYNOPSIS

Usage is the same as normal Tk drag/drop usage, except when creating
the Drag-Drop Token, use:

 use Tk::IDEdragDrop;
 
 my $dragToken = $widget->IDEdragDrop( ... );

=cut

Construct Tk::Widget 'IDEdragDrop';

use strict;
use Carp;


# class data for the Top level drag shadow
#   Since there only needs to be one of these at a time, this is setup as class data, do we don't
#     have to recreate everytime something is dragged.

our ($dragShadowToplevel, $offsetX, $offsetY);  

# There is a snag with having a token window and moving to
# exactly where cursor is - the cursor is "inside" the token
# window - hence it is not "inside" the dropsite window
# so we offset X,Y by OFFSET pixels.
sub OFFSET () {3}

sub ClassInit
{
 my ($class,$mw) = @_;
 $mw->bind($class,'<Map>','Mapped');
 return $class;
}

	

# Create drag and drop events on the parent widget. 
#   This differs from 
#   Tk::DragDrop, which creates events on the Drag/Drop token itself, and
#   does a global graph ( $token->grabGlobal ) to funnel all events to it during
#   the drag. 
#   The Tk::DragDrop approach works Ok for most cases, but doesn't response to button-release
#     events when the token is dragged out of the Tk main window. (i.e. when dragged to the
#     desktop.) This case is needed for the IDE to create new top-level windows by dragging
#     to the desktop.
#   
sub event
{
 my ($w,$opt,$value) = @_;
 # delete old bindings
 #print "In Event, value = $value, opt = $opt\n";
 $w->parent->Tk::bind($value,[$w,'Drag']);
 $w->parent->Tk::bind('<B1-ButtonRelease>',[$w,'Drop']);
 #$mw->bind($class,'<Any-KeyPress>','Done');
}

sub Drop
{
 my $ewin  = shift;
 print "In Drop\n" if($DEBUG);
 my $e     = $ewin->parent->XEvent;
 my $token = $ewin->toplevel;
 my $site  = $ewin->FindSite($e->X,$e->Y,$e);
 if (defined $site)
  {
   my $seln = $token->cget('-selection');
   unless ($token->Callback(-predropcommand => $seln, $site))
    {
# XXX This is ugly if the user restarts a drag within the 2000 ms:
#     my $id = $token->after(2000,[$token,'Done']);
     my $w = $token->parent;
     $token->InstallHandlers;
     $site->Drop($token,$seln,$e);
     $token->Callback(-postdropcommand => $seln);
     $token->Done;
     #print "Hiding DragShowTopLevel after Drop\n";
     $token->DragShadowToplevelHide();
    }
  }
 else
  {
   $token->Done;
  }
 $token->Callback('-endcommand');
}
#


sub Mapped
{
 my ($token) = @_;
 #print "In Mapped\n";
 my $e = $token->parent->XEvent;
 $token = $token->toplevel;
 #$token->bind('<Any-ButtonRelease>',sub{ print "Token B1 release\n"});

 # We don't do a grabGlobal here, like is done for Tk::DragDrop
 #$token->grabGlobal; 
 #$token->focus;
 if (defined $e)
  {
   my $X = $e->X;
   my $Y = $e->Y;
   $token->MoveToplevelWindow($X+OFFSET,$Y+OFFSET);
   $token->NewDrag;
   $token->FindSite($X,$Y,$e);
  }
}


sub Drag
{
 my $token = shift;
 my $w     = $token->parent;
 if ($w->{'Dragging'}){
	 my $e = $token->parent->XEvent;
	 my $X  = $e->X;
	 my $Y  = $e->Y;
	 $token = $token->toplevel;
	 $token->MoveToplevelWindow($X+OFFSET,$Y+OFFSET);
	 
	 # Move the top level dragshadow, unless it is currently hidden
	 $dragShadowToplevel->MoveToplevelWindow($X+$offsetX,$Y+$offsetY) unless( $token->{DragShadowToplevelHide});
	 
	 $token->FindSite($X,$Y,$e);
	 $token->update;
 }
 else{
	 $token->StartDrag();
 }
}


# Sub to configure the DragShadowToplevel
#
#   Usage: 
#      $widget->DragShadowToplevelConfig($width, $height, $offsetX, $offsetY);
#        where
#             $width:  Width of widget
#             $height: Height of widget
#             $offsetX:  Offset between the upper left corner of the widget and where mouse pointer appears
#             $offsetY:  Offset between the upper left corner of the widget and where mouse pointer appears

sub DragShadowToplevelConfig{
	my $self = shift;
	my ($w, $h, $oX, $oY) = @_;
	
	# Set the offset class data
	$offsetX  = $oX;
	$offsetY  = $oY;
	
	my $pointerX = $self->pointerx;
	my $pointerY = $self->pointery;
	
	my $geometry = $w."x".$h."+".($pointerX+$oX)."+".($pointerY+$oY);
	
	# Create the toplevel widget, if not defined
	unless( defined($dragShadowToplevel) && $dragShadowToplevel->Exists()){
		$dragShadowToplevel = $self->toplevel->IDEdragShadowToplevel(-geometry => $geometry);
	}
	else{
		$dragShadowToplevel->configure(-geometry => $geometry);
	}
	$dragShadowToplevel->deiconify();
}
	
# Sub to hide the DragShadowToplevel, if defined
sub DragShadowToplevelHide{
	my $self = shift;
	
	if(defined($dragShadowToplevel)){
		$dragShadowToplevel->withdraw;
		$self->{DragShadowToplevelHide} = 1;
	}
}

# Sub to show the DragShadowToplevel,if it has been hidden
sub DragShadowToplevelShow{
	my $self = shift;
	if(defined($dragShadowToplevel) && $self->{DragShadowToplevelHide} ){
		$dragShadowToplevel->deiconify();
		$self->{DragShadowToplevelHide} = 0;
	}	
}

# Sub to get the current geometry of the dragShadowtoplevel
sub DragShadowToplevelGeometry{
	my $self = shift;
	if(defined($dragShadowToplevel) ){
		return $dragShadowToplevel->geometry();
	}
	print "DragShadowToplevel not defined\n";
	return undef;	
}

# DragShadowTopLevel accessor
#    Usage:
#       Setting              $self->dragShadowToplevel($value);
#       Getting  my $value = $self->dragShadowToplevel();
sub dragShadowToplevel{
	my $self = shift;
	my $value = shift;
	if( defined($value)){
		$dragShadowToplevel = $value;
	}
	return $dragShadowToplevel;
}

# offsetX accessor
#    Usage:
#       Setting              $self->offsetX($value);
#       Getting  my $value = $self->offsetX();
sub offsetX{
	my $self = shift;
	my $value = shift;
	if( defined($value)){
		$offsetX = $value;
	}
	return $offsetX;
}

# offsetY accessor
#    Usage:
#       Setting              $self->offsetY($value);
#       Getting  my $value = $self->offsetY();
sub offsetY{
	my $self = shift;
	my $value = shift;
	if( defined($value)){
		$offsetY = $value;
	}
	return $offsetY;
}

## Overridden findsite ####
#  This doesn't do anything unless we are dragging,
#   which keeps spurious site->overs from being called
#    (Especially is we are clicking on a tabframe tab right next
#    to the edge of an IDElayout frame)
sub FindSite
{
 my ($token,@args) = @_;
 my $w     = $token->parent;
 return undef unless ($w->{'Dragging'});
 
 $token->SUPER::FindSite(@args);
}



1;

