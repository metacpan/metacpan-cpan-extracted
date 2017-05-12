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


package App::MathImage::Gtk2::Params::Enum;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use Glib::Ex::ObjectBits 'set_property_maybe';
use Locale::TextDomain 1.19 ('App-MathImage');

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Gtk2::Ex::ToolItem::ComboEnum;
use Glib::Object::Subclass
  'Gtk2::Ex::ToolItem::ComboEnum',
  properties => [ Glib::ParamSpec->string
                  ('parameter-value',
                   'Parameter Value',
                   'Blurb.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('parameter-info',
                   'Parameter Info',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ],
  signals => { notify => \&_do_notify };

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub _do_notify {
  my ($self, $pspec) = @_;
  ### Params-Enum _do_notify(): $pspec->get_name

  $self->signal_chain_from_overridden ($pspec);

  my $pname = $pspec->get_name;
  if ($pname eq 'active_nick') {
    ### Enum notify value...
    $self->notify('parameter_value');
  }
}

sub GET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Params-Enum GET_PROPERTY: $pspec->get_name

  my $pname = $pspec->get_name;
  if ($pname eq 'parameter_value') {
    return $self->get('active_nick');
  } else {
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Params-Enum SET_PROPERTY: $pspec->get_name, $newval

  my $pname = $pspec->get_name;
  if ($pname eq 'parameter_value') {
    $self->set (active_nick => $newval);
    ### Params-Enum active-nick now: $self->get('active-nick')

  } else {
    my $name = $newval->{'name'};
    my $display = ($newval->{'display'} || $name);
    $self->set (enum_type => _pinfo_to_enum_type($newval),
                overflow_mnemonic =>
                Gtk2::Ex::MenuBits::mnemonic_escape($display));
    if (! defined ($self->get('parameter-value'))) {
      $self->set (parameter_value => $newval->{'default'});
    }

    my $combobox = $self->get_child;
    set_property_maybe ($combobox, # tearoff-title new in 2.10
                        tearoff_title => __('Math-Image:').' '.$display);
  }
}

sub _pinfo_to_enum_type {
  my ($pinfo) = @_;
  my $key = $pinfo->{'share_key'} || $pinfo->{'name'};
  my $enum_type = "App::MathImage::Gtk2::Params::Enum::$key";
  if (! eval { Glib::Type->list_values ($enum_type); 1 }) {
    my $choices = $pinfo->{'choices'} || [];
    ### $choices
    Glib::Type->register_enum ($enum_type, @$choices);

    if (my $choices_display = $pinfo->{'choices_display'}) {
      no strict 'refs';
      %{"${enum_type}::EnumBits_to_display"}
        = map { $choices->[$_] => $pinfo->{'choices_display'}->[$_] }
          0 .. $#$choices;
    }
  }
  return $enum_type;
}

1;
__END__
