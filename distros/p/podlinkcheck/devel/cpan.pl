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

$ENV{'HOME'} = '/tmp/nosuchdir';

mkdir '/tmp/nosuchdir';
chmod 0444, '/tmp/nosuchdir';

{
  # print  exists($CPAN::META->{'readwrite'}->{'CPAN::Module'}->{'x'}),"\n";

  require CPAN;
  if (! $CPAN::Config_loaded) {
    print "CPAN::HandleConfig->load\n";
    local $CPAN::HandleConfig::loading = 1;
    CPAN::HandleConfig->load;
    print "finished CPAN::HandleConfig->load\n";
  }
  print "CPAN::META ",scalar(%$CPAN::META),"\n";
  if (! %$CPAN::META) {
    print "read_metadata_cache ...\n";
    local $CPAN::Config->{use_sqlite} = 0;
    CPAN::Index->read_metadata_cache;
  }
  print "CPAN::META ",scalar(%$CPAN::META),"\n";
  if (! %$CPAN::META) {
    print "read_metadata_cache ...\n";
    local $CPAN::Config->{use_sqlite} = 0;
    CPAN::Index->read_metadata_cache;
  }

  my @keys = keys %$CPAN::META;
  print scalar(@keys),"\n";
  print @keys,"\n";

  @keys = keys %{$CPAN::META->{'readwrite'}};
  print scalar(@keys),"\n";
  print @keys,"\n";

  @keys = keys %{$CPAN::META->{'readwrite'}->{'CPAN::Module'}};
  print scalar(@keys),"\n";
  print @keys[0,1,2,3],"\n";

  my $module = 'Class::Methodmaker';
  print exists($CPAN::META->{'readwrite'}->{'CPAN::Module'}->{$module}),"\n";
  print $CPAN::META->{'readwrite'}->{'CPAN::Module'}->{$module},"\n";
  exit 0;
}

{
#   if (! $CPAN::Config_loaded) {
#     CPAN::HandleConfig->load;
#   }
  #   $CPAN::Config{'index_expire'} = 999;
  #   $CPAN::Config->{'load_module_verbosity'} = 'verbose'; # : 'silent';
  #
  #   print $CPAN::META,"\n";

  #   require Data::Dumper;
  #   print Data::Dumper->new([$CPAN::META],['META'])->Dump;

  # CPAN::Index->reload;

  foreach my $mobj ($CPAN::META->all_objects('CPAN::Module')) {
    print $mobj,"\n";
  }

  print "\n\nexpand ...\n";
  my $mobj = CPAN::Shell->expand('Module', 'Foo::Bar');
  print $mobj,"\n";
  exit 0;
}

