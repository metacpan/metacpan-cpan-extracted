#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use App::MathImage::Gtk2::AboutDialog;
use Test::Weaken::Gtk2;

use Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "Test::Weaken 3 not available -- $@";

eval { require Test::Weaken::ExtraBits; 1 }
  or plan skip_all => "due to Test::Weaken::ExtraBits not available -- $@";

plan tests => 1;

# Somehow a GtkFileChooserDefault stays alive in gtk 2.20.  Is it meant to,
# to keep global settings?  In any case ignore for now.
sub my_ignore {
  my ($ref) = @_;
  return (ref($ref) =~ /::GtkFileChooserDefault$/);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = App::MathImage::Gtk2::AboutDialog->new;
         $dialog->show;
         MyTestHelpers::main_iterations();
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore => \&my_ignore,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
