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


package App::MathImage::Gtk2::FractionEntry;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;  # for Gtk2::EVENT_PROPAGATE()
use POSIX ();
use Locale::TextDomain 1.19 ('App-MathImage');

use Glib::Ex::ObjectBits;
use App::MathImage::Gtk2::Ex::ArrowButton;

# uncomment this to run the ### lines
#use Devel::Comments;


our $VERSION = 110;

Gtk2::Rc->parse_string (<<'HERE');
style "App__MathImage__Gtk2__FractionEntry_style" {
  xthickness = 0
  ythickness = 0
}
widget_class "*App__MathImage__Gtk2__FractionEntry*GtkAspectFrame" style:application "App__MathImage__Gtk2__FractionEntry_style"
HERE

use Glib::Object::Subclass
  'Gtk2::HBox',
  signals => {
              activate => { param_types => [ ] },
             },
  properties => [ Glib::ParamSpec->string
                  ('text',
                   __('Fraction'),
                   'The fraction as a string.',
                   '1/2',
                   Glib::G_PARAM_READWRITE),

                  do {
                    my $pspec = Gtk2::Entry->find_property('width-chars');
                    Glib::ParamSpec->int
                        ('width-chars',
                         $pspec->get_nick,
                         $pspec->get_blurb,
                         -1, POSIX::INT_MAX(),
                         6,
                         Glib::G_PARAM_READWRITE)
                      },
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### FractionEntry INIT_INSTANCE()...

  my $entry = $self->{'entry'} = Gtk2::Entry->new;
  $entry->set_text ('1/2');     # initial
  $entry->set_width_chars (6);  # initial
  $entry->set_alignment (0.5);
  $entry->signal_connect (activate => \&_do_entry_activate);
  $entry->show;

  foreach my $side (0, 1) {
    my $vbox = Gtk2::VBox->new (0, 0);
    # initial arrow width, per _do_size_allocate()
    $vbox->set_size_request ($entry->size_request->height / 2, -1);
    $self->pack_start ($vbox, 0,0,0);

    foreach my $dir ('up','down') {
      my $button = App::MathImage::Gtk2::Ex::ArrowButton->new
        (arrow_type => $dir);
      $button->{'side'} = $side;
      $button->{'direction'} = $dir;
      $button->signal_connect (clicked => \&_do_arrow_clicked);
      $button->signal_connect (scroll_event => \&_do_scroll_event);
      Glib::Ex::ObjectBits::set_property_maybe # tooltip-text new in 2.12
          ($button, tooltip_text => ($side == 0
                                     ? ($dir eq 'up'
                                        ? __('Increment the numerator.')
                                        : __('Decrement the numerator.'))
                                     : ($dir eq 'up'
                                        ? __('Increment the denominator.')
                                        : __('Decrement the denominator.'))));
      ### xt: $button->get_style->xthickness
      $vbox->pack_start ($button, 1,1,0);
    }
    $vbox->show_all;

    unless ($side) {
      $self->pack_start ($entry, 1,1,0);
    }
  }
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'text' || $pname eq 'width_chars') {
    return $self->{'entry'}->get_property($pname);
  }
  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'text' || $pname eq 'width_chars') {
    return $self->{'entry'}->set_property ($pname, $newval);
  }
  return $self->{$pname};
}

sub _do_entry_activate {
  my ($entry) = @_;
  my $self = $entry->get_ancestor (__PACKAGE__) || return;
  $self->activate;
}

sub _do_arrow_clicked {
  my ($button) = @_;
  my $self = $button->get_ancestor (__PACKAGE__) || return;
  _scroll ($self, $button, $button->{'direction'}, 1);
}

# arrow button 'scroll-event' handler
sub _do_scroll_event {
  my ($button, $event) = @_;
  my $self = $button->get_ancestor (__PACKAGE__) || return;
  if ($event->direction =~ /(up|down)/) {
    _scroll ($self, $button, $1, $event->state & 'control-mask' ? 10 : 1);
  }
  return Gtk2::EVENT_PROPAGATE;
}

my @re = (qr{^(.*?)(-?[0-9.]+)(.*)$},     # num
          qr{^(.*/.*?)(-?[0-9.]+)(.*)$},  # den
         );

sub _scroll {
  my ($self, $button, $direction, $amount) = @_;
  my $entry = $self->{'entry'};
  my $str = $entry->get_text;
  my $side = $button->{'side'};
  my ($before, $value, $after) = ($str =~ $re[$side])
    or return;
  ### $before
  ### $value
  ### $after
  if ($value =~ /(.*?)(\..*)/) {
    $value = $1;
    $after = "$2$after";
    ### $value
    ### $after
  }
  $value = ($value||0) + ($direction eq 'up' ? $amount : -$amount);
  if ($value == 0 && $side) {
    $value += ($direction eq 'up' ? 1 : -1);
  }
  $entry->set_text ($before . $value . $after);
  $self->activate;
}

sub activate {
  my ($self) = @_;
  $self->signal_emit ('activate');
}

1;
__END__
