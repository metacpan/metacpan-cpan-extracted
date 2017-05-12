#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use Test::More tests => 78;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require App::MathImage;
require POSIX;
POSIX::setlocale(POSIX::LC_ALL(), 'C'); # no message translations


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 110;
  is ($App::MathImage::VERSION, $want_version, 'VERSION variable');
  is (App::MathImage->VERSION,  $want_version, 'VERSION class method');

  ok (eval { App::MathImage->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::MathImage->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

foreach my $elem
  (
   [ ['--version'] ],
   [ ['--help'] ],
   [ ['--verbose', '--version'] ],

   # per math-image POD docs
   [ ['--text', '--primes'] ],
   [ ['--text', '--twin'] ],
   [ ['--text', '--twin1'] ],
   [ ['--text', '--twin2'] ],
   [ ['--text', '--semi-primes'] ],
   [ ['--text', '--semi-primes-odd'] ],
   [ ['--text', '--squares'] ],
   [ ['--text', '--pronic'] ],
   [ ['--text', '--triangular'] ],
   [ ['--text', '--polygonal=7'] ],
   [ ['--text', '--pentagonal'] ],
   [ ['--text', '--cubes'] ],
   [ ['--text', '--tetrahedral'] ],
   [ ['--text', '--fibonacci'] ],
   [ ['--text', '--perrin'] ],
   # [ ['--text', '--padovan'] ], # not ready yet
   [ ['--text', '--fraction=7/23'] ],
   [ ['--text', '--fraction=1.123'] ],
   [ ['--text', '--all'] ],
   [ ['--text', '--odd'] ],
   [ ['--text', '--even'] ],
   [ ['--text', '--expression=i**2 + 2*i + 1'] ],

   [ ['--text', '--sacks'],
     modules => ['Math::PlanePath::SacksSpiral'] ],
   [ ['--text', '--vogel'],
     modules => ['Math::PlanePath::VogelFloret'] ],

   [ ['--text'] ],
   [ ['--text', '--scale=5'] ],
   [ ['--text', '--size=10'] ],
   [ ['--text', '--size=10x20'] ],
   # [ ['--text', '--random'] ],  # could need all modules

   [ ['--output=numbers'] ],
   [ ['--output=list'] ],
   [ ['--xpm'],
     modules => ['Image::Xpm'] ],

   # png is only actually optional in GD
   [ ['--png'],
     modules => ['Image::Base::PNGwriter'] ],
   [ ['--png','--module=PNGwriter'],
     modules => ['Image::Base::PNGwriter'] ],
   [ ['--png','--module=Magick'],
     modules => ['Image::Base::Magick'] ],
   [ ['--png','--module=Gtk2'],
     # always have Image::Base::Gtk2::Gdk::Pixbuf
   ],

   # [ ['--prima'],         module => 'Prima' ],
  ) {
 SKIP: {
    my ($argv, %options) = @$elem;
    foreach my $module (@{$options{'modules'}}) {
      ### load module: $module
      if (! eval "require $module") {
        skip "due to $module not available: $@", 2;
      }
    }
    local @ARGV = @$argv;
    diag "command_line() ",join(' ',@ARGV);
    local *STDOUT;
    require File::Spec;
    my $devnull = File::Spec->devnull;
    open STDOUT, '>', $devnull
      or die "Cannot open $devnull";

    # class method
    is (App::MathImage->command_line,
        0,
        "command ".join(' ',@$argv));

    # object method
    @ARGV = @$argv;
    my $mi = App::MathImage->new;
    is ($mi->command_line,
        0,
        "command ".join(' ',@$argv));
  }
  }

exit 0;
