#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Test-MockTime-DateCalc.
#
# Test-MockTime-DateCalc is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-MockTime-DateCalc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-MockTime-DateCalc.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
BEGIN {
  plan tests => 9;
}

my $have_sub_identify = eval { require Sub::Identify; 1 };
if (! $have_sub_identify) {
  print STDERR "# Sub::Identify not available -- $@";
}
my $skip = $have_sub_identify ? undef : 'due to Sub::Identify not available';

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Test::MockTime::DateCalc;
require Date::Calc;

#------------------------------------------------------------------------------
# Sub::Identify sub_name() on replacements

foreach (qw(System_Clock
            Today
            Now
            Today_and_Now
            This_Year
            Gmtime
            Localtime
            Timezone
            Time_to_Date)) {
  my $name = $_;
  my $fullname = "Date::Calc::$name";
  my $coderef = do { no strict 'refs';
                     \&$fullname };
  skip ($skip,
        $have_sub_identify && Sub::Identify::sub_name($coderef),
        $name,
        "name of $name $coderef");
}

exit 0;
