package UI::Dialog::Screen::Menu;
###############################################################################
#  Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use 5.006;
use strict;
use warnings;
use constant { TRUE => 1, FALSE => 0 };

BEGIN {
    use vars qw($VERSION);
    $VERSION = '1.21';
}

use UI::Dialog;

# Example Usage
#
# my $screen = new UI::Dialog::Screen::Menu ( dialog => $d );
# $screen->add_menu_item( "Label", \&func );
# $screen->loop();
#

sub new {
    my ($class, %args) = @_;
    $args{__loop_active} = FALSE;
    unless (exists $args{dialog}) {
        $args{dialog} = new UI::Dialog
         (
          title => (defined $args{title}) ? $args{title} : '',
          backtitle => (defined $args{backtitle}) ? $args{backtitle} : '',
          height => (defined $args{height}) ? $args{height} : 20,
          width => (defined $args{width}) ? $args{width} : 65,
          listheight => (defined $args{listheight}) ? $args{listheight} : 5,
          order => (defined $args{order}) ? $args{order} : undef,
          PATH => (defined $args{PATH}) ? $args{PATH} : undef,
          beepbefore => (defined $args{beepbefore}) ? $args{beepbefore} : undef,
          beepafter => (defined $args{beepafter}) ? $args{beepafter} : undef,
          'trust-input' => (defined $args{'trust-input'} && $args{'trust-input'} == 1) ? 1 : 0,
         );
    }
    unless (exists $args{menu}) {
        $args{menu} = [];
    }
    return bless { %args }, $class;
}

#: $screen->add_menu_item( "Label", \&func );
#: Add an item to the menu with a label and a callback func
#
sub add_menu_item {
    my ($self,$label,$func) = @_;
    push(@{$self->{menu}},{label=>$label,func=>$func});
    return @{$self->{menu}} - 1;
}

#: @list_of_menu_items = $screen->get_menu_items();
#: Return a list of all the menu items in order. Each item is a hash
#: with a label and a func reference.
#
sub get_menu_items {
    my ($self) = @_;
    return @{$self->{menu}};
}

#: %item = $screen->del_menu_item( $index );
#: Remove a menu item and return it. The item will no longer show in the
#: list of avaliable menu items.
#
sub del_menu_item {
    my ($self,$index) = @_;
    if (defined $index && $index >= 0 && $index < @{$self->{menu}}) {
        return splice(@{$self->{menu}}, $index, 1);
    }
    return undef;
}

#: $screen->set_menu_item( $index, $label||undef, $func||undef );
#: Update a menu item's properties. If a field is "undef", no action
#: is performed on that item's field. Returns the menu_item before
#: modification.
#: Note: $index starts from 0.
#
sub set_menu_item {
    my ($self,$index,$label,$func) = @_;
    if (defined $index && $index >= 0 && $index < @{$self->{menu}}) {
        my $item = $self->{menu}->[$index];
        my $orig = { label => $item->{label}, func => $item->{func} };
        $self->{menu}->[$index]->{label} = $label if defined $label;
        $self->{menu}->[$index]->{func} = $func if defined $func;
        return $orig;
    }
    return undef;
}


#: $screen->run();
#: Blocking call, display the menu and react once. Returns 0 if cancelled,
#: returns 1 if an item was selected and the function called.
#
sub run {
    my ($self) = @_;
    my @menu_list = ();
    my $c = 1;
    foreach my $data (@{$self->{menu}}) {
        push(@menu_list,$c,$data->{label});
        $c++;
    }
    my $sel = $self->{dialog}->menu
     (
      title => (defined $self->{title}) ? $self->{title} : '',
      text => (defined $self->{text}) ? $self->{text} : '',
      list => \@menu_list
     );
    if ($self->{dialog}->state() eq "OK") {
        my $data = $self->{menu}->[$sel-1];
        my $func = $data->{func};
        &{$func}($self,$self->{dialog},$sel-1) if defined $func and ref($func) eq "CODE";
        return 1;
    } else {
        if (exists $self->{cancel}) {
            my $func = $self->{cancel};
            &{$func}($self,$self->{dialog},-1) if defined $func and ref($func) eq "CODE";
        }
    }
    return 0;
}

#: $screen->loop();
#: Blocking call, execute $screen->run() indefinitely. If run() was cancelled,
#: the loop will break.
sub loop {
    my ($self) = @_;
    $self->{__loop_active} = TRUE;
    while ($self->{__loop_active}) {
        last unless $self->run();
    }
}

#: $screen->break_loop();
#: Notify loop() to break instead of re-iterate regardless of user input.
#
sub break_loop {
    my ($self) = @_;
    $self->{__loop_active} = FALSE;
}

#: $screen->is_looping();
#: Returns TRUE if currently looping, FALSE otherwise
#
sub is_looping {
    my ($self) = @_;
    return ($self->{__loop_active}) ? TRUE : FALSE;
}

1; # END OF UI::Dialog::Screen::Menu
