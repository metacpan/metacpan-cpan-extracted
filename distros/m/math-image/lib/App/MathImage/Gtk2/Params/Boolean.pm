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


package App::MathImage::Gtk2::Params::Boolean;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use Glib::Ex::ObjectBits 'set_property_maybe';

our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


# Gtk2::ToggleToolButton
use Gtk2::Ex::ToolItem::CheckButton;
use Glib::Object::Subclass
  'Gtk2::Ex::ToolItem::CheckButton',
  properties => [ Glib::ParamSpec->boolean
                  ('parameter-value',
                   'Parameter Value',
                   'Blurb.',
                   0,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('parameter-info',
                   'Parameter Info',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ],
  signals => { notify => \&_do_notify };

sub _do_notify {
  my ($self, $pspec) = @_;
  ### Params-Boolean _do_notify(): $pspec->get_name

  my $pname = $pspec->get_name;
  if ($pname eq 'active') {
    ### Boolean notify value...
    $self->notify('parameter-value');
  }
}

sub GET_PROPERTY {
  my ($self) = @_;  # ($self, $pspec)
  return $self->get_active;
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Params-Boolean SET_PROPERTY(): $pspec->get_name

  my $pname = $pspec->get_name;
  if ($pname eq 'parameter_value') {
    $self->{'parameter_value_set'} = 1;
    $self->set_active ($newval);
  } else {
    $self->{$pname} = $newval;

    my $display = $newval->{'display'};
    $self->set (label => defined $display ? $display : $newval->{'name'});
    if (! $self->{'parameter_value_set'}) {
      $self->{'parameter_value_set'} = 1;
      $self->set_active ($newval->{'default'});
    }
  }
}

1;
__END__
