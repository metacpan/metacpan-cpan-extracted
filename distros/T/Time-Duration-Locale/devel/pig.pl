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

use 5.010;
use strict;
use warnings;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin,'lib');
use Time::Duration::en_PIGLATIN;

{
  require Lingua::PigLatin;
  say  Lingua::PigLatin::piglatin('The string this quick trip scram stupid ghost');
  exit 0;
}

print "main duration() is ",\&duration,"\n";
print Time::Duration::en_PIGLATIN::_filter("hello world\n");
print Time::Duration::en_PIGLATIN::_filter("ago"),"\n";
print Time::Duration::en_PIGLATIN::duration(1230),"\n";
print duration(45*86400+6*3600),"\n";
print duration(150),"\n";

__END__

use Time::Duration::Locale ();

$ENV{'LANGUAGE'} = 'en';
Time::Duration::Locale::setlocale();
print Time::Duration::Locale::duration(45*86400+6*3600),"\n";

$ENV{'LANGUAGE'} = 'en_PIGLATIN';
Time::Duration::Locale::setlocale();
print Time::Duration::Locale::duration(45*86400+6*3600),"\n";

# {
#   my $module = Time::Duration::Locale::module();
#   print "module ",(defined $module ? $module : 'undef'), "\n";
# }
# 
# 
# $ENV{'LANGUAGE'} = 'en_PIGLATIN:it:sv';
# Time::Duration::Locale::setlocale();
# {
#   my $module = Time::Duration::Locale::module();
#   print "module ",(defined $module ? $module : 'undef'), "\n";
# }
# 
# print duration(150),"\n";

exit 0;
