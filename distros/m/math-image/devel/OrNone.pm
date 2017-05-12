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

package App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone;
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
use Smart::Comments;

our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::CheckMenuItem',
  signals => { activate => \&_do_activate },
  properties => [ Glib::ParamSpec->object ('group',
                                           'group',
                                           'Blurb.',
                                           'Gtk2::RadioMenuItem',
                                           'writable') ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_draw_as_radio (1);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### OrNone SET_PROPERTY(): "$newval"
  my @group_list = ($self);
  Scalar::Util::weaken ($group_list[0]);
  $self->{'group_list'} = \@group_list;
  $self->set_group ($newval);
}
sub get_group {
  my ($self) = @_;
  return grep {defined} @{$self->{'group_list'}};
}

sub set_group {
  my ($self, $group_widget) = @_;
  ### OrNone set_group()

  my $old_group_list = $self->{'group_list'};
  @$old_group_list = grep {defined && $_ != $self} @$old_group_list;

  my $new_group_list = $self->{'group_list'}
    = ($group_widget ? $group_widget->{'group_list'} : []);
  push @$new_group_list, $self;
  Scalar::Util::weaken ($new_group_list->[-1]);

  $self->notify('group');
}

sub _do_activate {
  my ($self) = @_;
  $self->signal_chain_from_overridden;
  if ($self->get_active) {
    foreach my $other (@{$self->{'group_list'}}) {
      if (defined $other && $other != $self) {
        $other->set_active(0);
      }
    }
  }
}


sub new {
  my ($class, $group_widget_or_list, $label) = @_;
  my $self = $class->Glib::Object::new (label => $label);
  if (ref $group_widget_or_list eq 'ARRAY') {
    $group_widget_or_list = $group_widget_or_list->[0];
  }
  $self->set_group ($group_widget_or_list);
  return $self;
}
*new_with_label = \&new;
*new_from_widget = \&new;
*new_with_label_from_widget = \&new;

sub new_with_mnemonic {
  my ($class, $group_widget_or_list, $label) = @_;
  my $self = $class->Glib::Object::new (label => $label,
                                        use_underline => 1);
  if (ref $group_widget_or_list eq 'ARRAY') {
    $group_widget_or_list = $group_widget_or_list->[0];
  }
  $self->set_group ($group_widget_or_list);
  return $self;
}
*new_with_mnemonic_from_widget = \&new_with_mnemonic;

1;
__END__

=for stopwords Math-Image Ryde

=head1 NAME

App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone -- radio menu item allowing none set

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone;
 my $menuitem = App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone->new;

=head1 WIDGET HIERARCHY

C<App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone> is a subclass of
C<Gtk2::CheckMenuItem>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Item
            Gtk2::MenuItem
              Gtk2::CheckMenuItem
                App::MathImage::Gtk2::Ex::RadioMenuItem::OrNone

=head1 SEE ALSO

L<Gtk2::RadioMenuItem>

=head1 LICENSE

Copyright 2010 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut


# use Glib::Object::Subclass
#   'Gtk2::RadioMenuItem',
#   signals => { activate => \&_do_activate },
#   properties
#   => [ Glib::ParamSpec->can('override')
#        ? (Glib::ParamSpec->override
#           ('group', Gtk2::RadioMenuItem->find_property ('group')))
#        : (Glib::ParamSpec->object ('group',
#                                    'group',
#                                    'Blurb.',
#                                    'Gtk2::RadioMenuItem',
#                                    'writable')),
#      ];
# 
# 
# sub SET_PROPERTY {
#   my ($self, $pspec, $newval) = @_;
#   ### OrNone SET_PROPERTY(): "$newval"
#   $self->set_group ($newval);
# }
# sub set_group {
#   my ($self, $group) = @_;
#   ### OrNone set_group(): $self->{'activate_in_progress'}
#   my $active = $self->get_active;
#   $self->SUPER::set_group ($group);
#   $self->set_active ($active);
# }
# 
# sub _do_activate {
#   my ($self) = @_;
#   ### OrNone _do_activate(): $self->{'activate_in_progress'}
#   if (! $self->{'activate_in_progress'}) {
#     local $self->{'activate_in_progress'} = 1;
#     my $active = $self->get_active;
#     ### before: $active
#     $self->signal_chain_from_overridden;
#     ### chain: $self->get_active
#     $self->Gtk2::CheckMenuItem::set_active (! $active);
#     ### restored: $self->get_active
#   }
# }
# 
# 
# sub new {
#   my ($class, $group_widget_or_list, $label) = @_;
#   my $self = $class->Glib::Object::new (label => $label);
#   if (ref $group_widget_or_list eq 'ARRAY') {
#     $group_widget_or_list = $group_widget_or_list->[0];
#   }
#   $self->set_group ($group_widget_or_list);
#   return $self;
# }
# *new_with_label = \&new;
# *new_from_widget = \&new;
# *new_with_label_from_widget = \&new;
# 
# sub new_with_mnemonic {
#   my ($class, $group_widget_or_list, $label) = @_;
#   my $self = $class->Glib::Object::new (label => $label,
#                                         use_underline => 1);
#   if (ref $group_widget_or_list eq 'ARRAY') {
#     $group_widget_or_list = $group_widget_or_list->[0];
#   }
#   $self->set_group ($group_widget_or_list);
#   return $self;
# }
# *new_with_mnemonic_from_widget = \&new_with_mnemonic;
