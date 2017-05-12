# -*- mode: perl; fill-column: 80; comment-column: 80; -*-

# bounded.t --
#
#       This file provides out of bounds mechanics testing.
#
# Copyright (c) 2000-2007 Meccanomania
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# svn: @(#) $Id$
#-------------------------------------------------------------------------------

$VERSION = '$Revision$' =~ /\D(\d+)\s*\$$/;

use strict;

use Tk;
use Tk::Trace;

my $mw;
my $w;
my $here;
my $title;
my $err;

BEGIN {
  if (!eval q{
        use Test::More tests => 1;
        1;
    }) {
    print "# tests only work with installed Test::More module\n";
    print "1..1\n";
    print "ok 1\n";
    exit;
  }
}


#-------------------------------------------------------------------------------
# Create a bounded class.
#-------------------------------------------------------------------------------

$title = 'Create bounded class.';

$here = 0;

{
  package Tk::bBEntry_1;

  use Tk::Bounded qw/Tk::Entry/;
  use base qw/Tk::Bounded Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bBEntry_1';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>', nP, sub { $here = 1 } );
  }
}


{
  no warnings;
  *Tk::Error = sub {
    $err = $_[1];
  };
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bBEntry_1;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

is( $here, 1, $title );


#__END__
