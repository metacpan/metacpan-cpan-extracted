# -*- mode: perl; fill-column: 80; comment-column: 80; -*-

# bound.t --
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
        use Test::More tests => 15;
        1;
    }) {
        print "# tests only work with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }

    use_ok( qw/Tkbound :bound_mask/ );
}

my $err;
my $here;
my $title;
my $mw;
my $w;
my $class;
my( $tag, $btag );
my $bev_widget;
my $bev_mask;
my $bev_tag;
my $bev_sequence;
my $bev_Sequence;
my $bev_callback;


#-------------------------------------------------------------------------------
# Check syntax
#-------------------------------------------------------------------------------

$title = 'Syntax - Event syntax.';
$err = undef;

$mw = Tk::MainWindow -> new();
$w = $mw -> Label;

eval {
  $w -> bound( '<Yyy>', NP );
};
like( $@, qr/bad event type or keysym/, $title );
$mw -> destroy;

#-------------------------------------------------------------------------------

$title = 'Syntax - Previous callback requested.';
$err = undef;
{
  local $^W = 0;
  eval "sub Tk::Error { die \$_[1] }";
};
$mw = Tk::MainWindow -> new();
$w = $mw -> Label;
eval {
  $w -> bound( '<Up>', NP );
};
like( $@, qr/no previous callback/, $title );
$mw -> destroy;

#-------------------------------------------------------------------------------

$title = 'Syntax - Unexpected bound mask - as a value.';
$err = undef;
{
  no warnings;
  *Tk::Error = sub {
    my( $w, $error, @msgs ) = @_;
    $err = $_[1];
  };
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> Entry;

$class = ref $w;
$tag = "enter1#$class";

$w -> bindtags( [ $tag ] );
$w -> bound( $class, '<Left>', 99 );

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

like( $err, qr/unexpected bound mask/, $title );


#-------------------------------------------------------------------------------

$title = 'Syntax - Unexpected bound mask - as a callback.';

$err = undef;
{
  no warnings;
  *Tk::Error = sub {
    $err = $_[1];
  };
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> Entry;

$class = ref $w;
$tag = "enter1#$class";

$w -> bindtags( [ $tag ] );
$w -> bound( $class, '<Left>', sub { 99 } );

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

like( $err, qr/unexpected bound mask/, $title );


#-------------------------------------------------------------------------------
# Associate boundings
#-------------------------------------------------------------------------------

$title = 'Associate boundings - previous callback called.';

$here = 0;

{
  package Tk::bEntry_1;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_1';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
  }

  sub SetCursor {
    $here = 1;
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
$w = $mw -> bEntry_1;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

is( $here, 1, $title );


#-------------------------------------------------------------------------------

$title = 'Associate boundings - user defined - without arguments - sub { }';

$here = 0;

{
  package Tk::bEntry_2;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_2';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP, sub { $here = 1 } );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
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
$w = $mw -> bEntry_2;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

is( $here, 1, $title );

#-------------------------------------------------------------------------------

$title = 'Associate boundings - user defined - without arguments - \'methodname\'.';

$here = 0;

{
  package Tk::bEntry_2b;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_2b';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>', nP, 'here' );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
  }

  sub here {
    $here = 1;
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
$w = $mw -> bEntry_2b;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

is( $here, 1, $title );

#-------------------------------------------------------------------------------
# Retreive boundings
#-------------------------------------------------------------------------------

$title = 'Retreive boundings - current bounding.';

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> Entry;

$class = ref $w;
$mw -> bound( $class, '<Left>',  nP, sub { $here = 1 } );

is( $mw -> bind( $class, '<Left>' ),
    $mw -> bound( $class, '<Left>' ), $title );

$mw -> destroy;

#-------------------------------------------------------------------------------

$title = 'Retreive boundings - all boundings.';

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> Entry;

$class = ref $w;
$mw -> bound( $class, '<Left>',  nP, sub { $here = 1 } );
$mw -> bound( $class, '<Right>',  nP, sub { $here = 1 } );

is( scalar $mw -> bound( $class ), 2, $title );

$mw -> destroy;


#-------------------------------------------------------------------------------
# Destroy bounding
#-------------------------------------------------------------------------------

$title = 'Destroy bounding.';

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> Entry;

$class = ref $w;
$mw -> bound( $class, '<Left>',  nP, sub { $here = 1 } );
$mw -> bound( $class, '<Left>', undef );

is( $mw -> bound( $class, '<Left>' ), undef, $title );

$mw -> destroy;

#-------------------------------------------------------------------------------
# Callback and substitutions.
#-------------------------------------------------------------------------------

$title = 'Callback and substitution - use &Tk::bEv.';

{
  package Tk::bEntry_3;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;
  use Tk qw/bEv/;

  Construct Tk::Widget 'bEntry_3';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP,
		  [ sub { ( undef, $bev_tag, $bev_sequence, $bev_Sequence,
			    $bev_callback, $bev_mask ) = @_ },
		    bEv('t'), bEv('s'),
		    bEv('S'), bEv('c'), bEv('m') ] );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
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

$mw -> destroy;

ok( eq_array( [ $bev_tag, $bev_sequence, $bev_Sequence, $bev_mask,
		$bev_callback -> [0] ],
	      [ ref $w, '<Left>', '<Key-Left>', nP,
		'SetCursor' ] ),
    $title );


#-------------------------------------------------------------------------------

$title = 'Callback and substitution - use $self -> bXevent.';

{
  package Tk::bEntry_4;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_4';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP, sub {
		    my $self = shift;
		    my $bev = $self -> bXEvent;
		    ( $bev_tag, $bev_sequence, $bev_Sequence,
		      $bev_callback, $bev_mask ) =
			( $bev -> t, $bev -> s, $bev -> S,
			  $bev -> c, $bev -> m );
		  }
		);
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
  }
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_4;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

ok( eq_array( [ $bev_tag, $bev_sequence, $bev_Sequence, $bev_mask,
		$bev_callback -> [0] ],
	      [ ref $w, '<Left>', '<Key-Left>', nP,
		'SetCursor' ] ),
    $title );

#-------------------------------------------------------------------------------

$title = 'Callback and substitution - use $Tk::bwidget and $Tk::bevent.';

{
  package Tk::bEntry_5;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_5';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>',  nP, 'NoOp' );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag = "enter1#$class";
    my $btag = "before1#$class";

    $obj -> bindtags( [ $tag, $btag ] );
  }
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_5;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;

my $bw = $Tk::bwidget;
my $bev = $Tk::bevent;
ok( eq_array( [ $bw,
		$bev -> t, $bev -> s, $bev -> S, $bev -> m,
		$bev -> c -> [0] ],
	      [ $w,
		ref $w, '<Left>', '<Key-Left>', nP,
		'SetCursor' ] ),
    $title );

#-------------------------------------------------------------------------------
# Out of bound level
#-------------------------------------------------------------------------------

$title = 'Out of bound level.';

$here = 0;
{
  package Tk::bEntry_6;

  use base qw/Tk::Derived Tk::Entry/;
  use Tkbound qw/:bound_mask/;

  Construct Tk::Widget 'bEntry_6';

  sub ClassInit {
    my( $class, $mw ) = @_;

    $class -> SUPER::ClassInit( $mw );

    $mw -> bound( $class, '<Left>', nP, sub { $here++ } );
    $mw -> bound( $class, '<Left>', np, sub { $here++ } );
  }

  sub SetBindtags {
    my ($obj) = @_;
    my $class = ref $obj;
    my $tag1 = "enter1#$class";
    my $btag1 = "before1#$class";
    my $tag2 = "enter2#$class";
    my $btag2 = "before2#$class";

    $obj -> bindtags( [ $tag1, $btag1, $tag2, $btag2 ] );
  }
}

$mw = Tk::MainWindow -> new;
$mw -> geometry( '+10+10' );
$w = $mw -> bEntry_6;

$w -> pack;
$w -> focus;
$mw -> update;

$w -> eventGenerate( '<Left>' );
$mw -> idletasks;

$mw -> destroy;
is( $here, 2, $title );


#__END__
