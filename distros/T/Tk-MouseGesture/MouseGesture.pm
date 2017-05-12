
package Tk::MouseGesture;

use Carp;
use strict;
use Tk;

use vars qw/$VERSION/;
$VERSION = 0.03;

Construct Tk::Widget 'MouseGesture';

# the following hash defines the set of predefined gestures.
my %gestures = (
		'B1-left'    => \&_ges_b1_left,
		'B2-left'    => \&_ges_b2_left,
		'B3-left'    => \&_ges_b3_left,

		'B1-right'   => \&_ges_b1_right,
		'B2-right'   => \&_ges_b2_right,
		'B3-right'   => \&_ges_b3_right,

		'B1-up'      => \&_ges_b1_up,
		'B2-up'      => \&_ges_b2_up,
		'B3-up'      => \&_ges_b3_up,

		'B1-down'    => \&_ges_b1_down,
		'B2-down'    => \&_ges_b2_down,
		'B3-down'    => \&_ges_b3_down,

		'B1-diag-UL' => \&_ges_b1_diag_ul,
		'B2-diag-UL' => \&_ges_b2_diag_ul,
		'B3-diag-UL' => \&_ges_b3_diag_ul,

		'B1-diag-UR' => \&_ges_b1_diag_ur,
		'B2-diag-UR' => \&_ges_b2_diag_ur,
		'B3-diag-UR' => \&_ges_b3_diag_ur,

		'B1-diag-LL' => \&_ges_b1_diag_ll,
		'B2-diag-LL' => \&_ges_b2_diag_ll,
		'B3-diag-LL' => \&_ges_b3_diag_ll,

		'B1-diag-LR' => \&_ges_b1_diag_lr,
		'B2-diag-LR' => \&_ges_b2_diag_lr,
		'B3-diag-LR' => \&_ges_b3_diag_lr,
	       );

my @objects;

sub new {
  my ($class, $parent, $gesture, %args) = @_;

  # make sure the parent is a toplevel.
  unless ($parent->isa('Tk::Toplevel')) {
    #carp "Parent of $class must be a toplevel widget!";
    #    return undef;

    # get the parent.
    $parent = $parent->toplevel;
  }

  # make sure the gesture exists and is one that is known.
  unless ($gesture) {
    carp "Wrong arguments. Must be MouseGesture(gesture_name, callback)";
    return undef;
  }

  unless (exists $gestures{$gesture}) {
    carp "Unknown mouse gesture '$gesture'!";
    return undef;
  }

  my $obj = bless {
		   PARENT => $parent,
		   XRES   => $args{-xres}    || 20,
		   YRES   => $args{-yres}    || 20,
		   SUB    => $args{-command} || sub {},
		   MIN    => $args{-min}     || 50,
		   EN     => 1,
		  } => $class;

  $obj->addGesture($gesture);

  push @objects => $obj;

  return $obj;
}

sub disable { $_[0]{EN} = 0 }
sub enable  { $_[0]{EN} = 1 }

sub disableAll { $_->disable for @objects }
sub enableAll  { $_->enable  for @objects }

sub addGesture {
  my ($self, $gesture) = @_;

  # make sure the gesture is one that is known.
  unless (exists $gestures{$gesture}) {
    carp "Unknown mouse gesture '$gesture'!";
    return undef;
  }

  $gestures{$gesture}->($self);
}

sub command {
  my ($self, $sub) = @_;

  $self->{SUB} = $sub if $sub;

  return $self->{SUB};
}

sub _ges_b1_left { _generic_straight(1, -1, 0, @_) }
sub _ges_b2_left { _generic_straight(2, -1, 0, @_) }
sub _ges_b3_left { _generic_straight(3, -1, 0, @_) }

sub _ges_b1_right { _generic_straight(1, 1, 0, @_) }
sub _ges_b2_right { _generic_straight(2, 1, 0, @_) }
sub _ges_b3_right { _generic_straight(3, 1, 0, @_) }

sub _ges_b1_up { _generic_straight(1, 0, -1, @_) }
sub _ges_b2_up { _generic_straight(2, 0, -1, @_) }
sub _ges_b3_up { _generic_straight(3, 0, -1, @_) }

sub _ges_b1_down { _generic_straight(1, 0, 1, @_) }
sub _ges_b2_down { _generic_straight(2, 0, 1, @_) }
sub _ges_b3_down { _generic_straight(3, 0, 1, @_) }

sub _generic_straight {
  # arguments are:
  # 1. button number.
  # 2. horizontal-sensitivity: if 0 => vertical gesture
  #                               1 => right
  #                              -1 => left
  # 3. veritcal  -sensitivity: if 0 => horizontal gesture
  #                               1 => bottom
  #                              -1 => top
  # 4. self.

  my ($b, $X, $Y, $self) = @_;

  my $p    = $self->{PARENT};
  my $xres = $self->{XRES};
  my $yres = $self->{YRES};
  my $min  = $self->{MIN};
  my $cb   = Tk::Callback->new($self->{SUB});

  my ($x, $y, $xc, $yc, $within);

  # make sure any other bindings are preserved.
  my $old1 = $p->bind("<$b>");
  my $old2 = $p->bind("<B$b-Motion>");
  my $old3 = $p->bind("<B$b-ButtonRelease>");

  $p->bind("<$b>" => sub {
	     $old1 && $old1->Call;
	     return unless $self->{EN};

	     $within    = 1;
	     ($x, $y)   = $p->pointerxy;
	     ($xc, $yc) = ($x, $y);
	   });
  $p->bind("<B$b-Motion>" => sub {
	     $old2 && $old2->Call;
	     return unless $self->{EN};
	     return unless $within;

	     my ($nx, $ny) = $p->pointerxy;

	     if ($Y) {
	       if ($Y > 0) {
		 $within = 0 if $ny < $yc;
	       } else {
		 $within = 0 if $ny > $yc;
	       }
	     } else {
	       $within = 0 if abs($ny - $y) > $yres;
	     }

	     if ($X) {
	       if ($X > 0) {
		 $within = 0 if $nx < $xc;
	       } else {
		 $within = 0 if $nx > $xc;
	       }
	     } else {
	       $within = 0 if abs($nx - $x) > $yres;
	     }

	     $xc = $nx;
	     $yc = $ny;
	   });
  $p->bind("<B$b-ButtonRelease>" => sub {
	     $old3 && $old3->Call;
	     return unless $self->{EN};

	     $within or return;

	     my ($nx, $ny) = $p->pointerxy;
	     my $ok = 0;

	     if ($X) {
	       $ok = 1 if abs($nx - $x) >= $min;
	     } else {
	       $ok = 1 if abs($ny - $y) >= $min;
	     }
	     $ok && $cb->Call;
	   });
}

sub _ges_b1_diag_ul { _generic_diag(1, -1, -1, @_) }
sub _ges_b2_diag_ul { _generic_diag(2, -1, -1, @_) }
sub _ges_b3_diag_ul { _generic_diag(3, -1, -1, @_) }

sub _ges_b1_diag_ur { _generic_diag(1,  1, -1, @_) }
sub _ges_b2_diag_ur { _generic_diag(2,  1, -1, @_) }
sub _ges_b3_diag_ur { _generic_diag(3,  1, -1, @_) }

sub _ges_b1_diag_ll { _generic_diag(1, -1,  1, @_) }
sub _ges_b2_diag_ll { _generic_diag(2, -1,  1, @_) }
sub _ges_b3_diag_ll { _generic_diag(3, -1,  1, @_) }

sub _ges_b1_diag_lr { _generic_diag(1,  1,  1, @_) }
sub _ges_b2_diag_lr { _generic_diag(2,  1,  1, @_) }
sub _ges_b3_diag_lr { _generic_diag(3,  1,  1, @_) }

sub _generic_diag {
  my ($b, $X, $Y, $self) = @_;

  my $p    = $self->{PARENT};
  my $res  = $self->{XRES} > $self->{YRES} ? $self->{XRES} : $self->{YRES};
  my $min  = $self->{MIN};
  my $cb   = Tk::Callback->new($self->{SUB});

  my ($x, $y, $xc, $yc, $within);

  my $slope = $X^$Y ? -1 : 1;

  # dist of point (xo, yo) to line ax + by + c = 0
  # d = abs(axo + bxo + c) / sqrt(a^2 + b^2)   trust me

  my $A = $slope;
  my $B = -1;
  my $C;
  my $den = sqrt($A**2 + 1);

  # make sure any other bindings are preserved.
  my $old1 = $p->bind("<$b>");
  my $old2 = $p->bind("<B$b-Motion>");
  my $old3 = $p->bind("<B$b-ButtonRelease>");

  $p->bind("<$b>" => sub {
	     $old1->Call if $old1;
	     return unless $self->{EN};

	     $within    = 1;
	     ($x, $y)   = $p->pointerxy;
	     ($xc, $yc) = ($x, $y);
	     $C         = $y - $slope * $x;
	   });
  $p->bind("<B$b-Motion>" => sub {
	     $old2->Call if $old2;
	     return unless $self->{EN};
	     return unless $within;

	     my ($nx, $ny) = $p->pointerxy;

	     # get dist to line with slope +/-1
	     my $dist = abs($A * $nx + $B * $ny + $C) / $den;

	     $dist > $res and return $within = 0;

	     if ($X > 0) {  # right
	       $within = 0 if $nx < $xc;
	       if ($Y > 0) { # down => DR
		 $within = 0 if $ny < $yc;
	       } else {      # up   => UR
		 $within = 0 if $ny > $yc;
	       }
	     } else {       # left
	       $within = 0 if $nx > $xc;
	       if ($Y > 0) { # down => DL
		 $within = 0 if $ny < $yc;
	       } else {      # up   => UL
		 $within = 0 if $ny > $yc;
	       }
	     }
	   });

  $p->bind("<B$b-ButtonRelease>" => sub {
	     $old3 && $old3->Call;
	     return unless $self->{EN};
	     $within or return;

	     my ($nx, $ny) = $p->pointerxy;
	     my $ok = 0;
	     $ok     = 1 if $min < sqrt(($x-$nx)**2 + ($y-$ny)**2);

	     $ok && $cb->Call;
	   });
}

"one";

__END__

=head1 NAME

Tk::MouseGesture - Create bindings for mouse gestures.

=head1 SYNOPSIS

    use Tk::MouseGesture;
    my $mg = $top->MouseGesture('B1-left',
                          -xres     => 20,
                          -yres     => 20,
                          -min      => 50,
                          -command  => sub { print "yes!\n" });
    $mg->addGesture('B3-diag-UL');

=head1 DESCRIPTION

Tk::MouseGesture allows your Perl/Tk app to recognize
various mouse gestures. A mouse gesture is a series of
mouse motions (usually accompanied by a button drag) that
act as short-cuts to certain operations. They are most widely
used in web browsers like Opera and Mozilla.
Gestures are bound to callbacks such that
when a user performs a recognized gesture, the
corresponding callback is called.

=head1 CONSTRUCTOR

A new mouse gesture binding can be created as follows:

C<$mg = $top-E<gt>B<MouseGesture>(B<Gesture>, ?options?);>

where C<Gesture> is one of the defined gestures, as described
in L</"GESTURES">. The parent of a Tk::MouseGesture object has
to be a Toplevel widget (Tk::MainWindow is a Toplevel).
If the parent is not a Toplevel widget, then Tk::MouseGesture
will figure out the Toplevel window that contains the parent,
and assume that as its parent.
The other options come in hash-value syntax,
and are described below. The call to C<MouseGesture()> returns
a Tk::MouseGesture object.

Valid options are:

=over 4

=item -xres

This defines the I<X resolution in pixels>, which is a vertical
window of this width that the mouse pointer has to stay within
for the entire duration of the gesture. Defaults to 20 pixels.

=item -yres

This defines the I<Y resolution in pixels>, which is a horizontal
window of this width that the mouse pointer has to stay within
for the entire duration of the gesture. Defaults to 20 pixels.

=item -min

This defines the minimum length of the gesture in pixels. If a
gesture is shorter than this length, then it is not recognized.
Defaults to 50 pixels.

=item -command

This defines the callback to be executed upon the successful
completion of a gesture. It accepts any valid Tk Callback as
defined in the L<Tk::Callbacks|Tk::Callbacks> pod. It defaults
to an empty sub. You can modify it via the call to C<command()>
as described in L</METHODS>.

=back

Note that there is no destructor. Currently, there is no way to
destroy a Tk::MouseGesture object as this might delete any bindings
to the parent widget set by the user. You can disable the recognition
of a mouse gesture via a call to C<disable()> as described in
L</METHODS>.

=head1 METHODS

The following methods are available:

=over 4

=item I<$mg>-E<gt>B<command>(?Callback?)

This method allows you to modify the callback bound to the
gesture object C<$mg>. It takes one optional argument which is
a valid Tk Callback as defined in the L<Tk::Callbacks|Tk::Callbacks>
pod. If no argument is given, then the currently bound callback is
returned.

=item I<$mg>-E<gt>B<disable>()

This disables the recognition of this particular gesture.

=item I<$mg>-E<gt>B<enable>()

This enables the recognition of this particular gesture.

=item I<$mg>-E<gt>B<disableAll>()

This disables the recognition of all defined mouse gesture.

=item I<$mg>-E<gt>B<enableAll>()

This enables the recognition of all defined mouse gesture.

=item I<$mg>-E<gt>B<addGesture>(Gesture)

This adds another gesture binding. C<Gesture> has to be one of
the defined gestures, as described in L</GESTURES>. The callback
associated with this gesture is the same as that supplied during
the constructor (or set via a C<command()> call).
This allows you to create multiple gesture definitions that are
bound to the same callback. To define another callback, you have
to create a new Tk::MouseGesture object.

=back

=head1 GESTURES

For now, only linear gesture are defined. These are:

=over 4

=item B1-left

=item B2-left

=item B3-left

Click on the first, second or third button, and drag the mouse to the left.

=item B1-right

=item B2-right

=item B3-right

Click on the first, second or third button, and drag the mouse to the right.

=item B1-up

=item B2-up

=item B3-up

Click on the first, second or third button, and drag the mouse upwards.

=item B1-down

=item B2-down

=item B3-down

Click on the first, second or third button, and drag the mouse downwards.

=item B1-diag-UL

=item B2-diag-UL

=item B3-diag-UL

Click on the first, second or third button, and drag the mouse diagonally
upwards and to the left (north-west) at 45 degrees.

=item B1-diag-UR

=item B2-diag-UR

=item B3-diag-UR

Click on the first, second or third button, and drag the mouse diagonally
upwards and to the right (north-east) at 45 degrees.

=item B1-diag-LL

=item B2-diag-LL

=item B3-diag-LL

Click on the first, second or third button, and drag the mouse diagonally
downwards and to the left (south-west) at 45 degrees.

=item B1-diag-LR

=item B2-diag-LR

=item B3-diag-LR

Click on the first, second or third button, and drag the mouse diagonally
downwards and to the right (south-east) at 45 degrees.

=back

=head1 BUGS

None that I know of.

=head1 INSTALLATION

Either the usual:

	perl Makefile.PL
	make
	make install

or just stick it somewhere in @INC where perl can find it. It's in pure Perl.

=head1 AUTHOR

B<Ala Qumsieh> <aqumsieh@cpan.org>.

Copyright (c) 2003 Ala Qumsieh. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
