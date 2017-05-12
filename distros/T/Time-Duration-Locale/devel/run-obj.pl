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
  $ENV{'LANGUAGE'} = 'en:sv';
}
use Time::Duration::LocaleObject;

my $tdl = Time::Duration::LocaleObject->new;
{
  my $module = $tdl->module;
  print "module ",(defined $module ? $module : 'undef'), "\n";
}
{
  $tdl->setlocale;
  my $module = $tdl->module;
  print "setlocale module ",(defined $module ? $module : 'undef'), "\n";
}

print "ago: ", $tdl->ago(123),"\n";

print "set sv\n";
$tdl->language('sv');
print "language now ", $tdl->language;
print "ago: ", $tdl->ago(123),"\n";

my $coderef = $tdl->can('ago');
print "cago: ", $tdl->$coderef(123),"\n";


eval {
  # Module::Load::load ('NoSuch');
  $tdl->language('nosuchlang');
};
print "error:\n",$@,"\nend\n";

exit 0;
