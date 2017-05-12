# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


# rootwin for ewmh virtual root ?
# listen for randr root size ?


package App::MathImage::X11::Protocol::Splash;
use 5.004;
use strict;
use Carp;
use List::Util 'max';  # 5.6 ?
use X11::Protocol;
use X11::Protocol::WM;

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub DESTROY {
  my ($self) = @_;
  if (my $win = $self->{'window'}) {
    $self->{'X'}->DestroyWindow ($win);
  }
}

sub popup {
  my ($self) = @_;
  my $X = $self->{'X'};
  $X->MapWindow ($self->create_window);
  $X->ClearArea ($self->{'window'}, 0,0,0,0);
  $X->flush;
}

sub popdown {
  my ($self) = @_;
  if (my $win = $self->{'window'}) {
    my $X = $self->{'X'};
    $X->UnmapWindow ($win);
    $X->flush;
  }
}

sub create_window {
  my ($self) = @_;
  if (! $self->{'window'}) {
    my $X = $self->{'X'};
    my $pixmap = $self->{'pixmap'};
    my $width = $self->{'width'};
    my $height = $self->{'height'};
    if (! defined $width || ! defined $height) {
      my %geom = $X->GetGeometry($pixmap);
      $width = $self->{'width'} =  $geom{'width'};
      $height = $self->{'height'} = $geom{'height'};
    }
    my $x = int (max (0, $X->{'width_in_pixels'} - $width) / 2); #  + 100
    my $y = int (max (0, $X->{'height_in_pixels'} - $height) / 2);

    my $parent = (X11::Protocol::WM::root_to_virtual_root($X,$X->root)
                  || $X->root);

    my $window = $X->new_rsrc;
    $X->CreateWindow ($window,
                      $parent,
                      'InputOutput',    # class
                      0,                # depth, from parent
                      'CopyFromParent', # visual
                      $x,$y,
                      $width,$height,
                      0,                # border
                      background_pixmap => $pixmap,
                      # background_pixel  => 0x00FFFF,
                      override_redirect => 1,
                      # save_under        => 1,
                      # backing_store     => 'Always',
                      # bit_gravity       => 'Static',
                      # event_mask        =>
                      # $X->pack_event_mask('Exposure',
                      #                     'ColormapChange',
                      #                     'VisibilityChange',),
                     );
    # $X->ChangeWindowAttributes ($window,
    #                            );
    # if ($window == 0x1600002) {
    # }
    ### sync: $X->QueryPointer($X->root)
    $self->{'window'} = $window;

    X11::Protocol::WM::set_wm_name ($X, $window, "Splash");
    if (my $transient_for = $self->{'transient_for'}) {
      X11::Protocol::WM::set_wm_transient_for
          ($X, $window, $transient_for);
    }
    X11::Protocol::WM::set_wm_hints
        ($X, $window,
         input => 0,
         window_group => $self->{'window_group'});
    X11::Protocol::WM::set_net_wm_window_type ($X, $window, 'SPLASH');
  }
  return $self->{'window'};
}


1;
__END__

=for stopwords Math-Image Ryde

=head1 NAME

App::MathImage::X11::Protocol::Splash -- temporary splash window

=for test_synopsis my ($X, $id)

=head1 SYNOPSIS

 use App::MathImage::X11::Protocol::Splash;
 my $splash = App::MathImage::X11::Protocol::Splash->new
                (X => $X,
                 pixmap => $id);
 $splash->popup;
 # ...
 $splash->popdown;

=head1 DESCRIPTION

(Unattended redraw not working ...)

...

=head1 FUNCTIONS

=over 4

=item C<$splash = App::MathImage::X11::Protocol::Splash-E<gt>new (key=E<gt>value,...)>

Create and return a new Splash object.  The key/value parameters are

    X         X11::Protocol object (mandatory)
    pixmap    xid of pixmap to display
    width     integer (optional)
    height    integer (optional)

=item C<$splash-E<gt>popup>

=item C<$splash-E<gt>popdown>

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Other>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see <http://www.gnu.org/licenses/>.

=cut
