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
use Pod::Find;

print Pod::Find::pod_where({ '-verbose' => 1,
                             '-dirs' => [],
                             '-inc' => 1,
                           },
                           'Fatal'),"\n";











  #   my @moduleparts = split /::/, $module;
  #   foreach my $suffix ('.pod', '.pm') {
  #     foreach my $dir (@{$self->INC_arrayref}) {
  #       foreach my $poddir ([], ['pod'], ['pods']) {
  #         my $filename = (File::Spec->catfile($dir,@$poddir,@moduleparts)
  #                         . $suffix);
  #         #### $filename
  #         if (-e $filename) {
  #           return $filename;
  #         }
  #       }
  #     }
  #   }
  #   return undef;
# sub INC_arrayref {
#   my ($self) = @_;
#   return $self->{'INC'} || \@INC;
# }
