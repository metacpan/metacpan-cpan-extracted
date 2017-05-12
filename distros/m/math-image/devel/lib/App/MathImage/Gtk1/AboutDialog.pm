# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk1::AboutDialog;
use 5.004;
use strict;
use Scalar::Util;
use Locale::TextDomain ('App-MathImage');

use vars '$VERSION','@ISA';
$VERSION = 110;

# uncomment this to run the ### lines
# use Smart::Comments;


sub popup {
  my ($self) = @_;
  ref $self or $self = $self->instance;
  if (my $win = $self->window) {
    $win->raise;
  } else {
    $self->show;
  }
}

# Maybe:
#
# =over 4
# 
# =item C<< App::MathImage::AboutDialog->instance() >>
# 
# Return a shared instance of the AboutDialog, ready to be presented to the
# user.  The dialog close button or delete event destroys the dialog; a
# subsequent call to C<instance> creates a new one.
# 
# =back
#
my $instance;
sub instance {
  my ($class) = @_;
  ### AboutDialog instance(): $class
  ### $instance
  return $instance || $class->new;
}

use constant::defer init => sub {
  ### AboutDialog init(): @_
  require Gtk;
  Gtk->init;
  @ISA = ('Gtk::Dialog');
  Gtk::Dialog->register_subtype(__PACKAGE__);
  return undef;
};
sub new {
  ### AboutDialog new(): @_
  init();
  return Gtk::Widget->new(@_);
}

sub GTK_CLASS_INIT {
  my ($class) = @_;
  ### AboutDialog GTK_CLASS_INIT() ...
}

sub GTK_OBJECT_INIT {
  my ($self) = @_;
  ### AboutDialog GTK_OBJECT_INIT() ...

  $self->set_title(__('Math-Image: About'));

  my $vbox = $self->vbox;

  {
    my $label = Gtk::Label->new
      (__x("Math-Image version {version}\n\n",
           version  => $self->VERSION));
    $label->set_justify ('center');
    $vbox->pack_start ($label, 1,1,0);
  }

  {
    my $label = Gtk::Label->new
      (__x("Copyright (C) 2010, 2011 Kevin Ryde

Math-Image is Free Software, distributed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.  Click on the License button below for the full text.

Math-Image is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the license for more.

You are running under: Perl {perlver}, Gtk-Perl {gtkperlver}, Gtk {gtkver}

http://user42.tuxfamily.org/math-image/index.html
",
           perlver     => sprintf('%vd', $^V),
           gtkver      => join('.', Gtk->major_version,
                               Gtk->minor_version,
                               Gtk->micro_version),
           gtkperlver  => Gtk->VERSION));
    $label->set_line_wrap (1);
    $vbox->pack_start ($label, 1,1,0);
  }

  my $button = Gtk::Button->new("Close");
  $button->signal_connect (clicked => \&_do_button_close);
  $button->can_default(1);
  $self->action_area->pack_start($button, 0,0,0);
  $button->grab_default;
  $button->show;
  $self->show_all;

  Scalar::Util::weaken ($instance = $self);
}

sub _do_button_close {
  my ($button) = @_;
  my $self = $button->get_ancestor (__PACKAGE__) || return;
  $self->destroy;
}

1;
__END__

=for stopwords AboutDialog Ryde

=head1 NAME

App::MathImage::Gtk1::AboutDialog -- about dialog module

=head1 SYNOPSIS

 use App::MathImage::Gtk1::AboutDialog;
 my $dialog = App::MathImage::Gtk1::AboutDialog->new;
 $dialog->show;

=head1 WIDGET HIERARCHY

C<App::MathImage::Gtk1::AboutDialog> is a subclass of C<Gtk::Dialog>.

    Gtk::Widget
      Gtk::Container
        Gtk::Bin
          Gtk::Window
            Gtk::Dialog
              App::MathImage::Gtk1::AboutDialog

=head1 SEE ALSO

L<math-image>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut
