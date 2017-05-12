# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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


# Maybe:
#
# $s = Gtk2::Ex::SyncCall->new
# $s->sync_call (subr, arg)
# $s->sync_and_idle (priority, subr, arg)
# $s->sync_redraw (widget)
# $s->sync_method (widget, method, millisecs)



package App::MathImage::Gtk1::Ex::SyncCall;
use 5.004;
use strict;
use warnings;
use Carp;
use App::MathImage::Gtk1::Ex::SignalIds;

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
#use Devel::Comments;

my $sync_call_atom;

my @sync_list;
my $sync_widget;
my $signal_ids;

sub sync {
  my ($class, $widget, $callback, $userdata) = @_;
  ### SyncCall sync() ...

  my $win = $widget->window
    || croak __PACKAGE__.'->sync(): widget not realized';

  if (! $sync_widget) {
    $sync_widget = $widget;

    $sync_widget->add_events ('property-change-mask');
    ### widget add_events gives: $widget->window && $widget->window->get_events
    #### window XID: $widget->window && $widget->window->can('XID') && $widget->window->XID

    $signal_ids = App::MathImage::Gtk1::Ex::SignalIds->new
      ($sync_widget,
       $widget->signal_connect (property_notify_event =>
                                \&_do_property_notify),
       $widget->signal_connect (unrealize => \&_do_widget_destroy),
       $widget->signal_connect (destroy   => \&_do_widget_destroy));
  }

  my $self = { callback => $callback,
               userdata => $userdata };
  push @sync_list, $self;

  if (@sync_list == 1) {
    # first entry in sync_list initiates the sync
    $sync_call_atom ||= Gtk::Gdk::Atom->intern (__PACKAGE__);
    ### property_change of: $sync_call_atom
    $win->property_change ($sync_call_atom,
                           Gtk::Gdk::Atom->intern('STRING'),
                           8,            # format
                           'append',     # mode
                           '',           # data
                           0);           # nelements
  }
  return $self;
}

# 'property-notify-event' signal on sync widget
sub _do_property_notify {
  my ($widget, $event) = @_;
  ### SyncCall property-notify handler: $event

  # note, no overloaded != until Gtk-Perl 1.183, only == prior to that
  if ($event->{'atom'} == $sync_call_atom) {
    _call_all ();
  }
  # even though $sync_call_atom is supposed to be for us alone, propagate it
  # anyway in case someone else is monitoring what happens
  return 0;  # EVENT_PROPAGATE
}

# 'unrealize' or 'destroy' signal on the sync widget
sub _do_widget_destroy {
  my ($widget) = @_;
  _call_all ();
}

sub _call_all {
  my ($data) = @_;
  my @list = @sync_list;
  @sync_list = ();
  foreach my $self (@list) {
    $self->{'callback'}->($self->{'userdata'});
  }
}

1;
__END__
