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


package App::MathImage::Gtk2::Params::Float::Expression;
use 5.008;
use strict;
use warnings;
use Carp;
use POSIX ();
use Glib;
use Gtk2;
use Glib::Ex::ObjectBits 'set_property_maybe';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Gtk2::Ex::ToolItem::OverflowToDialog 41; # v.41 fix overflow-mnemonic
use Glib::Object::Subclass
  'Gtk2::Ex::ToolItem::OverflowToDialog',
  properties => [ Glib::ParamSpec->double
                  ('parameter_value',
                   'Parameter Value',
                   'Blurb.',
                   POSIX::INT_MIN(), POSIX::INT_MAX(),
                   0,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('parameter-info',
                   'Parameter Info',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $entry = Gtk2::Entry->new;
  Scalar::Util::weaken (my $weak_self = $self);
  $entry->signal_connect (activate => \&_do_entry_activate, \$weak_self);
  $entry->show;
  $self->add ($entry);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'parameter_value') {
    my $entry = $self->get('child-widget') || return undef;
    my $expression = $entry->get_text;
    if (eval { require Math::Symbolic;
               require Math::Symbolic::Constant;
             }) {
      my $tree = Math::Symbolic->parse_from_string($expression);
      if (! defined $tree) {
        carp "Cannot parse expression: $expression";
        return 0;
      }
      # ENHANCE-ME: contfrac(2,2,2,2...) func
      $tree->implement (phi => Math::Symbolic::Constant->new((1 + sqrt(5)) / 2),
                        e => Math::Symbolic::Constant->euler,
                        pi => Math::Symbolic::Constant->pi,
                        gam => Math::Symbolic::Constant->new(0.5772156649015328606065120),
                       );
      my @vars = $tree->signature;
      if (@vars) {
        carp "Not a constant expression: $expression";
        return 0;
      }
      return $tree->value;
    }
    return $expression;

  } else {
    return $self->{$pname};
  }
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Float SET_PROPERTY: $pname

  if ($pname eq 'parameter_value') {
    if (my $entry = $self->get('child-widget')) {
      if (! defined $newval) { $newval = ''; }
      $entry->set_text ($newval);
    }

  } else {
    my $oldval = $self->{$pname};
    $self->{$pname} = $newval;

    if (my $entry = $self->get('child-widget')) {
      if (! $oldval) {
        $entry->set_text (defined $newval->{'default_expression'}
                          ? $newval->{'default_expression'}
                          : $newval->{'default'});
      }
      $entry->set (width_chars => $newval->{'width'} || 5);
    }

    my $display = ($newval->{'display'} || $newval->{'name'});
    $self->set (overflow_mnemonic =>
                Gtk2::Ex::MenuBits::mnemonic_escape($display));

    set_property_maybe ($self, # tooltip-text new in 2.12
                        tooltip_text => $newval->{'description'});
  }
}

sub _do_entry_activate {
  my ($entry, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->notify ('parameter-value');
}

1;
__END__
