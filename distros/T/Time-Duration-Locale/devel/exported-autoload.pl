#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
BEGIN {
  $ENV{'LANGUAGE'} = 'en';
}
use Time::Duration::Locale ();

print "after use\n";
print "TDL::duration() is ",
  (defined &Time::Duration::Locale::duration ? "defined" : "not defined"),
  "\n";

{
  my $can = Time::Duration::Locale->UNIVERSAL::can('setlocale');
  print "after use: UNIVERSAL::can(setlocale) is ",
    (defined $can ? $can : "undef"), "\n";
  if ($can) {
    use B::Deparse;
    my $deparse = B::Deparse->new("-p", "-sC");
    my $body = $deparse->coderef2text($can);
    print "Deparse: $body\n";
  }
}
{
  my $can = Time::Duration::Locale->UNIVERSAL::can('duration');
  print "after use: UNIVERSAL::can(duration) is ",
    (defined $can ? $can : "undef"), "\n";
  if ($can) {
    use B::Deparse;
    my $deparse = B::Deparse->new("-p", "-sC");
    my $body = $deparse->coderef2text($can);
    print "Deparse: $body\n";
  }
  if ($can) {
    use Devel::Peek;
    print "Peek: ",Dump($can);
  }
  #   if ($can) {
  #     require B::Concise;
  #     my $cv = B::CV->new(
  #     print "Concise:\n";
  #     B::Concise::concise_cv_obj('basic',$can,'duration');
  #   }
}

exit 0;
