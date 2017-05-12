# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Gtk2::Params;
use 5.008;
use strict;
use warnings;
use List::Util;
use POSIX ();
use Module::Load;
use Glib::Ex::ObjectBits 'set_property_maybe';
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::ToolbarBits;
use Gtk2::Ex::MenuBits;

our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->scalar
                  ('parameter-values',
                   'Parameter Values',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('parameter-info-array',
                   'Parameter Info Arrayref',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('toolbar',
                   'Toolbar',
                   'Blurb.',
                   'Gtk2::Toolbar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('after-toolitem',
                   'After Toolitem',
                   'Blurb.',
                   'Gtk2::ToolItem',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'toolitems_hash'} = {};
  $self->{'parameter_info_array'} = [];
  $self->{'parameter_values'} = {};
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### Params GET_PROPERTY: $pname

  if ($pname eq 'parameter_values') {
    my $toolitems_hash = $self->{'toolitems_hash'};
    # ### $toolitems_hash
    ### parameter_info_array: $self->{'parameter_info_array'}
    my %ret;
    foreach my $pinfo (@{$self->{'parameter_info_array'} || []}) {
      if (_pinfo_when($self,$pinfo)
          && (my $toolitem = _pinfo_to_toolitem ($self, $pinfo))) {
        ### $pinfo
        $ret{$pinfo->{'name'}} = $toolitem->get('parameter-value');
      }
    }
    ### GET_PROPERTY parameter_values: \%ret
    return \%ret;

  } else {
    ### GET_PROPERTY other value: $self->{$pname}
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Params SET_PROPERTY: $pname
  ### $newval

  if ($pname eq 'parameter_values') {
    if (defined $newval) {
      my %newval = (%{$self->{'parameter_values'}},
                    %$newval);
      ### %newval
      foreach my $pinfo (@{$self->{'parameter_info_array'}}) {
        my $name = $pinfo->{'name'};
        my $key = $pinfo->{'share_key'} || $name;
        if ((exists $newval{$name})
            && (my $toolitem = $self->{'toolitems_hash'}->{$key})) {
          $toolitem->set (parameter_value => delete $newval{$name});
        }
      }
      $self->{'parameter_values'} = \%newval;
    }
    return;
  }
  $self->{$pname} = $newval;

  if ($pname eq 'parameter_info_array') {
    my $toolbar = $self->{'toolbar'};
    my $toolitems_hash = $self->{'toolitems_hash'};
    my %hide = %$toolitems_hash;
    my $after = $self->{'after_toolitem'};

    foreach my $pinfo (@$newval) {
      ### $pinfo
      my $name = $pinfo->{'name'};
      my $key = $pinfo->{'share_key'} || $name;

      my $toolitem = $toolitems_hash->{$key};
      if (defined $toolitem) {
        delete $hide{$key};
      } else {
        my $ptype = $pinfo->{'type'};
        my $display = ($pinfo->{'display'} || $name);
        Scalar::Util::weaken (my $weak_self = $self);
        ### new toolitem...
        ### $name
        ### $ptype
        ### $display

        my $class;
        if (defined (my $ptype_hint = $pinfo->{'type_hint'})) {
          $class = "App::MathImage::Gtk2::Params::\u${ptype}::"
            . _hint_to_class($ptype_hint);
          ### hint class: $class
        }
        unless ($class && Module::Util::find_installed($class)) {
          $class = "App::MathImage::Gtk2::Params::\u$ptype";
          ### ptype class: $class
          unless (Module::Util::find_installed($class)) {
            $class = 'App::MathImage::Gtk2::Params::String';
          }
        }

        ### decided class: $class
        Module::Load::load ($class);
        $toolitem = $class->new
          (exists $self->{'parameter_values'}->{$key}
           ? (parameter_value => $self->{'parameter_values'}->{$key})
           : ());

        $toolitem->signal_connect
          ('notify::parameter-value' => \&_do_toolitem_changed, \$weak_self);
        {
          my $tooltip = $pinfo->{'description'};
          if (! defined $tooltip) {
            $tooltip = $self->{'display'};
            if (! defined $tooltip) {
              $tooltip = $self->{'name'};
            }
          }
          if ($toolitem->can('tooltip_extra')) {
            $tooltip .= "\n\n" . $toolitem->tooltip_extra;
          }
          ### $tooltip
          set_property_maybe ($toolitem, # tooltip-text new in 2.12
                              tooltip_text => $tooltip);
        }
        $toolitems_hash->{$key} = $toolitem;
        $toolitem->show_all;
        $toolbar->insert ($toolitem, -1);
      }

      ### set parameter_info: $pinfo
      $toolitem->set (parameter_info => $pinfo);
      Gtk2::Ex::ToolbarBits::move_item_after ($toolbar, $toolitem, $after);
      $after = $toolitem;
    }

    foreach my $toolitem (values %hide) {
      $toolitem->hide;
    }
    _update_visible ($self);
    ### Params notify parameter-values initially ...
    $self->notify('parameter-values');
  }
}

sub _hint_to_class {
  my ($str) = @_;
  $str =~ s/(^|_)(.)/\u$2/g;
  return $str;
}

sub _do_toolitem_changed {
  my ($toolitem) = @_;
  ### _do_toolitem_changed() ...

  my $ref_weak_self = $_[-1];
  my $self = $$ref_weak_self || return;
  _update_visible ($self);
  ### Params notify parameter-values for toolitem changed ...
  $self->notify ('parameter-values');
  ### _do_toolitem_changed() done ...
}

sub _update_visible {
  my ($self) = @_;
  ### Params _update_visible() ...

  my $toolitems_hash = $self->{'toolitems_hash'};
  foreach my $pinfo (@{$self->{'parameter_info_array'}}) {
    ### name: $pinfo->{'name'}
    if (my $toolitem = _pinfo_to_toolitem($self,$pinfo)) {
      $toolitem->set (visible => _pinfo_when($self,$pinfo));
    }
  }
}

sub _pinfo_when {
  my ($self, $pinfo) = @_;
  if (my $when_name = $pinfo->{'when_name'}) {
    ### $when_name
    if (my $when_pinfo = List::Util::first {$_->{'name'} eq $when_name} @{$self->{'parameter_info_array'}}) {
      if (my $when_toolitem = _pinfo_to_toolitem($self,$when_pinfo)) {
        my $got_value = $when_toolitem->get('parameter-value');
        ### $got_value
        if (my $when_condition = $pinfo->{'when_condition'}) {
          if ($when_condition eq 'odd' && ($got_value % 2) == 0) {
            return 0;
          }
        }
        return (defined $got_value
                &&
                List::Util::first
                {$_ eq $got_value}
                (defined $pinfo->{'when_value'} ? $pinfo->{'when_value'} : ()),
                @{$pinfo->{'when_values'} || []});
      }
    }
  }
  return 1;
}

sub _pinfo_to_toolitem {
  my ($self, $pinfo) = @_;
  return $self->{'toolitems_hash'}->{$pinfo->{'share_key'} || $pinfo->{'name'}};
}


1;
__END__
