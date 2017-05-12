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

package App::MathImage::Gtk2::Ex::ToolItem::ComboText;
use 5.008;
use strict;
use warnings;
use Scalar::Util;
use Gtk2;
use Glib::Ex::SignalBits;
use Gtk2::Ex::MenuView;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::ToolItem',
  signals => { add    => \&_do_add_or_remove,
               remove => \&_do_add_or_remove,
               create_menu_proxy => \&_do_create_menu_proxy,
             },
  properties => [ Glib::ParamSpec->string
                  ('overflow-mnemonic',
                   'Overflow Mnemonic',
                   'Blurb.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### ComboText FINALIZE_INSTANCE()...
  if (my $menuitem = delete $self->{'menuitem'}) {
    $menuitem->destroy;  # destroy circular MenuItem<->AccelLabel
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### ComboText SET_PROPERTY: $pname, $newval

  if ($pname eq 'overflow_mnemonic') {
    if (my $menuitem = $self->{'menuitem'}) {
      $menuitem->get_child->set_text (_mnemonic_text ($self));
    }
  }
}

sub _do_add_or_remove {
  my ($self, $child) = @_;
  ### ComboText _do_add_or_remove()...
  $self->signal_chain_from_overridden ($child);

  my $combobox = $self->get_child;
  Scalar::Util::weaken (my $weak_self = $self);
  $self->{'combobox_ids'} = $combobox && Glib::Ex::SignalIds->new
    ($combobox,
     $combobox->signal_connect (notify => \&_do_combobox_notify,
                                \$weak_self),
     $combobox->signal_connect (changed => \&_do_combobox_changed_active,
                                \$weak_self));
  if ($combobox) {
    if (my $menuview = $self->{'menuview'}) {
      $menuview->set (model => $combobox->get_model,
                      sensitive => $combobox->get_sensitive);
      _do_combobox_changed_active ($combobox, \$self);
    }
  }
  $self->rebuild_menu;
  _update_tearoff ($self);
}

sub _do_combobox_notify {
  my ($combobox, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $menuview = $self->{'menuview'} || return;
  my $pname = $pspec->get_name;
  if ($pname eq 'model') {
    $menuview->set (model => $combobox->get_model);
    _do_combobox_changed_active ($combobox, $ref_weak_self);
  } elsif ($pname eq 'sensitive') {
    $menuview->set (model => $combobox->get_sensitive);
  } elsif ($pname eq 'add_tearoffs') {
    _update_tearoff ($self);
  }
}
sub _do_combobox_changed_active {
  my ($combobox, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $menuview = $self->{'menuview'} || return;
  $menuview->set_active_iter ($combobox && $combobox->get_active_iter);
}

sub _do_create_menu_proxy {
  my ($self) = @_;
  ### ComboText _do_create_menu_proxy()...

  $self->{'menuitem'} ||= do {
    ### create new menuitem...
    my $menuitem = Gtk2::MenuItem->new_with_mnemonic (_mnemonic_text($self));
    $menuitem->set (sensitive => $self->get('sensitive'));
    if ($self->find_property('tooltip_text')) { # new in Gtk 2.12
      $menuitem->set (tooltip_text => $self->get('tooltip_text'));
    }

    require App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuView;
    my $combobox = $self->get_child;
    my $menuview = $self->{'menuview'}
      = App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuView->new
        (model => $combobox && $combobox->get_model);
    Scalar::Util::weaken ($menuview->{'toolitem'} = $self);
    _update_tearoff ($self);
    $menuitem->set_submenu ($menuview);
    $menuitem
  };

  ### proxy: "$self->{'menuitem'}"
  ### menuview: "$self->{'menuview'}"
  ### return: defined($self->get_child)
  $self->set_proxy_menu_item (__PACKAGE__, $self->{'menuitem'});
  return defined($self->get_child); # show when have combobox
}

sub _mnemonic_text {
  my ($self) = @_;
  my $str = $self->{'overflow_mnemonic'};
  if (defined $str) {
    return $str;
  } elsif (my $child_widget = $self->{'child_widget'}) {
    return Gtk2::Ex::MenuBits::mnemonic_escape ($child_widget->get_name);
  } else {
    return '';
  }
}

sub _update_tearoff {
  my ($self) = @_;
  if (my $menuview = $self->{'menuview'}) {
    my $combobox = $self->get_child;
    _menu_want_tearoff ($menuview, $combobox && $combobox->get('add_tearoffs'));
  }
}
sub _menu_want_tearoff {
  my ($menu, $want_tearoff) = @_;
  if ($want_tearoff) {
    unless (List::Util::first
            {$_->isa('Gtk2::TearoffMenuItem')}
            $menu->get_children) {
      ### add new TearoffMenuItem...
      $menu->prepend (Gtk2::TearoffMenuItem->new);
    }
  } else {
    Gtk2::Ex::ContainerBits::remove_widgets
        ($menu, grep {$_->isa('Gtk2::TearoffMenuItem')} $menu->get_children);
  }
}

1;
__END__
