#!/usr/bin/perl -w

# Copyright 2011, 2012, 2024 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

## no critic (RequireUseStrict, RequireUseWarnings)
use Test::Without::GD;

use 5.004;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

my $test_count = (tests => 9)[1];
plan tests => $test_count;

my $have_GD = eval { require GD; 1 };
if (! $have_GD) {
  MyTestHelpers::diag ("GD not available -- $@");
  foreach (1 .. $test_count) {
    skip ('GD not available', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("GD vesion: ",GD->VERSION);
MyTestHelpers::diag ("  newFromXpm exists: ",
                     exists(&GD::Image::newFromXpm) ? 'yes' : 'no',
                     ", prototype: ",prototype('GD::Image::newFromXpm'));

require Test::Without::GD;

#------------------------------------------------------------------------------

{
  my $warn_handler_before = $SIG{'__WARN__'};
  ### $warn_handler_before
  Test::Without::GD->without_xpm;
  my $warn_handler_after = $SIG{'__WARN__'};
  ok ($warn_handler_before == $warn_handler_after, 1,
      'without_xpm() leaves SIG __WARN__ unchanged');

  my $image = GD::Image->newFromXpm('t/GD.xpm');
  my $err = $@;
  MyTestHelpers::diag ("expected error newFromXpm() -- $err");

  ok ($image, undef);
  ok (defined $err && $err =~ /libgd was not built with xpm support/,
      1);
}

#------------------------------------------------------------------------------

{
  Test::Without::GD->without_gifanim;
  my $image = GD::Image->new(100,100);

  {
    my $success = eval { $image->gifanimbegin(); 1 };
    my $err = $@;
    MyTestHelpers::diag ("expected error gifanimbegin() -- $err");
    ok ($success, undef);
    ok (defined $err && $err =~ /or higher required for animated GIF support/,
        1);
  }
  {
    my $success = eval { $image->gifanimadd(); 1 };
    my $err = $@;
    MyTestHelpers::diag ("expected error gifanimadd() -- $err");
    ok ($success, undef);
    ok (defined $err && $err =~ /or higher required for animated GIF support/,
        1);
  }
  {
    my $success = eval { $image->gifanimend(); 1 };
    my $err = $@;
    MyTestHelpers::diag ("expected error gifanimend() -- $err");
    ok ($success, undef);
    ok (defined $err && $err =~ /or higher required for animated GIF support/,
        1);
  }
}

exit 0;
