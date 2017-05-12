#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# 0-file-is-part-of.t is shared by several distributions.
#
# 0-file-is-part-of.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-file-is-part-of.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

ok (Test::FileIsPartOfDist->check(verbose=>1),
    'Test::FileIsPartOfDist');
exit 0;



package Test::FileIsPartOfDist;
BEGIN { require 5 }
use strict;
use ExtUtils::Manifest;
use File::Slurp;

sub import {
  my $class = shift;
  my $arg;
  foreach $arg (@_) {
    if ($arg eq '-test') {
      require Test;
      Test::plan(tests=>1);
      is ($class->check, 1, 'Test::FileIsPartOfDist');
    }
  }
  return 1;
}

sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub check {
  my $class = shift;
  my $self = $class->new(@_);

  my $manifest = ExtUtils::Manifest::maniread();
  if (! $manifest) {
    $self->diag("no MANIFEST perhaps");
    return 0;
  }
  my @filenames = keys %$manifest;

  my $distname = $self->makefile_distname;
  if (! defined $distname) {
    $self->diag("Oops, DISTNAME not found in Makefile");
    return 0;
  }
  if ($self->{'verbose'}) {
    $self->diag("DISTNAME $distname");
  }

  my $good = 1;
  my $filename;
  foreach $filename (@filenames) {
    if (! $self->check_file_is_part_of($filename,$distname)) {
      $good = 0;
    }
  }
  return $good;
}

sub makefile_distname {
  my ($self) = @_;
  my $filename = "Makefile";
  my $content = File::Slurp::read_file ($filename);
  if (! defined $content) {
    $self->diag("Cannot read $filename: $!");
    return undef;
  }
  my $distname;
  if ($content =~ /^DISTNAME\s*=\s*([^#\n]*)/m) {
    $distname = $1;
    $distname =~ s/\s+$//;
  }
  return $distname;
}

sub check_file_is_part_of {
  my ($self, $filename, $distname) = @_;

  my $content = File::Slurp::read_file ($filename);
  if (! defined $content) {
    $self->diag("Cannot read $filename: $!");
    return 0;
  }

  $content =~ /([T]his file is part of[^\n]*)/i
    or return 1;
  my $got = $1;
  if ($got =~ /[T]his file is part of \Q$distname/i) {
    return 1;
  }
  $self->diag("$filename: $got");
  $self->diag("expected DISTNAME: $distname");
  return 0;
}

sub diag {
  my $self = shift;
  my $func = $self->{'diag_func'}
    || eval { Test::More->can('diag') }
      || \&_diag;
  &$func(@_);
}
sub _diag {
  my $msg = join('', map {defined($_)?$_:'[undef]'} @_)."\n";
  $msg =~ s/^/# /mg;
  print STDERR $msg;
}
