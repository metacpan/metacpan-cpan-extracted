#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use List::Util;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
use Devel::Comments;

eval { require Gtk; 1 }
  or plan skip_all => "Gtk 1.x not available -- $@";
Gtk->init_check
  or plan skip_all => 'due to no DISPLAY available';

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "Test::Weaken 3 not available -- $@";

eval "use Test::Weaken::ExtraBits; 1"
  or plan skip_all => "due to Test::Weaken::ExtraBits not available -- $@";

plan tests => 1;

require App::MathImage::Gtk1::Main;

#-----------------------------------------------------------------------------
# Test::Weaken

require Test::Weaken::Gtk2;

sub my_ignore {
  my ($ref) = @_;

  foreach my $aref ((Math::NumSeq::Primes->can('parameter_info_array')
                     && Math::NumSeq::Primes->parameter_info_array),
                    (Math::PlanePath::SquareSpiral->can('parameter_info_array')
                     && Math::PlanePath::SquareSpiral->parameter_info_array)) {
    next unless $aref;
    if ($ref == $aref) {
      return 1;
    }
    if (List::Util::first {$ref == $_} @$aref) {
      return 1;
    }
  }
  return 0;
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $main = App::MathImage::Gtk1::Main->new;
         $main->show_all;
         return $main;
       },
       destructor => sub {
         my ($ref) = @_;
         $ref->destroy;
       },
       contents => sub {
         my ($ref) = @_;
         require Scalar::Util;
         if (Scalar::Util::blessed($ref) && $ref->isa('Gtk::Container')) {
           return $ref->children;
         }
         return;
       },
       ignore => \&my_ignore,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');

  # {
  #   my $unfreed = $leaks->unfreed_proberefs;
  #   my $label = $unfreed->[0];
  #   ### text: $label->get
  # }
  MyTestHelpers::test_weaken_show_leaks($leaks);

}

# {
#   my $leaks = Test::Weaken::leaks
#     ({ constructor => sub {
#          my $widget = Gtk::Label->new;
#          my $adj = Gtk::Label->new;
#          print "$widget\n";
#          print "$adj\n";
#          # = $widget->{'adj'}
#          # Gtk::Adjustment->new (0,0,0,0,0,0);
#          return [$widget,$adj];
#        },
#        destructor => \&Test::Weaken::Gtk2::destructor_destroy,
#        contents => \&Test::Weaken::Gtk2::contents_container,
#        ignore => \&my_ignore,
#      });
#   is ($leaks, undef, 'Test::Weaken deep garbage collection');
#   MyTestHelpers::test_weaken_show_leaks($leaks);
# }

exit 0;
