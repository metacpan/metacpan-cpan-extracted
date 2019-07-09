#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 148)[1];
plan tests => $test_count;

require X11::AtomConstants;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::AtomConstants::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::AtomConstants->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::AtomConstants->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::AtomConstants->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------

ok (eval { PIXMAP() }, undef,
    'PIXMAP() not imported');
ok (eval { XA_PIXMAP() }, undef,
    'no XA_PIXMAP() imported (should not exist)');
ok (eval { X11::AtomConstants::XA_PIXMAP() }, undef,
    'XA_PIXMAP() does not exist');

ok (X11::AtomConstants::PIXMAP(), 20, 'PIXMAP() value');
ok (X11::AtomConstants::RECTANGLE(), 22, 'RECTANGLE() value');
ok (X11::AtomConstants::LAST_PREDEFINED(), 68, 'LAST_PREDEFINED() value');

#------------------------------------------------------------------------------

{
  my $name;
  foreach $name (@X11::AtomConstants::EXPORT_OK) {
    {
      my @ret = X11::AtomConstants->$name;
      ok (scalar(@ret), 1, "constant $name return 1 value");
    }
    next if $name eq 'LAST_PREDEFINED';
    {
      my $atom_id = X11::AtomConstants->$name;
      my $got_name = $X->GetAtomName($atom_id);
      ok ($got_name, $name, "constant $name = $atom_id");
    }
  }
}

ok (scalar(@X11::AtomConstants::EXPORT_OK),
    X11::AtomConstants::LAST_PREDEFINED() + 1,  # plus 1 for LAST_PREDEFINED
    "count of constants == LAST_PREDEFINED");

exit 0;
