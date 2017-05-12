#!/usr/bin/perl -w

# Copyright 2010, 2011, 2016 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use File::Find ();

# uncomment this to run the ### lines
use Smart::Comments;

{
  mkdir '/tmp/dir/';
  mkdir '/tmp/dir/a';
  system 'touch /tmp/dir/a/afile';
  mkdir '/tmp/dir/z';
  system 'touch /tmp/dir/z/zfile';
  symlink '/tmp/dir/z', '/tmp/dir/s';
  symlink 'nosuchtarget', '/tmp/dir/dangling';

  my %seen;
  my $follow_symlink = sub {
    my ($filename) = @_;
    for (;;) {
      my $fullname = File::Spec->catfile($File::Find::dir, $filename);
      unless (-l $fullname) { return $filename; }

      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
          $atime,$mtime,$ctime,$blksize,$blocks) = stat(_);
      if ($seen{$dev,$ino}++) { return; } # don't re-follow symlinks

      $filename = readlink $fullname;
      ### readlink to: $filename
      if (! defined $filename) {
        print "dangling symlink: $fullname\n";
        return;
      }
    }
    return $filename;
  };

  File::Find::find ({ wanted => sub {
                        my $filename = $File::Find::name;
                        print "$filename\n";
                      },
                      # follow_fast => 1,
                      no_chdir => 1,
                      preprocess => sub {
                        print "preprocess: @_\n";
                        return map { $follow_symlink->($_) } sort @_;
                      },
                    },
                    '/tmp/dir');

  require File::Find::Iterator;
  print "\n";
  print "iterator\n";
  my $finder = File::Find::Iterator->create(dir => ['/tmp/dir']);
  while (my $filename = $finder->next) {
    print "$filename\n";
  }
  exit 0;
}

{
  File::Find::find ({ wanted => sub {
                        my $filename = $File::Find::name;
                        # print "$filename\n";
                      },
                      follow_fast => 1,
                      no_chdir => 1,
                      preprocess => sub {
                        print "@_\n";
                        return @_;
                      },
                    },
                    '/usr/share/perl5');
  exit 0;
}
