#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

use 5.004;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;

my $test_count = (tests => 5)[1];
plan tests => $test_count;

if (! eval { require Image::BMP; 1 }) {
  MyTestHelpers::diag ('Image::BMP not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Image::BMP not available', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("Image::BMP VERSION ",Image::BMP->VERSION);

require App::MathImage::Image::Base::BMP;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 110;
ok ($App::MathImage::Image::Base::BMP::VERSION, $want_version,
    'VERSION variable');
ok (App::MathImage::Image::Base::BMP->VERSION, $want_version,
    'VERSION class method');

ok (eval { App::MathImage::Image::Base::BMP->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { App::MathImage::Image::Base::BMP->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


#------------------------------------------------------------------------------
# new() clone image, and resize

# Not supported yet ...
# {
#   my $i1 = App::MathImage::Image::Base::BMP->new
#     (-width => 11, -height => 22);
#   my $i2 = $i1->new;
#   # no resize yet ...
#   # $i2->set (-width => 33, -height => 44);
# 
#   ok ($i1->get('-width'), 11, 'clone original width');
#   ok ($i1->get('-height'), 22, 'clone original height');
#   ok ($i2->get('-width'), 11, 'clone new width');
#   ok ($i2->get('-height'), 22, 'clone new height');
#   ok ($i1->get('-imagebmp') != $i2->get('-imagebmp'),
#       1,
#       'cloned -imagebmp object different');
# }

#------------------------------------------------------------------------------
# xy

# only to an opened file
# {
#   my $image = App::MathImage::Image::Base::BMP->new
#     (-width => 20,
#      -height => 10);
#   $image->xy (2,2, '#000');
#   ok ($image->xy (2,2), '#000000', 'xy() #000');
# 
#   $image->xy (3,3, "#010203");
#   ok ($image->xy (3,3), '#010203', 'xy() rgb');
# }

# no resize yet
# {
#   my $image = App::MathImage::Image::Base::BMP->new
#     (-width => 2, -height => 2);
#   $image->set(-width => 20, -height => 20);
# 
#   $image->xy (10,10, 'white');
#   ok ($image->xy (10,10), '#FFFFFF', 'xy() in resize');
# }


#------------------------------------------------------------------------------
# load() errors

my $temp_filename;
BEGIN {
  $temp_filename = "tempfile.bmp";
}
MyTestHelpers::diag ("Tempfile $temp_filename");
unlink $temp_filename;
ok (! -e $temp_filename,
    1,
    "removed any existing $temp_filename");
END {
  MyTestHelpers::diag ("Remove tempfile $temp_filename");
  if (! unlink $temp_filename) {
    if (-e $temp_filename) {
      MyTestHelpers::diag("Oops, cannot remove $temp_filename: $!");
    }
  }
}

# -file setting dodginess  ....
# {
#   ### new() no such file ...
#   my $eval_ok = 0;
#   my $ret = eval {
#     my $image = App::MathImage::Image::Base::BMP->new (-file => $temp_filename);
#     $eval_ok = 1;
#     $image
#   };
#   my $err = $@;
#   ### $eval_ok
#   ### $err
#   ok ($eval_ok, 0, 'new() error for no file - doesn\'t reach end');
#   ok (! defined $ret, 1, 'new() error for no file - return undef');
#   ok ($err,
#       '/does not exist/',
#       'new() error for no file - error string "Cannot"');
# }
# {
#   ### load() no such file ...
#   my $eval_ok = 0;
#   my $image = App::MathImage::Image::Base::BMP->new;
#   my $ret = eval {
#     $image->load ($temp_filename);
#     $eval_ok = 1;
#     $image
#   };
#   my $err = $@;
#   ### $eval_ok
#   ### $err
#   # diag "load() err is \"",$err,"\"";
#   ok ($eval_ok, 0, 'load() error for no file - doesn\'t reach end');
#   ok (! defined $ret, 1, 'load() error for no file - return undef');
#   ok ($err,
#       '/does not exist/',
#       'load() error for no file - error string "Cannot"');
# }

#-----------------------------------------------------------------------------
# save() errors

# {
#   my $eval_ok = 0;
#   my $nosuchdir = "no/such/directory/foo.bmp";
#   my $image = App::MathImage::Image::Base::BMP->new (-width => 1,
#                                                      -height => 1);
#   my $ret = eval {
#     $image->save ($nosuchdir);
#     $eval_ok = 1;
#     $image
#   };
#   my $err = $@;
#   ### $err
#   # diag "save() err is \"",$err,"\"";
#   ok ($eval_ok, 0, 'save() error for no dir - doesn\'t reach end');
#   ok (! defined $ret, 1, 'save() error for no dir - return undef');
#   ok ($err, '/error/', 'save() error for no dir - error string');
# }


#-----------------------------------------------------------------------------
# save() / load()

# {
#   require Image::BMP;
#   my $bmp_obj = Image::BMP->new (20, 10);
#   ok ($bmp_obj->width, 20);
#   ok ($bmp_obj->height, 10);
#   my $image = App::MathImage::Image::Base::BMP->new
#     (-imagebmp => $bmp_obj);
#   $image->save ($temp_filename);
#   ok (-e $temp_filename,
#       1,
#       "save() to $temp_filename, -e exists");
#   ok (-s $temp_filename > 0,
#       1,
#       "save() to $temp_filename, -s non-empty");
# }
# {
#   my $image = App::MathImage::Image::Base::BMP->new (-file => $temp_filename);
# }
# {
#   my $image = App::MathImage::Image::Base::BMP->new;
#   $image->load ($temp_filename);
# }


#------------------------------------------------------------------------------
# check_image

# cannot draw into new image ???
# {
#   my $image = App::MathImage::Image::Base::BMP->new
#     (-width  => 20,
#      -height => 10);
#   ok ($image->get('-width'), 20);
#   ok ($image->get('-height'), 10);
# 
#   $image->xy (0,0, '#FFFF00000000');
#   ok ($image->xy(0,0), '#FF0000');
# 
#   require MyTestImageBase;
#   $MyTestImageBase::black = '#000000';
#   $MyTestImageBase::white = '#FFFFFF';
#   $MyTestImageBase::black = '#000000';
#   $MyTestImageBase::white = '#FFFFFF';
#   MyTestImageBase::check_image ($image);
#   MyTestImageBase::check_diamond ($image);
# }

exit 0;
