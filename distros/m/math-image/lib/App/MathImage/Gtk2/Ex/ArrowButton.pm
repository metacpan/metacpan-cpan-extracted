# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk2::Ex::ArrowButton;
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

# Priority level ":gtk" treating these as widget level defaults.  An
# "application" or user RC file can override.
#
# "GtkButton::image-spacing" only affects a GtkBox child, for an image plus
# label display.
#
# "GtkArrow::arrow-scaling" is normally 0.7 to have it take only 70% of the
# area, up that to 1 for full size.
#
Gtk2::Rc->parse_string (<<'HERE');
style "App__MathImage__Gtk2__Ex__Arrow_style" {
  xthickness = 0
  ythickness = 0
  GtkButton::inner-border = {0,0,0,0}
  GtkButton::default-border = {0,0,0,0}
  GtkWidget::focus-padding = 0
  GtkWidget::focus-line_width = 0
  GtkArrow::arrow-scaling = .9
}
class "App__MathImage__Gtk2__Ex__ArrowButton" style:gtk "App__MathImage__Gtk2__Ex__Arrow_style"
widget_class "*App__MathImage__Gtk2__Ex__ArrowButton.GtkArrow" style:gtk "App__MathImage__Gtk2__Ex__Arrow_style"
HERE

use Glib::Object::Subclass
  'Gtk2::Button',
  properties => [
                 do {
                   my $pspec = Gtk2::Arrow->find_property('arrow-type');
                   Glib::ParamSpec->enum
                       ('arrow-type',
                        $pspec->get_nick,
                        $pspec->get_blurb,
                        'Gtk2::ArrowType',
                        $pspec->get_default_value,
                        Glib::G_PARAM_READWRITE)
                     },
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->can_focus (0);

  # does relief do anything when no border etc?
  #   $self->set_property (relief => 'none');

  ### border_width: $self->get_border_width
  ### relief: $self->get_relief

  my $arrow = Glib::Object::new ('Gtk2::Arrow',
                                 shadow_type => 'none',
                                 visible => 1);
  $arrow->set_size_request (1,1);
  # $arrow->requisition->width (1);  # override arrow 15 pixel
  # $arrow->requisition->height (1); # MIN_ARROW_SIZE
  $self->add ($arrow);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'arrow_type') {
    my $arrow = $self->get_child || return 'none';
    return $arrow->get_property ('arrow-type');
  }
  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ArrowButton SET_PROPERTY: $pname
  ### $newval

  if ($pname eq 'arrow_type') {
    my $arrow = $self->get_child || return;
    $arrow->set_property ($pname, $newval);
  } else {
    $self->{$pname} = $newval;
  }
}

1;
__END__

=for stopwords Math-Image Ryde ArrowButton enum

=head1 NAME

App::MathImage::Gtk2::Ex::ArrowButton -- button with a direction arrow

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::ArrowButton;
 my $ab = App::MathImage::Gtk2::Ex::ArrowButton->new;

=head1 WIDGET HIERARCHY

C<App::MathImage::Gtk2::Ex::ArrowButton> is a subclass of C<Gtk2::Button>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Button
            App::MathImage::Gtk2::Ex::ArrowButton

=head1 DESCRIPTION

An ArrowButton widget is a C<Gtk2::Button> with a directional arrow drawn in
it.

    +-----------+
    |    +      |
    |    |\     |
    |    | \    |
    |    |  +   |
    |    | /    |
    |    |/     |
    |    +      |
    +-----------+

In the current code it's done simply with a C<Gtk2::Arrow> widget child, but
with various properties and style settings arranged to make it fill the
button, and to avoid the arrow's otherwise hard-coded 15 pixel minimum size.

=head1 FUNCTIONS

=over 4

=item C<< $ab = App::MathImage::Gtk2::Ex::ArrowButton->new (key=>value,...) >>

Create and return a new ArrowButton object.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.

    my $ab = App::MathImage::Gtk2::Ex::ArrowButton->new (arrow_type => 'left');

=back

=head1 PROPERTIES

=over 4

=item C<arrow-type> (C<Gtk2::ArrowType> enum, default C<right>)

The arrow type to show, one of C<up>, C<down>, C<left>, C<right> or C<none>.
C<none> means nothing is shown.  The default is the same as C<Gtk2::Arrow>.

=back

=head1 IMPLEMENTATION NOTES

C<Gtk2::Arrow> always responds to its C<< $arrow->size_request >> asking for
15x15 pixels.  Most container widgets (including C<Gtk2::Button>) respect
that and the effect is that it can be made bigger if desired, but no smaller
than 15 pixels.  A C<< $arrow->set_size_request(1,1) >> or similar can be
used to reduce it if the container's size is going to be determined
elsewhere and the arrows shouldn't have a minimum.

=head1 SEE ALSO

L<Gtk2::Button>,
L<Gtk2::Arrow>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut
