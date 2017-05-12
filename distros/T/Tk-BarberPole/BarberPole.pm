package Tk::BarberPole;

use strict;
use vars qw/$VERSION/;
use constant PI_OVER_180 => 3.141592659 / 180;

$VERSION = 0.01;

use Tk;
use base qw/Tk::Derived Tk::Canvas/;

Construct Tk::Widget 'BarberPole';

sub Populate {
  my ($c, $args) = @_;

  $c->SUPER::Populate($args);

  $c->ConfigSpecs(
		  -width              => [PASSIVE => undef, undef, 30],
		  -length             => [PASSIVE => undef, undef, 100],
		  -stripewidth        => [PASSIVE => undef, undef, 10],
		  -slant              => [PASSIVE => undef, undef, 45],
		  -separation         => [PASSIVE => undef, undef, 20],
		  -orientation        => [PASSIVE => undef, undef, 'horizontal'],
		  -colors             => [PASSIVE => undef, undef, [qw/red blue/]],
		  -delay              => [METHOD  => undef, undef, 50],
		  -highlightthickness => [SELF => 'highlightThickness','HighlightThickness',0],
		  -padx               => [PASSIVE => 'padX', 'Pad', 0],
		  -pady               => [PASSIVE => 'padY', 'Pad', 0],
		  -autostart          => [PASSIVE => undef, undef, 1],
		 );

  $c->afterIdle(['_drawPole', $c]);
}

sub _drawPole {
  my $c = shift;

  # calculate the angle, once and for all.
  # and other values.
  $c->{Len}     = $c->cget('-length');
  $c->{Wid}     = $c->cget('-width');
  $c->{Angle}   = $c->cget('-slant') * PI_OVER_180;
  $c->{Inc}     = $c->{Wid} * tan($c->{Angle});
  $c->{Sep}     = $c->cget('-separation');
  $c->{StripeW} = $c->cget('-stripewidth');
  $c->{Col}     = $c->cget('-colors');
  $c->{Ori}     = $c->cget('-orientation');

  # set the correct canvas size.
  my ($w, $h) = $c->{Ori} eq 'horizontal' ? @{$c}{qw/Len Wid/} : @{$c}{qw/Wid Len/};
  my $bw      = $c->cget('-borderwidth') + $c->cget('-highlightthickness');
  my $padx    = $c->cget('-padx');
  my $pady    = $c->cget('-pady');

  my $startX  = $padx + $bw;
  my $startY  = $pady + $bw;

  $w += 2 * $startX;
  $h += 2 * $startY;

  $c->GeometryRequest($w, $h);

  # draw the outline of the pole.
  $c->createRectangle($startX, $startY, $w-$startX-1, $h - $startY-1,
		      -outline => 'black',
		      -tags    => ['BORDER'],
		     );

  # now draw the stripes.
  if ($c->{Ori} eq 'horizontal') {
    my $x     = -($c->{Inc} + $c->{StripeW});
    my $y     = $startY;
    my $color = 0;

    while ($x < $c->{Len}) {
      push @{$c->{Stripes}} =>
	$c->createPolygon($x, $y, $x + $c->{Inc}, $y + $c->{Wid},
			  $x + $c->{Inc} + $c->{StripeW}, $y + $c->{Wid},
			  $x + $c->{StripeW}, $y,
			  -fill => $c->{Col}[$color % @{$c->{Col}}],
			  -tags => ['STRIPE'],
			 );

      $color ++;
      $x += $c->{Sep};
    }

    # make sure the number of poles are a multiple of the number of colors.
    if (my $mod = @{$c->{Stripes}} % @{$c->{Col}}) {

      my $count = $#{$c->{Col}} - $mod;
      my $x     = -($c->{Inc} + $c->{StripeW} + $c->{Sep}) - $count * $c->{Sep};

      my @new;
      for my $i (0 .. $count) {
	push @new =>
	  $c->createPolygon($x, $startY, $x + $c->{Inc}, $startY + $c->{Wid},
			    $x + $c->{Inc} + $c->{StripeW}, $startY + $c->{Wid},
			    $x + $c->{StripeW}, $startY,
			    -fill => $c->{Col}[$color % @{$c->{Col}}],
			    -tags => ['STRIPE'],
			   );

	$color ++;
	$x += $c->{Sep};
      }

      unshift @{$c->{Stripes}} => @new;
    }

  } else {
    # vertical
    my $x     = $startX;
    my $y     = -($c->{Inc} + $c->{StripeW});
    my $color = 0;

    while ($y < $c->{Len}) {
      push @{$c->{Stripes}} =>
	$c->createPolygon($x, $y, $x + $c->{Wid}, $y + $c->{Inc},
			  $x + $c->{Wid}, $y + $c->{Inc} + $c->{StripeW},
			  $x, $y + $c->{StripeW},
			  -fill => $c->{Col}[$color % @{$c->{Col}}],
			  -tags => ['STRIPE'],
			 );

      $color ++;
      $y += $c->{Sep};
    }

    # make sure the number of poles are a multiple of the number of colors.
    if (my $mod = @{$c->{Stripes}} % @{$c->{Col}}) {

      my $count = $#{$c->{Col}} - $mod;
      my $y     = -($c->{Inc} + $c->{StripeW} + $c->{Sep}) - $count * $c->{Sep};
      my @new;
      for my $i (0 .. $count) {
	push @new =>
	  $c->createPolygon($startX, $y, $startX + $c->{Wid}, $y + $c->{Inc},
			    $startX + $c->{Wid}, $y + $c->{Inc} + $c->{StripeW},
			    $startY, $y + $c->{StripeW},
			    -fill => $c->{Col}[$color % @{$c->{Col}}],
			    -tags => ['STRIPE'],
			   );

	$color ++;
	$y += $c->{Sep};
      }

      unshift @{$c->{Stripes}} => @new;
    }
  }

  # tag first stripe
  $c->{First} = $c->{Stripes}[0];

  $c->raise('BORDER');

  $c->start if $c->cget('-autostart');
}

sub _animate {
  my $c = shift;

  # check for any stripes that are outside the visible area
  # and move them to the beginning.

  my @visible = $c->find(overlapping => 0, 0, $c->{Len}, $c->{Wid});
  my %h;
  @h{@{$c->{Stripes}}} = 1;
  delete $h{$_} for @visible;

  for my $id (keys %h) {
    # find how far each stripe is from the end of the pole,
    # and move it the same distance away from the first stripe.

    my @c = $c->coords($id);

    my $dist = $c->{Ori} eq 'horizontal' ? $c[0] - $c->{Len} : $c[1] - $c->{Len};
    next if $dist < 0;   # before the beginning.

    # calculate offset
    my @f      = $c->coords($c->{First});
    my $offset = $c->{Ori} eq 'horizontal' ?
      ($c[0] - $f[0]) + $c->{Sep} :
	($c[1] - $f[1]) + $c->{Sep};

    # move it.
    $c->move($id, $c->{Ori} eq 'horizontal' ? (-$offset, 0) : (0, -$offset));
    $c->{First} = $id;
  }

  # now move everything.
  $c->move(STRIPE => $c->{Ori} eq 'horizontal' ? (1, 0) : (0, 1));
}

sub delay {
  my ($c, $v) = @_;

  if (defined $v) {
    $c->{Delay} = $v;
  }

  if ($c->{Anim}) {
    $c->afterCancel($c->{RepID});
    $c->{RepID} = $c->repeat($c->{Delay}, ['_animate', $c]);
  }

  return $c->{Delay};
}

sub start {
  my $c = shift;

  return if $c->{Anim};

  # now start the animation
  $c->{RepID} = $c->repeat($c->{Delay}, ['_animate', $c]);
  $c->{Anim}  = 1;
}

sub stop {
  my $c = shift;

  return unless $c->{Anim};

  # now stop the animation
  $c->afterCancel($c->{RepID});
  $c->{Anim} = 0;
}

sub tan { sin($_[0]) / cos($_[0])  }

1;

__END__

=head1 NAME

Tk::BarberPole - A rotating barber pole

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::BarberPole;

    $pole = $parent->BarberPole(
	-width       => 200,
	-length      => 20,
	-bg          => 'white',
        -orientation => 'vertical',
	-colors      => [qw/red blue/],

	-slant       => 38,
        -stripewidth => 15,
        -separation  => 35,

        -delay       => 50,
        -autostart   => 1,
    );

    $pole->start;
    $pole->stop;

=head1 DESCRIPTION

B<Tk::BarberPole> is a widget in the shape of a rotating barber pole. Animation can
be started and stopped programatically.

=head1 STANDARD OPTIONS

The following standard widget options are supported:

=over 4

=item B<-borderwidth>

Defaults to 0.

=item B<-highlightthickness>

Defaults to 0.

=item B<-padx>

Defaults to 0.

=item B<-pady>

Defaults to 0.

=item B<-relief>

Defaults to C<flat>.

=back

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item B<-autostart>

If set to a true value, animation of the barber pole automatically starts
at widget creation. The animation can be further controlled via the
L<start|"WIDGET METHODS"> and L<stop|"WIDGET METHODS"> methods. Defaults to 1.

=item B<-colors>

Specifies the colors of the stripes. The value must be an anonymous list of
the colors. The number of stripes will always be a multiple of the number of
colors specified. Defaults to C<['red', 'blue']>.

=item B<-delay>

The delay, in milliseconds, between successive updates of the stripe positions.
Each update moves the stripes by one pixel. The smaller the delay, the faster
the animation. Defaults to 50.

=item B<-length>

Specifies the desired long dimension of the BarberPole in screen
units (i.e. any of the forms acceptable to Tk_GetPixels). For vertical
BarberPoles this is the height; for horizontal ones it
is the width. Defaults to 100.

=item B<-orientation>

Specifies the orientation of the BarberPole. Valid values are 'horizontal',
and 'vertical'. Defaults to 'horizontal'.

=item B<-separation>

Specifies the distance, in pixels, between successive stripes.
Defaults to 20.

=item B<-slant>

Specifies the angle, in degrees, of each stripe. Defaults to 45.

=item B<-stripewidth>

Specifies the width of each stripe in pixels. Defaults to 10.

=item B<-width>

Specifies the desired short dimension of the BarberPole in screen
units (i.e. any of the forms acceptable to Tk_GetPixels). For vertical
BarberPoles this is the width; for horizontal ones it
is the height. Defaults to 30.

=back

=head1 WIDGET METHODS

=over 4

=item I<$pole>-E<gt>B<start>

Starts the animation.

=item I<$pole>-E<gt>B<stop>

Stops the animation.

=back

=head1 INSTALLATION

Either the usual:

        perl Makefile.PL
        make
        make install

or just stick it somewhere in \@INC where perl can find it. It's in pure Perl.

=head1 AUTHOR

Ala Qumsieh E<lt>F<aqumsieh@cpan.org>E<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ala Qumsieh. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


