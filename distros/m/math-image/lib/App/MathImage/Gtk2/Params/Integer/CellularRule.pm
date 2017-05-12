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


package App::MathImage::Gtk2::Params::Integer::CellularRule;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain 1.19 ('App-MathImage');

our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


use Glib::Object::Subclass
  'App::MathImage::Gtk2::Params::Integer';

use constant tooltip_extra => 'See mouse button-3 menu to flip to the mirror image rule.';

sub INIT_INSTANCE {
  my ($self) = @_;
  ### Integer-CellularRule INIT_INSTANCE() ...

  my $weak_self = $self;
  Scalar::Util::weaken($self);

  my $spin = $self->get('child-widget');
  ### $spin
  $spin->signal_connect (populate_popup => \&_do_populate_popup,
                         \$weak_self);
}

sub _do_populate_popup {
  my ($spin, $menu) = @_;
  ### Integer-CellularRule _do_populate_popup() ...
  my $self = $spin->get_ancestor(__PACKAGE__) || return;
  my $weak_self = $self;
  Scalar::Util::weaken($self);

  my $pos = 0;
  {
    my $item = Gtk2::MenuItem->new_with_mnemonic (__('Mirror Rule'));
    $item->signal_connect (activate => \&_do_mirror, \$weak_self);
    $item->show;
    $menu->insert ($item, $pos++);
  }
  {
    my $item = Gtk2::SeparatorMenuItem->new;
    $item->show;
    $menu->insert ($item, $pos++);
  }
  # {
  #   my $item = Gtk2::MenuItem->new_with_mnemonic (__('Invert Rule'));
  #   $menu->insert ($item, 1);
  #   $item->signal_connect (activate => \&_do_invert, \$weak_self);
  #   $item->show;
  # }
}

# 111
# 110  <---+  0x40
# 101      |
# 100  <-  |  0x10
# 011  <---+  0x08
# 010
# 001  <-     0x02
# 000
sub _do_mirror {
  my ($item, $ref_weak_self) = @_;
  ### Integer-CellularRule  _do_mirror() ...
  my $self = $$ref_weak_self || return;
  my $spin = $self->get('child-widget') || return;
  $spin->set_value (_rule_mirror ($spin->get_value));
}
sub _rule_mirror {
  my ($rule) = @_;
  return (($rule & 0xA5)
          | (($rule & 0x02) << 3) | (($rule & 0x10) >> 3)
          | (($rule & 0x08) << 3) | (($rule & 0x40) >> 3));
}

sub _do_invert {
  my ($item, $ref_weak_self) = @_;
  ### Integer-CellularRule  _do_mirror() ...
  my $self = $$ref_weak_self || return;
  my $spin = $self->get('child-widget') || return;
  $spin->set_value ($spin->get_value ^ 0xFE);
}

1;
__END__
