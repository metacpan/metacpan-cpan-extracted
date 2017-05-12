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


package App::MathImage::Gtk2::Params::String;
use 5.008;
use strict;
use warnings;
use Carp;
use POSIX ();
use Glib;
use Gtk2;
use Gtk2::Ex::EntryBits 46; # v.46 for scroll_number_handler()
use Glib::Ex::ObjectBits 'set_property_maybe';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Gtk2::Ex::ToolItem::OverflowToDialog 41; # v.41 fix overflow-mnemonic
use Glib::Object::Subclass
  'Gtk2::Ex::ToolItem::OverflowToDialog',
  properties => [ Glib::ParamSpec->string
                  ('parameter-value',
                   'Parameter Value',
                   'Blurb.',
                   '', # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('parameter-info',
                   'Parameter Info',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'parameter_value') {
    if (my $child = $self->get('child-widget')) {
      if ($child->isa('Gtk2::ComboBoxEntry')) {
        $child = $child->get_child;
      }
      return ($child->get('text'));
    }
    return undef;

  } else {
    return $self->{$pname};
  }
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Params-String SET_PROPERTY: $pname

  if ($pname eq 'parameter_value') {
    ### parameter_value: $newval
    $self->{'parameter_value_set'} = $newval;
    if (my $child = $self->get('child-widget')) {
      if (! defined $newval) { $newval = ''; }
      if ($child->isa('Gtk2::ComboBoxEntry')) {
        if (my $iter = Gtk2::Ex::ComboBoxBits::find_text_iter ($child, $newval)) {
          ### active iter: $iter
          $child->set_active_iter ($iter);
          ### parameter-value now: $self->get('parameter-value')
          return;
        }
        # foreach my $path ($App::MathImage::Generator->path_choices) {
        #   if ($newval eq $path) {
        #     ### active pos: $pos
        #     $child->set_active ($pos);
        #     return;
        #   }
        # }
        $child = $child->get_child;
      }
      $child->set (text => $newval);
    }

  } else {
    my $oldval = $self->{$pname};
    $self->{$pname} = $newval;

    my $entry = $self->get('child-widget');
    unless ($entry) {
      my $entry_class = 'Gtk2::Entry';
      my $type_hint = ($newval->{'type_hint'} || '');
      if ($type_hint eq 'oeis_anum') {
        require App::MathImage::Gtk2::OeisEntry;
        $entry_class = 'App::MathImage::Gtk2::OeisEntry';
      }
      if ($type_hint eq 'fraction') {
        require App::MathImage::Gtk2::FractionEntry;
        $entry_class = 'App::MathImage::Gtk2::FractionEntry';
      }
      if ($newval->{'choices'}) {
        my $combo = Gtk2::ComboBoxEntry->new;

        # require App::MathImage::Gtk2::Drawing::Path;
        # my $enum_type = 'App::MathImage::Gtk2::Drawing::Path';
        # my @nicks = map {$_->{'nick'}} Glib::Type->list_values($enum_type);
        # ### @nicks
        # App::MathImage::Generator->path_choices) {

        my $model = Gtk2::ListStore->new ('Glib::String');
        foreach my $choice (@{$newval->{'choices'}}) {
          $model->set ($model->append, 0, $choice);
        }
        $combo->set_model ($model);
        $combo->set_text_column (0);
        Scalar::Util::weaken (my $weak_self = $self);
        $combo->signal_connect (changed => \&_do_combo_changed, \$weak_self);
        $combo->show;
        $self->add ($combo);
        $entry = $combo->get_child;

      } else {
        $entry = $entry_class->new;
        if (exists $self->{'parameter_value_set'}) {
          $entry->set (text => $self->{'parameter_value_set'});
          $self->{'parameter_value_set'} = 1;
        }
        $entry->show;
        $self->add ($entry);
      }

      Scalar::Util::weaken (my $weak_self = $self);
      $entry->signal_connect (activate => \&_do_entry_activate,
                              \$weak_self);
      if ($entry->isa('Gtk2::Entry')) {
        # plain strings, not OeisEntry or FractionEntry
        $entry->signal_connect (scroll_event =>
                                \&Gtk2::Ex::EntryBits::scroll_number_handler);
      }
    }
    if (! $self->{'parameter_value_set'}) {
      # initial parameter-info
      $self->{'parameter_value_set'} = 1;
      $self->set (parameter_value => $newval->{'default'});
    }

    if ($entry->isa('Gtk2::ComboBoxEntry')) {
      $entry = $entry->get_child;
    }

    $entry->set (width_chars => $newval->{'width'} || 5);

    my $display = ($newval->{'display'} || $newval->{'name'});
    $self->set (overflow_mnemonic =>
                Gtk2::Ex::MenuBits::mnemonic_escape($display));
  }
}

sub _do_entry_activate {
  my ($entry, $ref_weak_self) = @_;
  ### Params-String _do_entry_activate()...
  my $self = $$ref_weak_self || return;
  ### parameter-value now: $self->get('parameter-value')
  $self->notify ('parameter-value');
}

sub _do_combo_changed {
  my ($entry, $ref_weak_self) = @_;
  ### Params-String _do_combo_changed()...
  my $self = $$ref_weak_self || return;
  my $combo = $self->get('child-widget');
  if ($combo->get_active_iter) {
    ### parameter-value now: $self->get('parameter-value')
    $self->notify ('parameter-value');
  }
}

1;
__END__
