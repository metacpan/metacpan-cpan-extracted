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

use App::MathImage::Gtk2::Generator;
use Test::Weaken::Gtk2 39; # v.39 for ignore_default_root_window()

use Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

# Test::Weaken 3.018 for "ignore_preds"
eval "use Test::Weaken 3.018; 1"
  or plan skip_all => "Test::Weaken 3.018 not available -- $@";

eval { require Test::Weaken::ExtraBits; 1 }
  or plan skip_all => "due to Test::Weaken::ExtraBits not available -- $@";

plan tests => 2;

#------------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $root = Gtk2::Gdk->get_default_root_window;
         return App::MathImage::Gtk2::Generator->new (window => $root);
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore_object => App::MathImage::Generator::default_options()->{'path_parameters'},
       ignore_preds => [ \&Test::Weaken::Gtk2::ignore_default_root_window,
                         \&Test::Weaken::ExtraBits::ignore_global_functions,
                       ],
     });
  is ($leaks, undef, 'deep garbage collection - gen on root window');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

#------------------------------------------------------------------------------

{
  require App::MathImage::Gtk2::Drawing;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $root = Gtk2::Gdk->get_default_root_window;
         my $drawing = App::MathImage::Gtk2::Drawing->new;
         my $gen = App::MathImage::Gtk2::Generator->new (window => $root,
                                                         widget => $drawing);
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore_object => App::MathImage::Generator::default_options()->{'path_parameters'},
       ignore_preds => [ \&Test::Weaken::Gtk2::ignore_default_root_window,
                         \&Test::Weaken::ExtraBits::ignore_global_functions,
                       ],
     });
  is ($leaks, undef,
      'deep garbage collection - gen on Drawing and root window');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}



#------------------------------------------------------------------------------

# {
#   require App::MathImage::Gtk2::Drawing;
#   my $toplevel = Gtk2::Window->new;
#   $toplevel->set_size_request (10,10);
#   my $drawing = App::MathImage::Gtk2::Drawing->new (values => 'All',
#                                                     scale => 5);
#   $toplevel->add ($drawing);
#   $toplevel->show_all;
#   my $values_parameters = $drawing->get('values_parameters') || {};
# 
#   my $leaks = Test::Weaken::leaks
#     ({ constructor => sub {
#          $drawing->start_drawing_window ($drawing->window);
#          my $prev = $drawing->{'generator'};
#          $drawing->start_drawing_window ($drawing->window);
#          return $prev;
#        },
#        destructor => sub {
#          my ($ref) = @_;
#          MyTestHelpers::diag ('gen gtkmain isweak ',
#                               Scalar::Util::isweak($drawing->{'gen_object'}->{'gtkmain'}));
#          MyTestHelpers::diag ('gen widget isweak ',
#                               Scalar::Util::isweak($drawing->{'gen_object'}->{'widget'}));
#          delete $drawing->{'gen_object'};
#        },
#        contents => \&Test::Weaken::Gtk2::contents_container,
#        ignore => sub {
#          my ($ref) = @_;
#          return ($ref == $drawing
#                  || $ref == $drawing->{'widgetcursor'}
#                  || $ref == ($drawing->{'path_parameters'}||0)
#                  || $ref == ($drawing->{'values_parameters'}||0)
#                  || $ref == App::MathImage::Generator::default_options->{'path_parameters'}
#                  || $ref == $drawing->window
#                  || $ref == $drawing->{'vadjustment'}
#                  || $ref == $drawing->{'hadjustment'}
#                  || $ref == $toplevel);
#        },
#      });
#   is ($leaks, undef, 'Test::Weaken deep garbage collection');
#   MyTestHelpers::test_weaken_show_leaks($leaks);
# }

exit 0;
