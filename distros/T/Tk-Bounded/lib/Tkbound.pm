# -*- mode: perl; fill-column: 80; comment-column: 80; -*-

# Tkbound --
#
#	This file provides out of bounds mechanics.
#
# Copyright (c) 2000-2007 Meccanomania
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# svn: @(#) $Id: Tkbound.pm 56 2008-01-10 23:23:59Z meccanomania $
#-------------------------------------------------------------------------------

package Tkbound;

$VERSION = '$Revision: 56 $' =~ /\D(\d+)\s*\$$/;

use Tk qw/Ev/;
use Tk::ErrorDialog;
use attributes qw/reftype/;

use base Exporter;

use strict;

#-------------------------------------------------------------------------------

# Wrap bound into Tk package.

*Tk::bound = \&bound;
*Tk::normalize_event = \&normalize_event;

# Create a bound event structure. Bless single argument (references and
# scalars), and leave to Ev other structures.

push @Tk::EXPORT, 'bEv';	# Force bEv export by Tk
*Tk::bEv =  sub {
  if (@_ == 1) {
    my $arg = $_[0];
    return bless (((ref $arg) ? $arg : \$arg), 'Tk::bEv');
  }

  return bless [@_],'Tk::Ev';
};

# Create localized variables into Tk package.
our $bevent;
our $bwidget;

*Tk::bwidget = *bwidget;
*Tk::bevent = *bevent;

# Create a bound event function into the Tk::Widget package.
*Tk::Widget::bXEvent = sub { bless \shift, 'Tkbound::bXEvent' };

#-------------------------------------------------------------------------------

# Masks for description of out of bounds bloc.

my $enum_MASK = 0;
use constant {
  enter_MASK =>		1 << $enum_MASK++,
  before_MASK =>	1 << $enum_MASK++,
  previous_MASK =>	1 << $enum_MASK++,
  after_MASK =>		1 << $enum_MASK++,
  leave_MASK =>		1 << $enum_MASK++,
};

# Mask combinations for bloc description.

use constant {
						# next before previous
  np => enter_MASK | before_MASK | previous_MASK | leave_MASK,
  nP => enter_MASK | before_MASK | leave_MASK,	# next before without previous
  Np => enter_MASK | previous_MASK | leave_MASK,# previous only
  NP => enter_MASK | leave_MASK,		# void

						# previous before next
  pn => enter_MASK | previous_MASK | after_MASK | leave_MASK,
  pN => enter_MASK | previous_MASK | leave_MASK,# previous before without next
  Pn => enter_MASK | after_MASK | leave_MASK,	# next only
  PN => enter_MASK | leave_MASK,		# void
};

use constant MASKS => qw/np nP Np NP pn pN Pn PN/;
use constant MASKS_VALUES => ( np, nP, Np, NP, pn, pN, Pn, PN );

use constant DEFAULT_BLOC => Np;	# Set default bloc to previous.
use constant NEXT_MASK => before_MASK | after_MASK;	# next mask
use constant BOUND_MASK => enter_MASK | leave_MASK;	# bound mask

{
  no strict;
  @EXPORT      = MASKS;
  %EXPORT_TAGS = ( bound_mask => [ MASKS ] );
}

#-------------------------------------------------------------------------------

# _boundarray, _boundarray_all --

# For each (tag, sequence), associate its outs out bounds level and current
# mask. Level stores the out of bounds current deep. Mask stores the current out
# of bounds configuration.

sub _boundarray {
  my( $toplevel, $tag, $sequence ) = @_;
  my $h = $toplevel -> TkHash( __PACKAGE__ );
  my $key = "$tag,$sequence";
  $h -> {$key} = [] unless exists $h -> {$key};
  return $h -> {$key};
}

sub _boundarray_all {
  my( $toplevel ) = @_;

  return map { split(/,/,$_) } (keys %{ $toplevel -> TkHash( __PACKAGE__ ) });
}

#-------------------------------------------------------------------------------

# _expand_bEv --

# Given a command and an event, produce a new command by replacing % constructs
# in the original command with information from the X event.

sub _expand_bEv {
  my( $bound_event, $script ) = @_;

  return $script unless( ref $script );

  return $script unless( reftype $script eq 'ARRAY' );

  return [ map { ref $_ eq 'Tk::bEv' && exists $bound_event -> { $$_ } ?
		   $bound_event -> { $$_ } : $_
		 } (@$script) ];
}

#-------------------------------------------------------------------------------
# _enter_wrapper

# This function is called to open the bloc profile.

sub _enter_wrapper {
  my( $widget, $tag, $string, $sequence, $level, $oob, $script, @values ) = @_;

  $widget -> Error( "$oob: unexpected bound mask" )
    unless( grep /$oob/, MASKS_VALUES );

  # Can't set before and after together.
  $widget -> Error( "panic: unexpected before and after change together" )
    if( ($oob & NEXT_MASK) == NEXT_MASK );

  # Get info.
  my $info = _boundarray( $widget -> toplevel, $tag, $sequence );
  my $sz = @$info;

  # Check enter level.
  $widget -> Error( "panic: unexpected enter level $level" )
    if( $sz == 0 || ! (0 < $level && $level < $sz) );

  # Compute event changes.
  my $changes = $oob ^ $info -> [ $level ] -> { mask };

  # Enter and leave mask change is not expected !
  $widget -> Error( 'panic: unexpected mask change' )
    if( ($changes & BOUND_MASK) == BOUND_MASK );

  # Set event values if out of bounds.
  my $bound_event;
  if( $oob & NEXT_MASK ) {
    $bound_event = { t => $tag,
		     s => $string,
		     S => $sequence,
		     m => $oob,
		     c => bless [ @values ], 'Tk::Callback' };
    $widget -> { _bXEvent_ } = $bound_event;
    *bwidget = \$widget;
    $bevent = bless \$widget, 'Tkbound::bXEvent';
  }

  # No event if no change.
  return unless( $changes );

  # Update mask and bound events.
  $info -> [ $level ] -> { mask } = $oob;

  # Expand bound events :
  #	* If script given, expand bEv events;
  #	* If no script given, reuse previous callback.
  #	* Otherwise, set to no operation.
  $script = ($oob & NEXT_MASK) ?
	     ($script ? _expand_bEv( $bound_event, $script ) : \@values) :
	     'NoOp';

  # Update bloc bindings. For the before and after tags, set to new callback.
  # For the previous tag, reset by binding to NoOp all levels from 1 to current
  # level minus 1, so that nothing can happen; reset also mask; set by
  # positionning again the enter at current level minus 1, so that other levels
  # are restored if necessary.

  my $before = sprintf( "before%d#%s", $level, $tag );
  my $after = sprintf( "after%d#%s", $level, $tag );
  $widget -> bind( $before, $sequence, $script ) if( $changes & before_MASK );
  $widget -> bind( $after, $sequence, $script ) if( $changes & after_MASK );

  if( $changes & previous_MASK ) {
    if( ($oob & previous_MASK) != previous_MASK ) {
      for( my $l = $level - 1; $l > 0; --$l ) {
	my $E = sprintf( "enter%d#%s", $l, $tag );
	my $b = sprintf( "before%d#%s", $l, $tag );
	my $a = sprintf( "after%d#%s", $l, $tag );
	my $L = sprintf( "leave%d#%s", $l, $tag );
	$info -> [ $l ] -> { mask } = DEFAULT_BLOC;
	$widget -> bind( $E, $sequence, 'NoOp' );
	$widget -> bind( $b, $sequence, 'NoOp' );
	$widget -> bind( $a, $sequence, 'NoOp' );
	$widget -> bind( $L, $sequence, 'NoOp' );
      }
      $widget -> bind( $tag, $sequence, 'NoOp' );
    } else {
      if( $level > 1 ) {
	my $pv = $info -> [ $level - 1 ] -> { cb };
	my $A = sprintf( "enter%d#%s", $level - 1, $tag );
	$widget -> bind( $A, $sequence, $pv );
      } else {
	my $pv = $info -> [ 1 ] -> { cb };
	$widget -> bind( $tag, $sequence, $pv );
      }
    }
  }
}

#-------------------------------------------------------------------------------
# _leave_wrapper

# This function is called to close the bloc profile.

sub _leave_wrapper {
  my( $widget ) = @_;

  $widget -> { _bXEvent_ } = undef;
  *bwidget = \undef;
  $bevent = undef;
}

#-------------------------------------------------------------------------------
#  normalize_event --

# Use bind to ckeck if there is a binding, and the event string syntax; use
# virtual event to force event string normalisation.

sub normalize_event {
  my( $widget, $string ) = @_;

  # Assume no '<<bound>>' event.
  $widget -> eventAdd( '<<bound>>', $string );
  my $sequence = $widget -> eventInfo( '<<bound>>' ) -> [ 0 ];
  $widget -> eventDelete( '<<bound>>', $string );

  return $sequence;
}

#-------------------------------------------------------------------------------
#  _create_bounding --

# In order to make Ev sequences evaluate correcty, the binding table
# properties are used to set up the out of bounds mechanism.

# A tag in the binding table is set up for out of bounds into a bloc of tags as
# follows :
#
#	enter	before	previous	after	leave
#	
#	* enter is first placed into the binding table to receive control in
#	a callback that takes the sequence, the out of bounds flags, the values
#	evaluated for tag, for future use. The whole bloc is controlled
#	by the out of bounds flag.
#
#	* before and after tags are placed around the previous tag. One of each
#	is activated following the bounds flag, the other left to NoOp.
#
#	* previous tag is the original tag. It can be also left to NoOp if not
#	called.
#
#	* leave tag terminates the bloc

# Blocs can also be surrounded around other such blocs, in which case the
# original tag plays the role of the whole bloc enter. Blocs are then indexed
# by their level. Level 0 is original callback; level is 1 for thirst bound
# binding, and so on.

sub _create_bounding {
  my( $widget, $tag, $string, $oob, $script ) = @_;

  # Warning : widget does not refer to the widget that will receive the actual
  # callback; it could be any widget. The actual widget is linked to tag, for
  # which legal values beginning by a dot (such as .entry or .), in addition to
  # special tags such as Entry for class and all for any widget are known to tcl
  # version of tk. perl itself handles special tags (such as Tk::Entry) for
  # class.

  # Look for previous callback. After initialisation, the bindings yields to no
  # boundings : level to 0, enter to tag.  There is not way out of bind to
  # check wether the event string is handled. On first level, catch any error
  # thrown by bind, and assign a new boundtag element. For other levels, there
  # is a binding for enter that was previously set up; catching is thus
  # unecessary.

  # Get the actual event string.
  my $sequence = normalize_event( $widget, $string );

  my $original_cb = $widget -> bind( $tag, $sequence );
  my $previous_cb;

  my $info = _boundarray( $widget -> toplevel, $tag, $sequence );
  my $level = scalar @$info;

  if( $level == 0 ) {
    # At level 0, if no callback, no bounding is possible.
    # [ bounding is binding !]
    $widget -> Error( "no previous callback" )
      unless $previous_cb = $original_cb;

    $info -> [ 0 ] = { mask => undef, cb => undef };
    $level++;

  } else {
    # If original callback has been deleted, all boundings should be deleted
    # too, from level 1 to current level.
    $widget -> Error( "panic: unexpected original callback deletion" )
      unless( $original_cb );

    my $enter = sprintf( "enter%d#%s", $level - 1, $tag );
    $previous_cb = $widget -> bind( $enter, $sequence );

    # Previous callback cannot be deleted directly.
    $widget -> Error( "panic: unexpected previous callback deletion" )
      unless( $previous_cb );
  }

  # Set up block enter so that regular callbacks can be evaluated for out of
  # bounds.
  my @ev_oob;
  if( ref $oob ) {
    if( ref $oob eq 'CODE' ) {
      @ev_oob = ([ $oob ]);
    } elsif( ref $oob eq 'ARRAY' ) {
      @ev_oob = @$oob;
    } else {
      $widget -> Error( "Invalid out of bounds\n" );
    }
  } else {
    $widget -> Error( "$oob: unexpected bound mask" )
      unless( grep /$oob/, MASKS_VALUES );

    @ev_oob = ([ sub { $oob } ]);
  }

  # Make new bound tags from bound level, tag and sequence.
  $info -> [ $level ] = { mask => DEFAULT_BLOC, cb => $previous_cb };

  my $enter = sprintf( "enter%d#%s", $level, $tag );
  my $before = sprintf( "before%d#%s", $level, $tag );
  my $after = sprintf( "after%d#%s", $level, $tag );
  my $leave = sprintf( "leave%d#%s", $level, $tag );

  # Make wrapper evaluate arguments of previous callback in its context, for
  # future use.
  my @values = ref $previous_cb && reftype $previous_cb eq 'ARRAY' ?
    @$previous_cb : ($$previous_cb);

  # Set up bloc bindings.
  my $ew = [ \&_enter_wrapper,
	     $tag,
	     $string,
	     $sequence,
	     $level,
	     Ev(@ev_oob),
	     $script,
	     @values ];
  my $lw = \&_leave_wrapper;
  $widget -> bind( $enter, $sequence, $ew );
  $widget -> bind( $before, $sequence, 'NoOp' );
  $widget -> bind( $after, $sequence, 'NoOp' );
  $widget -> bind( $leave, $sequence, $lw );
}

#-------------------------------------------------------------------------------
#  _delete_bounding --
#
# Remove an event binding from a binding table.

sub _delete_bounding {
  my( $widget, $tag, $string ) = @_;

  my $sequence = normalize_event( $widget, $string );

  my $info = _boundarray( $widget -> toplevel, $tag, $sequence );
  my $level = scalar @$info;

  return unless( $level );

  # Delete data relative to level.
  delete $info -> [ --$level ];

  # Delete tags and bindings accordingly.
  my $enter = sprintf( "enter%d#%s", $level, $tag );
  my $before = sprintf( "before%d#%s", $level, $tag );
  my $after = sprintf( "after%d#%s", $level, $tag );
  my $leave = sprintf( "leave%d#%s", $level, $tag );

  $widget -> bind( $enter, $sequence, undef );
  $widget -> bind( $before, $sequence, undef );
  $widget -> bind( $after, $sequence, undef );
  $widget -> bind( $leave, $sequence, undef );

  # Delete all.
  delete $info -> [ 0 ] if( $level == 1 );
}

#-------------------------------------------------------------------------------
#  _get_bounding --
#
# Return the command associated with a given event string.

sub _get_bounding {
  my( $widget, $tag, $string ) = @_;

  # Get the actual event string.
  my $sequence = normalize_event( $widget, $string );

  my $info = _boundarray( $widget -> toplevel, $tag, $sequence );
  my $level = scalar @$info;

  return unless( $level );

  # return $widget -> bind( $tag, $string );
  return $info -> [ 1 ] -> { cb };
}

#-------------------------------------------------------------------------------
#  _get_all_boundings --
#
# Return a list of event strings for all the boundings associated with a given
# object.

sub _get_all_boundings {
  my( $widget, $tag ) = @_;

  my $i = 0;
  my $t;
  return grep {
    my $r;
    SWITCH : {
      ( $i % 2 == 0 ) && do {
	# Save tag
	$t = $_;
	$r = undef;
	last;
      };
      ( $t eq $tag ) && do {
	# Keep $_ for tag
	$t = undef;
	$r = 1;
	last;
      };
      {
	$r = undef;
	last;	
      };
    }

    ++$i;
    $r;
  } _boundarray_all( $widget -> toplevel );
}

#-------------------------------------------------------------------------------
# bound --

#   The bound command is handled specially, it must *always* be called
#   with a widget object. And only the <> form of sequence is allowed
#   so that the following forms of call can be spotted:

#   $widget->bound();
#   $widget->bound('tag');
#   $widget->bound('<...>');
#   $widget->bound('tag','<...>');
#   $widget->bound('<...>',oob);
#   $widget->bound('<...>',oob,script);
#   $widget->bound('tag','<...>',oob);
#   $widget->bound('tag','<...>',oob,script);

sub bound {
  # bound is *always* be called with a widget object.
  my $widget = $_[0];
  $widget -> Error( "$widget is not a widget" )
    unless( ref $widget && $widget -> IsWidget );

  if( @_ < 2 || @_ > 5 ) {
    $widget -> Error( "wrong number of arguments bound ?pattern? ?oob ?script??");
    return;
  }


  # Normalise arguments to
  # $widget -> bound( $tag, $event, $oob, $script );
  my $string = $_[1];

  # Evaluate path name if event given.
  if( substr( $string, 0, 1 ) eq '<' ) {
    $string = $widget -> PathName;
    splice @_, 1, 0, $string;
  }

  # If there are four or five arguments, the command is modifying a
  # bounding.  If there are three arguments, the command is querying a bounding.
  # If there are only two arguments, the command is querying all the boundings
  # for the given tag/window.

  if( @_ > 3 ) {
    my( $sequence, $oob, $script ) = @_[2 .. 4];

    # If the oob is null, just delete the bounding.
    return _delete_bounding( $widget, $string, $sequence )
      unless( $oob );

    # Otherwise, create the bounding.
    return _create_bounding( $widget, $string, $sequence, $oob, $script );
  }

  # Get the bounding.
  return _get_bounding( $widget, $string, $_[2] ) if( @_ == 3 );

  # Get all boundings.
  return _get_all_boundings( $widget, $string );
}

#-------------------------------------------------------------------------------

package Tkbound::bXEvent;

use vars qw/$AUTOLOAD/;

sub DESTROY { }

sub AUTOLOAD {
  my $meth = ( $AUTOLOAD =~ /(\w)$/ )[ 0 ];

  no strict 'refs';
  *{ $AUTOLOAD } = sub {
    my $bevent = shift;
    $$bevent -> { _bXEvent_ } -> { $meth };
  };

  goto &$AUTOLOAD;
}



1;

__END__

=cut
