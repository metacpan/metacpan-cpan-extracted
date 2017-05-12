#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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
use Time::Duration::LocaleObject;
use Test::More;

use Config;
$Config{useithreads}
  or plan skip_all => 'No ithreads in this Perl';

eval { require threads } # new in perl 5.8, maybe
  or plan skip_all => "threads.pm not available: $@";

plan tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


# This is only meant to check that any CLONE() done by threads works with
# the AUTOLOAD() and/or can() stuff.

$ENV{'LANGUAGE'} = 'en';
my $tdl = Time::Duration::LocaleObject->new;
$tdl->setlocale;

my $thr = threads->create(\&foo);
sub foo {
  return $tdl->ago(0);
}

my @ret = $thr->join;
is_deeply (\@ret, [$tdl->ago(0)], 'same in thread as main');

exit 0;
