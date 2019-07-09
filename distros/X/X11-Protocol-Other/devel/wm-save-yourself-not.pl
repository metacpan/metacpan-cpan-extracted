#!/usr/bin/perl -w

# Copyright 2017, 2019 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./wm-save-yourself-not.pl
# 
# This is an experiment to remove WM_SAVE_YOURSELF from top-level clients
# which also have WM_DELETE_WINDOW.
#
# mwm close button (f.kill) forcibly disconnects when WM_SAVE_YOURSELF,
# defeating the purpose of WM_DELETE_WINDOW.  Try without WM_SAVE_YOURSELF.
#

use strict;
use FindBin;
use Scalar::Util;
use X11::Protocol;
use X11::Protocol::Other;
use X11::Protocol::WM;

# uncomment this to run the ### lines
# use Smart::Comments;


sub toplevel_windows {
  my ($X, $root) = @_;
  if (! defined $root) { $root = $X->root; }
  $root = X11::Protocol::WM::root_to_virtual_root ($X, $root) || $root;
  # printf "root %d 0x%X\n", $root, $virtual_root;
  my (undef,undef, @children) = $X->QueryTree($root);
  return @children;
}

#------------------------------------------------------------------------------

my $X = X11::Protocol->new;
my $WM_PROTOCOLS     = $X->atom('WM_PROTOCOLS');
my $WM_SAVE_YOURSELF = $X->atom('WM_SAVE_YOURSELF');
my $WM_DELETE_WINDOW = $X->atom('WM_DELETE_WINDOW');

my @windows = map {
  X11::Protocol::WM::frame_window_to_client($X,$_) || ()
  } toplevel_windows($X);

WINDOW: foreach my $window (@windows) {
  printf "window %d 0x%X\n", $window, $window;
  {
    my ($str, $type, $format, $bytes_after)
      = $X->GetProperty ($window, $X->atom('WM_NAME'), $X->atom('STRING'),
                         0, 999, 0);
    if ($type != X11::AtomConstants::STRING()) {
      next WINDOW;
    }
    print "  WM_NAME $str\n";
  }
  {
    my @protocols   # list of atom integers
      = X11::Protocol::Other::get_property_atoms ($X, $window, $WM_PROTOCOLS);
    print "  WM_PROTOCOLS ";
    foreach my $protocol (@protocols) {
      print " ",$X->atom_name($protocol);
    }
    print "\n";

    if ((grep {$_ == $WM_DELETE_WINDOW} @protocols)
        && (grep {$_ == $WM_SAVE_YOURSELF} @protocols)) {
      print "  change\n";
      @protocols = grep {$_ != $WM_SAVE_YOURSELF} @protocols;
      X11::Protocol::Other::set_property_atoms ($X, $window, $WM_PROTOCOLS,
                                                @protocols);
    }
  }
}
exit 0;








# my ($value, $type, $format, $bytes_after)
#   = $X->GetProperty ($window, $WM_PROTOCOLS,
#                      0,    # AnyPropertyType
#                      0,    # offset
#                      999,  # length
#                      0);   # delete;
# if ($type != X11::AtomConstants::ATOM()) {
#   print "not atom\n";
#   next WINDOW;
# }
# if ($format != 32) {
#   print "not atom\n";
#   next WINDOW;
# }
# my @protocols = unpack 'L*', $value;
# foreach my $protocol (@protocols) {
#   print " ",$X->atom_name($protocol);
# }
# print "\n";
