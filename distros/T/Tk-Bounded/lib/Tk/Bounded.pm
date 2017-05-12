# -*-mode: perl; fill-column: 80; comment-column: 80; -*-

# Tk::Bounded --
#
#	This file provides out of bounds mechanics.
#
# Copyright (c) 2000-2007 Meccanomania
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# svn: @(#) $Id: Bounded.pm 58 2008-01-10 23:29:20Z meccanomania $
#-------------------------------------------------------------------------------

package Tk::Bounded;

# Import bound and boundtags for caller.
use Tkbound;
use Tkboundtags;

$VERSION = '$Revision: 58 $' =~ /\D(\d+)\s*\$$/;

use attributes;
use Carp;
use base qw/Tk::Derived/;
use Tk qw/Ev lsearch/;

# Deriving from Tk::Derived class is not well documented.

# We need a Populate function in order to add some config specs, but derived
# base class (as not derived from the widget class) cannot handle it. Workaround
# it by calling the Populate function in the package that use it. To do so, add
# a _super wrapper function into user's class namespace, that, in turn calls the
# bounded class Populate function.
# [Delegate ?]
#
# On the other hand, ConfigSpec function is defined in derived class, and we can
# call it a as regular Tk derived class does.

sub Populate {
  my( $self, $args ) = @_;

  $self -> _callbase( 'Populate', $args );
}

# [ import function is called on module use. Here, its role is to assign
#   _boundbase hidden function to the namespace of it package caller to a given
#   source text take as is. So, _boundbase is defined a as regular function of
#   the given package.
#
#   Remember that a a clause such as 'use Tk::Bounded( qw/Tk::Entry/ ) yields the
#   parameter referred to by $module to Tk::Bounded and next parameter referred to
#   by $base to Tk::Entry.
#   ]

sub import {
  no strict 'refs';
  my( $module, $base ) = @_;

  # Add _super hidden function into caller's namespace.
  my $pkg = caller;

  *{"${pkg}::_super"} = sub { $base };
}

# _callbase hidden function role is to wrap a given routine into the _super
# hidden function defined on module loading.

sub _callbase {
  my( $w, $sub ) = ( shift, shift );

  my $supersub = $w ->_super."::$sub";

  $w -> $supersub( @_ );
}

#-------------------------

# SetBindtags is oververwritten in order to specify bounding for level 1.

sub SetBindtags {
 my ($obj) = @_;

 $obj -> boundtags( [ ref $obj, $obj, $obj -> toplevel, 'all' ],
		    [ 1 ] );
}

#-------------------------------------------------------------------------------

1;

__END__

=cut
