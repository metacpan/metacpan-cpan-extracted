#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

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

my $test_count = (tests => 113)[1];
plan tests => $test_count;

require X11::Protocol::Other;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

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
MyTestHelpers::X11_server_info($X);

$X->QueryPointer($X->{'root'});  # sync

#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::Protocol::Other::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::Other->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::Other->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::Other->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


#------------------------------------------------------------------------------
# get_property_atoms()

my $test_window = $X->new_rsrc;
$X->CreateWindow ($test_window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0,                # border
                  # event_mask => $X->pack_event_mask('PropertyChange'),
                 );

{
  my $property = $X->atom('X11_PROTOCOL_OTHER__TEST');
  my $property2 = $X->atom('X11_PROTOCOL_OTHER__TEST_2');
  my $root = $X->root;
  my @want_atoms_one = ($X->atom('ONE'),
                        $X->atom('TWO'));
  $X->ChangeProperty($root,
                     $property,                   # property
                     X11::AtomConstants::ATOM(),  # type
                     32,                          # format
                     'Replace',
                     pack('L*', @want_atoms_one));

  my @want_atoms_two = ($X->atom('TWO'),
                        $X->atom('THREE'));
  ok (join(',',@want_atoms_one) ne join(',',@want_atoms_two),
      1);
  $X->ChangeProperty($test_window,
                     $property2,                  # property
                     X11::AtomConstants::ATOM(),  # type
                     32,                          # format
                     'Replace',
                     pack('L*', @want_atoms_two));

  {
    my @got_atoms
      = X11::Protocol::Other::get_property_atoms ($X, $root, $property);
    ok (scalar(@got_atoms), 2);
    ok (join(',',@got_atoms), join(',',@want_atoms_one));
  }
  {
    my @got_atoms
      = X11::Protocol::Other::get_property_atoms ($X, $test_window, $property2);
    ok (scalar(@got_atoms), 2);
    ok (join(',',@got_atoms), join(',',@want_atoms_two));
  }

  $X->DeleteProperty ($root, $property);
  {
    my @got_atoms
      = X11::Protocol::Other::get_property_atoms ($X, $root, $property);
    ok (scalar(@got_atoms), 0);
    ok (join(',',@got_atoms), '');
  }
}

#------------------------------------------------------------------------------
# root_to_screen()

{
  my $screens_aref = $X->{'screens'};
  my $good = 1;
  my $screen_number;
  foreach $screen_number (0 .. $#$screens_aref) {
    my $rootwin = $screens_aref->[$screen_number]->{'root'}
      || die "oops, no 'root' under screen $screen_number";
    my $got = X11::Protocol::Other::root_to_screen($X,$rootwin);
    if (! defined $got || $got != $screen_number) {
      $good = 0;
      MyTestHelpers::diag ("root_to_screen() wrong on rootwin $rootwin screen $screen_number");
      MyTestHelpers::diag ("got ", (defined $got ? $got : 'undef'));
    }
  }
  ok ($good, 1, "root_to_screen()");
}

#------------------------------------------------------------------------------
# visual_class_is_dynamic()

{
  my $visual_class = 'PseudoColor';
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      1,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 3;
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      1,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 'TrueColor';
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      0,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 4;
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      0,
      "visual_class_is_dynamic() $visual_class");
}

#------------------------------------------------------------------------------
# visual_is_dynamic()

{
  my $good = 1;
  foreach (keys %{$X->{'visuals'}}) {
    my $visual_id = $_;
    my $visual_class = $X->{'visuals'}->{$visual_id}->{'class'};
    my $got = X11::Protocol::Other::visual_is_dynamic($X,$visual_id);
    my $want = X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class);
    if ($got != $want) {
      MyTestHelpers::diag ("wrong: visual_id $visual_id visual_class $visual_class got $got want $want");
      $good = 0;
    }
  }
  ok ($good, 1,
      'visual_is_dynamic() ');
}

#------------------------------------------------------------------------------
# hexstr_to_rgb()

{
  my $elem;
  foreach $elem ([ 'bogosity' ],
                 [ '#' ],
                 [ '#1' ],
                 [ '#12' ],

                 [ '#def', 0xDDDD, 0xEEEE, 0xFFFF ],

                 [ '#1234' ],
                 [ '#12345' ],

                 [ '#123456', 0x1212, 0x3434, 0x5656 ],
                 [ '#abcdef', 0xABAB, 0xCDCD, 0xEFEF ],
                 [ '#ABCDEF', 0xABAB, 0xCDCD, 0xEFEF ],

                 [ '#1234567' ],
                 [ '#12345678' ],

                 [ '#123456789', 0x1231, 0x4564, 0x7897 ],
                 [ '#abcbcdcde', 0xABCA, 0xBCDB, 0xCDEC ],

                 [ '#1234567890' ],
                 [ '#12345678901' ],

                 [ '#123456789ABC', 0x1234, 0x5678, 0x9ABC ],
                 [ '#abcdfedcdcba', 0xABCD, 0xFEDC, 0xDCBA ],

                 [ '#1234567890123' ],
                 [ '#12345678901234' ],
                 [ '#123456789012345' ],
                 [ '#1234567890123456' ],
                 [ '#12345678901234567' ],
                 [ '#123456789012345678' ],

                ) {
    my ($hexstr, @want_rgb) = @$elem;
    my @got_rgb = X11::Protocol::Other::hexstr_to_rgb($hexstr);
    ok (scalar(@got_rgb), scalar(@want_rgb),
        "hexstr_to_rgb($hexstr) return 3 values");
    ok ($got_rgb[0], $want_rgb[0],
        "hexstr_to_rgb($hexstr) red[0]");
    ok ($got_rgb[1], $want_rgb[1],
        "hexstr_to_rgb($hexstr) green[1]");
    ok ($got_rgb[2], $want_rgb[2],
        "hexstr_to_rgb($hexstr) blue[2]");
  }
}

#------------------------------------------------------------------------------
$X->QueryPointer($X->{'root'});  # sync

exit 0;
