#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

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

# uncomment this to run the ### lines
# use Smart::Comments;

# eg. ~/.cpanm/sources/http%www.cpan.org/02packages.details.txt


{
  my $re = qr/^([^ ]*[^ :]) /;
  require File::HomeDir;
  my $wildcard = File::Spec->catfile(File::HomeDir->my_home,
                                     '.cpanm','sources','*','02packages.details.txt');
  foreach my $filename (glob $wildcard) {
    open my $fh, $filename or die;
    open my $bfh, $filename or die;

    # my $ret = _packages_details_bsearch($bfh, 'FindBin');
    # ### $ret
    # last;

    my $count = 0;
    my $count2 = 0;
    while (defined(my $line = readline $fh)) {
      if ($line =~ $re) {
        my $module = $1;
        $count++;
        if ($count < 10) {
          print ">>$module<<\n";
        }
        my $ret = _packages_details_bsearch($bfh, $module);
        if (! $ret) {
          print "not found: $module\n";
          # last if ++$count2 > 5;
        }

      } else {
        print $line;
      }
    }
    print "count $count\n";
  }
  exit 0;
}

{
  # eg. ~/.cpanm/sources/http%www.cpan.org/02packages.details.txt
  require App::PodLinkCheck;
  my $self = App::PodLinkCheck->new;

  my $re = qr/^([^ ]*[^ :]) /;
  require File::HomeDir;
  my $wildcard = File::Spec->catfile(File::HomeDir->my_home,
                                     '.cpanm','sources','*','02packages.details.txt');
  foreach my $filename (glob $wildcard) {
    my $fh;
    open $fh, $filename or die;
    my $count = 0;
    my $count2 = 0;
    while (defined(my $line = readline $fh)) {
      if ($line =~ $re) {
        my $module = $1;
        $count++;
        if ($count < 10) {
          print ">>$module<<\n";
        }
        my $ret = $self->_module_known_cpanminus($module);
        if (! $ret) {
          print "not found: $module\n";
          last if ++$count2 > 0;
        }

      } else {
        print $line;
      }
    }
    print "count $count\n";
  }
  exit 0;
}

{
  require File::HomeDir;
  my $wildcard = File::Spec->catfile(File::HomeDir->my_home,
                                     '.cpanm','sources','*','02packages.details.txt');
  my $re = qr/^([^ ]*[^ :]) /;
  foreach my $filename (glob $wildcard) {
    open my $fh, $filename or die;
    my %seen;
    while (defined(my $line = readline $fh)) {
      $line =~ $re or next;
      my $module = $1;
      if ($seen{lc($module)}++) {
        print "duplicate $module\n";
      }
    }
  }
  exit 0;
}
{
  require App::PodLinkCheck;
  my $self = App::PodLinkCheck->new;
  my $ret = $self->_module_known_cpanminus('FindBin');
  ### $ret
  $ret = $self->_module_known_cpanminus('App::PodLinkCheck');
  ### $ret
  $ret = $self->_module_known_cpanminus('NoSuchModule');
  ### $ret

  $ret = $self->_module_known_cpanminus('Zymurgy::Vintner::Recipe');
  ### $ret

  exit 0;
}
