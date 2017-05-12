#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# return a hashref which has as keys the anchor names from $mech->content
#
sub mech_anchors_hash {
  my ($mech) = @_;
  my %anchors;
  @anchors{html_anchors($mech->content)} = (); # hash slice
  if ($verbose >= 2) {
    print __x("anchors: {list}\n", list => join(',',keys %anchors));
  }
  return \%anchors;
}

sub _class_iterator_concat {
  my @iterators = @_;
  return Class::Iterator->new
    (sub {
       sub {
         for (;;) {
           my $it = $iterators[0] || return undef;
           if (defined (my $value = $it->next)) {
             return $value;
           }
           $it = pop @iterators || return;
         }
       }
     });
}

my $tar_gz_re = qr/(\.tar(\.gz|\.bz2)|\.tgz)$/;


    if ($filename =~ /~$/) {
      # emacs backup
      next;
    }
    my ($volume,$directory,$basename) = File::Spec->splitpath ($filename);
    if ($basename =~ /^\.?\#/) {
      # emacs backup .#foo or autosave #foo#
      next;
    }


sub _make_finder {
  my ($class, @inputs) = @_;
  require File::Find::Rule;

  my $rule = File::Find::Rule->new;
  $rule->or ($rule->new->directory->name($exclude_dirs_re)->prune->discard,
             $rule->new->directory->discard,
             $rule->new->file->name($exclude_files_re)->discard,
             $rule->new);
  $rule->start (@inputs);
}
