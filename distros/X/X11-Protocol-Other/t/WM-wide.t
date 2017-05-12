#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# Tests involving perl 5.8 wide chars.


BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 5)[1];
plan tests => $test_count;

require X11::Protocol::WM;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

if ($] < 5.008) {
  MyTestHelpers::diag ("This not applicable in perl < 5.8.0, have perl $]");
  foreach (1 .. $test_count) {
    skip ("not perl 5.8", 1, 1);
  }
  exit 0;
}

# should have Encode.pm in perl 5.8 and up, but allow for it hidden by
# Module::Mask::Deps during development testing
unless (eval { require Encode }) {
  my $err = $@;
  MyTestHelpers::diag ("Encode module not available: ",$err);
  foreach (1 .. $test_count) {
    skip ("no Encode module", 1, 1);
  }
  exit 0;
}

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  MyTestHelpers::diag ('No DISPLAY set');
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("DISPLAY $display");

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ("Cannot connect to X server -- $@");
  foreach (1 .. $test_count) {
    skip ("Cannot connect to X server", 1, 1);
  }
  exit 0;
}

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->{'root'},     # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border

sub to_hex {
  my ($str) = @_;
  return join (' ',
               map {sprintf("%02X", ord(substr($str,$_,1)))}
               0 .. length($str)-1);
}

#------------------------------------------------------------------------------
# set_wm_name()

{
  my $name = "\x{03B1}";  # lower case alpha
  my $compound = "\x1B\x2D\x46\xE1";  # alpha 0xE1 in iso-8859-7

   MyTestHelpers::diag ("name is_utf8 '",utf8::is_utf8($name), "'");

  X11::Protocol::WM::set_wm_name ($X, $window, $name);
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('WM_NAME'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('COMPOUND_TEXT'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'COMPOUND_TEXT');
  ok (to_hex($value), to_hex($compound));
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
exit 0;
