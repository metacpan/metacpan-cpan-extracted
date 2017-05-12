package Tk::MiniScale;

use Tk 800.022; # Minimum version containing Tk::Trace
use Tk::Scale;
use Tk::Trace;
use Carp;
use strict;

use base qw(Tk::Frame);
Construct Tk::Widget 'MiniScale';

$Tk::MiniScale::VERSION = '0.1';

use vars
  qw($SLIDERBITMAP_TOP $SLIDERBITMAP_BOTTOM $SLIDERBITMAP_LEFT  $SLIDERBITMAP_RIGHT );

$SLIDERBITMAP_TOP    = __PACKAGE__ . "::slidertop";
$SLIDERBITMAP_BOTTOM = __PACKAGE__ . "::sliderbottom";
$SLIDERBITMAP_LEFT   = __PACKAGE__ . "::sliderleft";
$SLIDERBITMAP_RIGHT  = __PACKAGE__ . "::sliderright";

my $def_bitmaps = 0;

# Constants for QueueLayout flags
sub _SliderSide () { 1 }     # May affect the orientation of the scale
sub _Orient ()     { 2 }     # Direct manipulation of the scale orientation
sub _From ()       { 4 }     # Switch if vertical scale
sub _To ()         { 8 }     # Switch if vertical scale
sub _Variable ()   { 16 }    # Configure the scale variable

sub ClassInit {
  my ( $class, $mw ) = @_;

  unless ($def_bitmaps) {

    my @rot_bits = (
      "........",
      ".1......",
      ".11.....",
      ".111....",
      ".1111...",
      ".11111..",
      ".111111.",
      ".1111111",
      ".111111.",
      ".11111..",
      ".1111...",
      ".111....",
      ".11.....",
      ".1......",
      "........"
    );
    my $rot_bits          = pack( "b8" x 15, @rot_bits );
    my $mirrored_rot_bits = pack( "b8" x 15, map { scalar reverse } @rot_bits );

    $mw->DefineBitmap( $SLIDERBITMAP_LEFT  => 8, 15, $rot_bits );
    $mw->DefineBitmap( $SLIDERBITMAP_RIGHT => 8, 15, $mirrored_rot_bits );

    my $bot_bits = pack(
      "b15" x 8,
      ".......1.......",
      "......111......",
      ".....11111.....",
      "....1111111....",
      "...111111111...",
      "..11111111111..",
      ".1111111111111.",
      "..............."
    );

    $mw->DefineBitmap( $SLIDERBITMAP_BOTTOM => 15, 8, $bot_bits );

    my $top_bits = pack(
      "b15" x 8,
      "...............",
      ".1111111111111.",
      "..11111111111..",
      "...111111111...",
      "....1111111....",
      ".....11111.....",
      "......111......",
      ".......1......."
    );

    $mw->DefineBitmap( $SLIDERBITMAP_TOP => 15, 8, $top_bits );

# If changing these bitmaps then ensure the the midpoint of the arrow is the same
# number of the short side of the bitmap (i.e. 8 in this case)
# then change the 'arrowmidpoint' variable (below) to that number
    $def_bitmaps = 1;
  }
  $class->SUPER::ClassInit($mw);
}

sub Populate {
  my ( $w, $args ) = @_;

  $w->SUPER::Populate($args);

  my $orient = $w->{'orient'}        = 'vertical';
  my $side   = $w->{'sliderside'}    = 'left';
  my $mp     = $w->{'arrowmidpoint'} = 8;
  my $off    = $w->{'offset'}        = $w->{'arrowmidpoint'} / 2;
  $w->{'watchvar'} = 0;

  my $c = $w->Canvas( -bd => 0, -highlightthickness => 0 )->pack;
  my $l = $c->createBitmap(
    0, 0,
    -anchor => 'nw',
    -bitmap => $SLIDERBITMAP_LEFT,
    -tags   => 'slider'
  );
  my $s = $c->Scale(
    -orient             => $orient,
    -from               => 100,
    -to                 => 0,
    -length             => 100,
    -showvalue          => 0,
    -sliderlength       => 0,
    -width              => 0,
    -sliderrelief       => 'flat',
    -bd                 => 1,
    -highlightthickness => 0,
  );
  $c->configure(
    -width  => $s->reqwidth + $mp + 1,
    -height => $s->reqheight + $mp
  );
  $c->createWindow(
    $mp + 1, $off,
    -window => $s,
    -anchor => 'nw',
    -tags   => 'scale'
  );

  $w->Advertise( 'canvas' => $c );
  $w->Advertise( 'scale'  => $s );
  $w->_setBindings;

  $w->ConfigSpecs(
    -variable   => [ 'METHOD', undef, undef, undef ],
    -sliderside => [ 'METHOD', undef, undef, $side ],
    -orient     => [ 'METHOD', undef, undef, $orient ],
    -from       => [ 'METHOD', undef, undef, 100 ],
    -to         => [ 'METHOD', undef, undef, 0 ],
    'DEFAULT'   => [$s],
  );
}    # end Populate

sub from {
  my ( $w, $v ) = @_;
  if ( @_ > 1 ) {
    $w->_configure( -from => $v );
    $w->QueueLayout(_From);
  }
  return $w->_cget('-from');
}

sub to {
  my ( $w, $v ) = @_;
  if ( @_ > 1 ) {
    $w->_configure( -to => $v );
    $w->QueueLayout(_To);
  }
  return $w->_cget('-to');
}

sub sliderside {
  my ( $w, $v ) = @_;
  if ( @_ > 1 ) {
    $w->_configure( -sliderside => $v );
    $w->QueueLayout(_SliderSide);
  }
  return $w->_cget('-sliderside');
}

sub orient {
  my ( $w, $v ) = @_;
  if ( @_ > 1 ) {
    $w->_configure( -orient => $v );
    $w->QueueLayout(_Orient);
  }
  return $w->_cget('-orient');
}

sub variable {
  my ( $w, $v ) = @_;
  if ( @_ > 1 ) {
    $w->_configure( -variable => $v );
    $w->QueueLayout(_Variable);
  }
  return $w->_cget('-variable');
}

sub QueueLayout {
  my ( $w, $why ) = @_;
  $w->afterIdle( [ 'Layout', $w ] ) unless ( $w->{LayoutPending} );
  $w->{'LayoutPending'} |= $why;
}

sub Layout {
  my ($w) = @_;
  return unless Tk::Exists($w);
  my $side   = $w->cget('-sliderside');
  my $orient = $w->cget('-orient');
  my $from   = $w->cget('-from');
  my $to     = $w->cget('-to');
  my $var    = $w->cget('-variable');
  my $why    = $w->{'LayoutPending'};
  $w->{'LayoutPending'} = 0;
  my $scale = $w->Subwidget('scale');

  if ( $why & _Variable ) {
    my $oldvar = $w->{'watchvar'};
    croak
      "Please define -variable as a reference to a Scalar"
      unless ( defined($var) and ref($var) eq 'SCALAR' );
    if ($oldvar) {
      $w->traceVdelete($oldvar);
    }

    $w->traceVariable( $var, 'w' => [ \&_update_slider, $w, $scale ] );
    $scale->configure( -variable => $var );
    $w->{'watchvar'} = $var;
  }
  if ( $why & ( _SliderSide | _Orient | _From | _To ) ) {

    if ( $orient =~ /^v/ ) {
      if ( $side =~ /^r/ ) {
        $w->_doSide('right');
      }
      else {
        $w->_doSide('left');
      }
      if ( $to < $from ) {
        $scale->configure( -from => $from, -to => $to );
      }
      else {
        $scale->configure( -from => $to, -to => $from );
      }
    }    #end if vertical
    elsif ( $orient =~ /^h/ ) {
      if ( $side =~ /^b/ ) {
        $w->_doSide('bottom');
      }
      else {
        $w->_doSide('top');
      }
      if ( $to < $from ) {
        $scale->configure( -from => $to, -to => $from );
      }
      else {
        $scale->configure( -from => $from, -to => $to );
      }
    }    #end if horizontal
  }

}

sub switchFromTo {
  my ($w)   = @_;
  my $scale = $w->Subwidget('scale');
  my $from  = $scale->cget('-from');
  my $to    = $scale->cget('-to');
  $scale->configure( -from => $to, -to => $from );
}

sub _setBindings {
  my ($w) = @_;

  my $c = $w->Subwidget('canvas');
  $c->Tk::bind( '<1>',         [ $w, '_doScale' ] );
  $c->Tk::bind( '<B1-Motion>', [ $w, '_doScale' ] );
}

sub _doSide {
  my ( $w, $side ) = @_;
  my $c = $w->Subwidget('canvas');
  if ( $side eq 'left' ) {
    $w->_orientScale('vertical');
    $w->_changeSlider($side);
  }
  elsif ( $side eq 'right' ) {
    $w->_orientScale('vertical');
    $w->_changeSlider($side);
  }
  elsif ( $side eq 'top' ) {
    $w->_orientScale('horizontal');
    $w->_changeSlider($side);
  }
  elsif ( $side eq 'bottom' ) {
    $w->_orientScale('horizontal');
    $w->_changeSlider($side);
  }
  else {
    carp "-sliderside must be one of top,bottom,left,right";
  }
}

sub _orientScale {
  my ( $w, $orient ) = @_;

  my $s  = $w->Subwidget('scale');
  my $c  = $w->Subwidget('canvas');
  my $mp = $w->{'arrowmidpoint'};

  if ( $orient eq 'vertical' ) {
    $s->configure( -orient => 'vertical' );
    $c->configure(
      -width  => $s->reqwidth + $mp + 1,
      -height => $s->reqheight + ( $mp * 2 )
    );
  }
  else {
    $s->configure( -orient => 'horizontal' );
    $c->configure(
      -width => $s->reqwidth + ( $mp * 2 ),
      -height => $s->reqheight + $mp + 1
    );
  }
  $w->switchFromTo;
  $w->{'orient'} = $orient;
}

sub _changeSlider {
  my ( $w, $side ) = @_;
  return if ( $side eq $w->{'sliderside'} );
  my $name = ref($w) . "::slider" . $side;
  my $c    = $w->Subwidget('canvas');
  $c->itemconfigure( 'slider', -bitmap => $name );
  $w->_locateSlider($side);
  $w->{'sliderside'} = $side;
}

sub _locateSlider {
  my ( $w, $side ) = @_;
  my $c     = $w->Subwidget('canvas');
  my $scale = $w->Subwidget('scale');
  my @bbox  = $c->bbox('scale');
  my $mp    = $w->{'arrowmidpoint'};
  my $off   = $w->{'offset'};
  my $value = $scale->get;
  my ( $x, $y ) = $scale->coords($value);

  #print "X: $x Y: $y\n";
  my $short = my $long = 0;

  if ( $w->{'orient'} eq 'vertical' ) {
    $short = $bbox[2] - $bbox[0];
    $long  = $bbox[3] - $bbox[1];
  }
  else {
    $short = $bbox[3] - $bbox[1];
    $long  = $bbox[2] - $bbox[0];
  }

  if ( $side eq 'left' ) {
    $c->coords( 'slider', 0, $y - $off + 1 );
    $c->coords( 'scale', $mp, $off );
  }
  elsif ( $side eq 'right' ) {
    $c->coords( 'scale', 0, $off );
    $c->coords( 'slider', $short + 1, $y - $off + 1 );
  }
  elsif ( $side eq 'top' ) {
    $c->coords( 'slider', $x - $off + 1, 0 );
    $c->coords( 'scale', $off, $mp );
  }
  elsif ( $side eq 'bottom' ) {
    $c->coords( 'scale', $off, 0 );
    $c->coords( 'slider', $x - $off + 1, $short + 1 );
  }
}

sub _getSliderPoint {
  my ($w)  = @_;
  my $c    = $w->Subwidget('canvas');
  my @bbox = $c->bbox('slider');
  if ( $w->{'orient'} eq 'vertical' ) {
    if ( $w->{'sliderside'} eq 'left' ) {
      return ( $bbox[2], $bbox[1] + int( ( $bbox[3] - $bbox[1] ) / 2 ) );
    }
    else {
      return ( $bbox[0], $bbox[1] + int( ( $bbox[3] - $bbox[1] ) / 2 ) );
    }
  }
  else {

    #horizontal
    if ( $w->{'sliderside'} eq 'top' ) {
      return ( $bbox[0] + int( ( $bbox[2] - $bbox[0] ) / 2 ), $bbox[3] );
    }
    else {
      return ( $bbox[0] + int( ( $bbox[2] - $bbox[0] ) / 2 ), $bbox[1] );
    }
  }
}

sub _update_slider {
  my ( $index, $value, $op, $w, $scale ) = @_;

# This is called from traceVariable so we need to update the "fake" slider position
# according to the current position of the scale slider.
  $w->_setSlider;
  return $value;
}

sub _doScale {
  my ($w) = @_;

  # We only change the scale here
  # Although it looks like we are adjust the slider we aren't.
  # The slider gets adjusted after the variable is seen as changed
  # by the set traceVariable.

  my $c    = $w->Subwidget('canvas');
  my $newY = $c->pointery - $c->rooty;
  my $newX = $c->pointerx - $c->rootx;
  my $off  = $w->{'offset'};
  $w->_setScale( $newX - $off, $newY - $off );
}

sub _setSlider {
  my ($w)   = @_;
  my $c     = $w->Subwidget('canvas');
  my $scale = $w->Subwidget('scale');
  my ( $x,    $y )    = $w->_getSliderPoint;
  my ( $curX, $curY ) = $scale->coords( $scale->get );
  my @limit = $c->bbox('scale');
  my $mp    = $w->{'arrowmidpoint'};
  my $off   = $w->{'offset'};
  if ( $w->{'orient'} eq 'vertical' ) {
    $c->move( 'slider', 0, $curY + $off - $y - 1 );
  }
  else {
    $c->move( 'slider', $curX + $off - $x - 1, 0 );
  }
}

sub _setScale {
  my ( $w, $x, $y ) = @_;
  my $s = $w->Subwidget('scale');
  $s->set( $s->get( $x, $y ) );    #this works for vert and horiz scales
       #because the x is ignored for vertical and y is ignored for horizontal.

}

sub SLIDERBITMAP_TOP    { $SLIDERBITMAP_TOP }
sub SLIDERBITMAP_BOTTOM { $SLIDERBITMAP_BOTTOM }
sub SLIDERBITMAP_LEFT   { $SLIDERBITMAP_LEFT }
sub SLIDERBITMAP_RIGHT  { $SLIDERBITMAP_RIGHT }

1;

=head1 NAME

Tk::MiniScale - A miniature scale widget

=head1 SYNOPSIS

I<$miniscale> = I<$parent>-E<gt>B<MiniScale>(?I<options>?);

=head1 EXAMPLE

    use Tk;
    use Tk::MiniScale;

    my $mw=tkinit;
    my $var = 0;
    $mw->MiniScale(
        -sliderside=>'bottom',
        -variable=>\$var,
        -command=>sub{print "$var\n"},
    )->pack(-fill=>'x', -expand=>1);
    MainLoop;

=head1 SUPER-CLASS

The C<MiniScale> class is derived from the C<Frame> class.
However, this megawidget is comprised of a C<Canvas> containing
two items - an bitmap item and an embedded window which houses
a real L<Tk::Scale|Tk::Scale> widget.

By default, all configurations are delegated to the Scale widget.

=head1 DESCRIPTION

MiniScale is a smaller version of L<Tk::Scale|Tk::Scale> which is 
especially useful when the user doesn't really I<care> about the actual
value of the variable they are modifying. In other words - they just want
to increase or decrease I<something> by a relative amount. This implies
that less precision is needed and therefore less space can be used to
draw this widget. i.e. the increment per pixel can be higher than in a
normal scale

Some useful examples might include a volume control or color intensity
control.

=head1 WIDGET-SPECIFIC OPTIONS

All options provided by the Scale widget are available. Currently there
is only one other option supported.

=over 4

=item B<-sliderside>

Which side of the scale to place the arrow slider. Must be left, right,
top or bottom. The orientation of the scale need not be stated explicitly.
A left or right implies a vertical orientation while top or bottom implies
a horizontal orientation.

=back

=head1 WIDGET METHODS

If you wish to use the L<Tk::Scale|Tk::Scale> methods then you will have
to use the Subwidget method to get the advertised scale object.
Otherwise I<currently> only one public method exists.

=over 4

=item B<switchFromTo>

Switch the -from and -to widget options to align at opposite ends of the scale.

Really - you should B<never> have to call this method. I don't even really
know why I left it as a public method. Some reasoning follows:

A normal Scale widget oriented in the vertical will default a 0 at the top of
the widget and 100 at the bottom. This is undesirable in the miniscale as
as moving the slider upward or to the right is assumed to be towards a higher
number. By default - the MiniScale will always default to a zero at the bottom
and 100 at the top of a vertically oriented widget. Similarly it defaults to a
zero at the left and 100 at the right of a horizontally oriented widget.

So I guess if you don't like that then you can use this method to change it
back.

=back

=head1 ADVERTISED WIDGETS

The following widgets are advertised:

=over

=item canvas

The canvas widget.

=item scale

The scale widget (which is an embedded window in the canvas)

=back

=head1 BUGS

None known at this time. Just be aware that this widget is not meant
to provide precision. It is mainly used as a percentage increase or
decrease to a variable of your choosing.

Also be aware that all the button and keyboard bindings for the
Tk::Scale remain intact. Just give focus to the scale if you want
the user to have access to the keyboard bindings.

I<$miniscale>-E<gt>B<Subwidget>('scale')-E<gt>focus;

=head1 TO DO

This widget was stripped out of another module I was working on. It
will provide a button-invoked popup miniscale. Stay tuned.

=head1 AUTHOR

B<Jack Dunnigan> dunniganj@cpan.org

=cut

