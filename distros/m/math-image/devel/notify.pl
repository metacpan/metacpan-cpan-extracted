#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use strict;
use warnings;
use Glib;
use Gtk2 '-init';

# uncomment this to run the ### lines
use Smart::Comments;

package Foo;
use Glib::Object::Subclass 'Gtk2::Window',
  signals => { notify => \&_do_notify,
               mysig =>
               { param_types   => ['Glib::Object',
                                  ],
                 flags         => ['action','run-last'],
               },

             },
  properties => [ Glib::ParamSpec->string
                  ('one',
                   'One',
                   'Blurb.',
                   'default',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('two',
                   'Two',
                   'Blurb.',
                   'default',
                   Glib::G_PARAM_READWRITE),

                ];

sub _do_notify {
  my ($self, $pspec) = @_;
  ### notify: $pspec->get_name

  $self->signal_chain_from_overridden ($pspec);

  if ($pspec->get_name eq 'one') {
    my $label = Gtk2::Label->new('hi');
    $self->add($label);
    $self->set_title ('fdjk');
    $self->signal_emit(mysig => $self);
    $self->notify('two');
  }
}


package main;
my $foo = Foo->new; #  (type => 'toplevel');
$foo->set(one => '111');
