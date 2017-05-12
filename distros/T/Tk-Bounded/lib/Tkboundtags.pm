# -*- mode: perl; fill-column: 80; comment-column: 80; -*-

# Tkboundtags --
#
#	This file provides out of bounds mechanics.
#
# Copyright (c) 2000-2007 Meccanomania
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# svn: @(#) $Id: Tkboundtags.pm 56 2008-01-10 23:23:59Z meccanomania $
#-------------------------------------------------------------------------------

package Tkboundtags;

$VERSION = '$Revision: 56 $' =~ /\D(\d+)\s*\$$/;

use Tk::ErrorDialog;

#-------------------------------------------------------------------------------

# Wrap bound and bountags into Tk package.

*Tk::boundtags = \&boundtags;

#-------------------------------------------------------------------------------
# _get_boundtags --

sub _get_boundtags {
  my( $widget ) = @_;

  my @bindtags = $widget -> bindtags;

  my @taglist;
  my @levellist;

  for( my $bound_index = 0; $bound_index < @bindtags; $bound_index++ ) {
    next unless( my($level, $tag) = 
		 $bindtags[ $bound_index ] =~ /^enter(\d+)#(.*)$/ );
    push @taglist, $tag;
    push @levellist, $level;
  }

  return( [ @taglist ], [ @levellist ] );
}

#-------------------------------------------------------------------------------
# _set_boundtags --

sub _set_boundtags {
  my( $widget, $taglist, $levellist ) = @_;
  my @boundtags;

  # Reset bindtags if not found for a class tag. We get called from
  # SetBindtags for force overwrite of tcl tk defaults bindings into perl tk
  # default bindings in class derivation in mega or derived widget, in which
  # case level is 0.

  my $bindtag_index = 0;
  for( my $tag_index = 0; $tag_index < @$taglist; $tag_index++ ) {
    my $tag = $taglist -> [$tag_index];
    $tag = $tag -> PathName if( ref $tag && $tag -> IsWidget );

    # Find where to insert/delete, and level. If not found, this is insertion at
    # level 0.
    my $bound_index;
    my $d = 0;
    for( $bound_index = 0; $bound_index < @boundtags; $bound_index++ ) {
      last if(($d) = $boundtags[ $bound_index ] =~
	      /^(?:enter(\d+)#)?${tag}$/ );
    }

    # Bind the tag before bounding it.
    if( $bound_index == @boundtags ) {
      $bound_index = $bindtag_index;
      $boundtags[ $bound_index ] = $tag;
      $bindtag_index++;
    }

    next unless( my $level = $levellist -> [$tag_index] );

    # Increase/decrease level
    if( $d <= $level ) {
      for( ++$d; $d <= $level; $d++ ) {
	my $enter = sprintf( "enter%d#%s", $d, $tag );
	my $before = sprintf( "before%d#%s", $d, $tag );
	my $after = sprintf( "after%d#%s", $d, $tag );
	my $leave = sprintf( "leave%d#%s", $d, $tag );
	splice @boundtags, $bound_index, 0, $enter, $before;
	splice @boundtags, $bound_index + 4 * $d - 1, 0, $after, $leave;
      }
      $bindtag_index += 4 * $level;

    } else {
      for( ; $level < $d; --$d ) {
	splice @boundtags, $bound_index + 4 * $d - 1, 2;
	splice @boundtags, $bound_index, 2;
      }
    }
  }

  # Update binding table.
  $widget -> bindtags( \@boundtags );
}

#-------------------------------------------------------------------------------
# boundtags --
#
#      This procedure is invoked to process the "bindtags" Tcl command.
#      See the user documentation for details on what it does.

sub boundtags {
  my $widget = $_[0];
  $widget -> Error( "$widget is not a widget" )
    unless( $widget -> IsWidget );

  # Read bounding table.
  return _get_boundtags( $widget ) if( @_ == 1 );

  # Set bounding table.
  $widget -> Error( "wrong number of arguments" ) if( @_ != 3 );

  my( $taglist, $levellist ) = @_[ 1, 2 ];
  $widget -> Error( "invalid argument type" )
    unless( ref $taglist eq 'ARRAY' &&
	    ref $levellist eq 'ARRAY' );

  _set_boundtags( $widget, $taglist, $levellist );
}


#-------------------------------------------------------------------------------

1;

__END__

=cut
