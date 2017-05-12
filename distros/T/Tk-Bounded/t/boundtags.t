# -*- mode: perl; fill-column: 80; comment-column: 80; -*-

# boundtags.t --
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
use Tk::widgets qw/Label Entry/;

BEGIN {
    if (!eval q{
        use Test::More tests => 6;
        1;
    }) {
        print "# tests only work with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }

    use_ok( qw/Tkboundtags/ );
}

my $title;
my $err;
my $mw;
my $w;
my $here;

#-------------------------------------------------------------------------------
# Syntax
#-------------------------------------------------------------------------------

$title = 'Syntax - Two arrays references requested (1/2).';

{
  local $^W = 0;
  eval "sub Tk::Error { die \$_[1] }";
}

$mw = Tk::MainWindow -> new;
$w = $mw -> Label;
eval {
  $w -> boundtags( 't', 'l' );
};

like( $@, qr/invalid argument type/, $title );
$mw -> destroy;

#-------------------------------------------------------------------------------

$title = 'Syntax - Two arrays references requested (2/2).';
{
  local $^W = 0;
  eval "sub Tk::Error { die \$_[1] }";
};

$mw = Tk::MainWindow -> new;
$w = $mw -> Label;
eval {
  $w -> boundtags( [ 1 ], 1 );
};

like( $@, qr/invalid argument type/, $title );
$mw -> destroy;

#-------------------------------------------------------------------------------
# Associate bound tags.
#-------------------------------------------------------------------------------

$title = 'Associate bound tags.';

$here = 0;
{
  package Tk::bEntry_1;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;
  use Tkboundtags;

  Construct Tk::Widget 'bEntry_1';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP );
  }

  sub SetBindtags {
    my ($obj) = @_;

    $obj -> boundtags( [ ref $obj ], [ 1 ] );
  }

  sub SetCursor {
    $here = 1;
  }
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_1;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

is( $here, 1, $title );


#-------------------------------------------------------------------------------
# Out of bound level
#-------------------------------------------------------------------------------

$title = 'Out of bound level.';

$here = 0;
{
  package Tk::bEntry_2;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_2';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>', nP, sub { $here++ } );
    $mw -> bound( $class, '<Left>', np, sub { $here++ } );
  }

  sub SetBindtags {
    my ($obj) = @_;

    $obj -> boundtags( [ ref $obj ], [ 2 ] );
  }

}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_2;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;
is( $here, 2, $title );

#-------------------------------------------------------------------------------
# Retreive bound tags
#-------------------------------------------------------------------------------

$title = 'Retreive bound tags.';

$here = 0;
{
  package Tk::bEntry_3;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_3';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>', nP, sub { $here++ } );
  }

  sub SetBindtags {
    my ($obj) = @_;

    $obj -> boundtags( [ ref $obj ], [ 1 ] );
  }
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_3;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

is_deeply( [ $w -> boundtags ], [ [ ref $w ], [ 1 ] ], $title );

$mw -> destroy;


#__END__
