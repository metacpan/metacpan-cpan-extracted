# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

package App::MathImage::Gtk2::AboutDialog;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use Locale::TextDomain ('App-MathImage');

# uncomment this to run the ### lines
#use Devel::Comments;


our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::AboutDialog';

# this applies to the whole program
my $copyright_string = __('Copyright (C) 2010, 2011 Kevin Ryde');

sub popup {
  my ($self, $parent) = @_;
  ref $self or $self = $self->instance_for_screen ($parent);
  $self->present;
}

sub INIT_INSTANCE {
  my ($self) = @_;

  # Before set_website() etc.
  # ENHANCE-ME: Maybe this belongs with global GUI inits.
   _AboutDialogBits__set_url_hook_show_uri();

  # "authors" comes out as a separate button and dialog, don't need that
  # $self->set_authors (__('Kevin Ryde'));

  $self->set_version ($VERSION);
  $self->set_copyright ($copyright_string);
  $self->set_website ('http://user42.tuxfamily.org/math-image/index.html');

  # the same as COPYING in the sources
  require Software::License::GPL_3;
  my $sl = Software::License::GPL_3->new({ holder => 'Kevin Ryde' });
  $self->set_license ($sl->license);

  $self->set_comments
    (__x("Math-Image is Free Software, distributed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.  Click on the License button below for the full text.

Math-Image is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the license for more.

You are running under: Perl {perlver}, Gtk2-Perl {gtkperlver}, Gtk {gtkver}, Glib-Perl {glibperlver}, Glib {glibver}
",
         perlver     => sprintf('%vd', $^V),
         gtkver      => join('.', Gtk2->get_version_info),
         glibver     => join('.', Glib::major_version(),
                             Glib::minor_version(),
                             Glib::micro_version()),
         gtkperlver  => Gtk2->VERSION,
         glibperlver => Glib->VERSION));

  $self->signal_connect (response => \&_do_response);
}

sub _do_response {
  my ($self, $response) = @_;

  if ($response eq 'cancel') {
    # "Close" button gives GTK_RESPONSE_CANCEL.
    # Emit 'close' same as a keyboard Esc to close, and that signal defaults
    # to raising 'delete-event', which in turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

#-----------------------------------------------------------------------------
# Had thought the default in Gtk 2.16 up was gtk_show_uri, needing no
# setting here, but that doesn't seem to be so.  It is the default in 2.24.

# =item C<_AboutDialogBits__url_hook_show_uri ($about, $url)>
#
# This function is designed for use as the hook in C<set_url_hook()> for
# About dialogs,
#
#     Gtk2::AboutDialog->set_url_hook (\&Gtk2::Ex::AboutDialogBits::url_hook_show_uri);
#
# This handler displays the C<$url> using C<Gtk2::show_uri()>, and a warning
# if that fails for some reason.
#
# Would a message dialog be better if C<show_uri()> fails?
#
sub _AboutDialogBits__url_hook_show_uri {
  my ($about, $url) = @_;
  eval { Gtk2::show_uri ($about->get_screen, $url); 1 }
    or warn "Oops, cannot open browser for ",$url;
}

# =item C<Gtk2::Ex::AboutDialogBits::set_url_hook_show_uri()>
#
# Set the C<Gtk2::AboutDialog-E<gt>set_url_hook()> to C<url_hook_show_uri()>
# so as to have C<Gtk2::show_uri()> used to follow URL links in the About
# dialog.
#
# C<set_url_hook()> is a global setting so this affects all About dialogs in
# the program, including those created from C code.  Note that per the Gtk
# docs this must be done before C<set_website()> of an About dialog.
#
sub _AboutDialogBits__set_url_hook_show_uri {
  if (Gtk2->can('show_uri')) { # new in Gtk 2.14
    Gtk2::AboutDialog->set_url_hook (\&_AboutDialogBits__url_hook_show_uri);
    return 1;
  } else {
    return 0;
  }
}

1;
__END__

# =over 4
# 
# =item C<< App::MathImage::AboutDialog->instance() >>
# 
# Return a shared instance of the AboutDialog, ready to be presented to the
# user.  The dialog close button or delete event destroys the dialog; a
# subsequent call to C<instance> creates a new one.
# 
# =back

=for stopwords AboutDialog Ryde

=head1 NAME

App::MathImage::Gtk2::AboutDialog -- about dialog module

=head1 SYNOPSIS

 use App::MathImage::Gtk2::AboutDialog;
 App::MathImage::Gtk2::AboutDialog->instance->present;

=head1 WIDGET HIERARCHY

C<App::MathImage::Gtk2::AboutDialog> is a subclass of C<Gtk2::AboutDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::AboutDialog
                App::MathImage::Gtk2::AboutDialog

=head1 SEE ALSO

L<math-image>, L<Gtk2::AboutDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
