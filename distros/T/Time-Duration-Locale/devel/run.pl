#!/usr/bin/perl -w

# Copyright 2009, 2010, 2013, 2017 Kevin Ryde

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
use lib 'lib';
BEGIN {
  $ENV{'LANGUAGE'} = 'es:pl:xx_YY:zz:id:fr_FR:fr:en_PIGLATIN:pt:en_AU:sv';
}
use Time::Duration::Locale;

use FindBin;
my $progname = $FindBin::Script;

require Encode::Locale;
require PerlIO::encoding;
unless (binmode(STDIN, ":encoding(console_in)")
        && binmode(STDOUT, ":encoding(console_out)")
        && binmode(STDERR, ":encoding(console_out)")) {
  warn "Cannot set :encoding on stdin/out: $!\n";
}

# Time::Duration::Locale::setlocale();
{
  my $module = Time::Duration::Locale::module();
  print "$progname: module ",(defined $module ? $module : 'undef'), "\n";
}
print "$progname: main duration() is ",\&duration,"\n";
{
  require Time::Duration;
  print "$progname: Time::Duration::duration() is ",\&Time::Duration::duration,"\n";
}
{
  my $str = duration(45*86400+6*3600);
  my $is_utf8 = utf8::is_utf8($str);
  # $str = Encode::decode ('utf-8', $str, Encode::FB_CROAK());
  print "$progname: duration $str  ", $is_utf8?"utf8":"bytes", "\n";
}
{
  my $module = Time::Duration::Locale::module();
  print "$progname: module ",(defined $module ? $module : 'undef'), "\n";
}

print "\n";
$ENV{'LANGUAGE'} = 'pt:en_PIGLATIN:it:sv';
Time::Duration::Locale::setlocale();
{
  my $module = Time::Duration::Locale::module();
  print "$progname: module ",(defined $module ? $module : 'undef'), "\n";
}

print "$progname: ",duration(150),"\n";

exit 0;
