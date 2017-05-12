#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Smart::Comments;

{
  require CPANPLUS::Configure;
  my $conf = CPANPLUS::Configure->new;
  $conf->set_conf( verbose => 1 );
  $conf->set_conf( no_update => 1 );

  require CPANPLUS::Backend;
  my $cpanplus ||= CPANPLUS::Backend->new ($conf);
#   print "!reload\n";
#   $cpanplus->reload_indices (update_source => 0, verbose => 1);

  print "!module_tree\n";
  my $mobj = $cpanplus->module_tree('NoSuchModule');
  ### NoSuchModule: $mobj

  $mobj = $cpanplus->module_tree('Filter::Util::Call');
  ### $mobj
  exit 0;
}

