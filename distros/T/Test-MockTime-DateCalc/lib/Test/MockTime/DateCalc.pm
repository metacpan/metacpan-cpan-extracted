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


package Test::MockTime::DateCalc;
use strict;
use vars qw($VERSION);

$VERSION = 6;

BEGIN {
  # Check that Date::Calc isn't already loaded.
  #
  # Week_of_Year() here is a representative func, present in Date::Calc 4.0
  # and up, and not one that's mangled here (so as not to risk hitting that
  # if something goes badly wrong).  Maybe looking at %INC would be better.
  #
  if (Date::Calc->can('Week_of_Year')) {
    die "Date::Calc already loaded, cannot fake after imports may have grabbed its functions";
  }
}

# Date::Calc had a big rewrite in 4.0 of May 1998, no attempt to fake
# anything earlier than that
#
use Date::Calc 4.0;

package Date::Calc;
use strict;

# Calc.xs in Date::Calc calls to the C time() func from its internal C
# function DateCalc_system_clock(), and also directly in its Gmtime(),
# Localtime(), Timezone() and Time_to_Date().  In each case that of course
# misses any fakery on the perl level time().  The replacements here go to
# perl time() for the current time, and stay with Date::Calc for conversions
# to d/m/y etc.
#

{
  local $^W = 0; # no warnings
  eval <<'HERE' or die;
sub System_Clock {
  my ($gmt) = @_;
  return ($gmt ? Gmtime() : Localtime());
}
sub Today {
  return (System_Clock(@_))[0,1,2];
}
sub Now {
  return (System_Clock(@_))[3,4,5];
}
sub Today_and_Now {
  return (System_Clock(@_))[0,1,2, 3,4,5];
}
sub This_Year {
  return (System_Clock(@_))[0];
}
1
HERE
}

{
    local $^W = 0; # no warnings
    eval <<'HERE' or die;

# anonymous sub to avoid adding anything to the Date::Calc namespace
my $default_to_time_func = sub {
  my ($func, $time) = @_;
  if (! defined $time) { $time = time(); }
  return &$func($time);
};
{ my $orig;
  BEGIN { $orig = \&Gmtime; }
  sub Gmtime { return &$default_to_time_func ($orig, @_) }
}
{ my $orig;
  BEGIN { $orig = \&Localtime; }
  sub Localtime { return &$default_to_time_func ($orig, @_) }
}
{ my $orig;
  BEGIN { $orig = \&Timezone; }
  sub Timezone { return &$default_to_time_func ($orig, @_) }
}
{ my $orig;
  BEGIN { $orig = \&Time_to_Date; }
  sub Time_to_Date { return &$default_to_time_func ($orig, @_) }
}
1
HERE
}

1;
__END__

=for stopwords pre Ryde Test-MockTime-DateCalc pre-requisites fakery

=head1 NAME

Test::MockTime::DateCalc -- fake time for Date::Calc functions

=head1 SYNOPSIS

 use Test::MockTime;
 use Test::MockTime::DateCalc; # before Date::Calc loads
 # ...
 use My::Module::Using::Date::Calc;

=head1 DESCRIPTION

C<Test::MockTime::DateCalc> arranges for the functions in C<Date::Calc> to
follow the Perl level C<time> function (see L<perlfunc>) and in particular
any fake date/time set there by C<Test::MockTime>.  The following
C<Date::Calc> functions are changed

    System_Clock
    Today
    Now
    Today_and_Now
    This_Year

    Gmtime
    Localtime
    Timezone
    Time_to_Date

C<Gmtime>, C<Localtime>, C<Timezone> and C<Time_to_Date> are made to default
to the Perl-level current C<time>.  When called with an explicit time
argument they're unchanged.

=head2 Module Load Order

C<Test::MockTime> or similar fakery must be loaded first, before anything
with a C<time()> call, which includes C<Test::MockTime::DateCalc>.  This is
the same as for any C<CORE::GLOBAL> override, see L<CORE/OVERRIDING CORE
FUNCTIONS>.

C<Test::MockTime::DateCalc> must be loaded before C<Date::Calc>.  If
C<Date::Calc> is already loaded then its functions might have been imported
into other modules and such imports are not affected by the redefinitions
made.  For that reason C<Test::MockTime::DateCalc> demands it be the one to
load C<Date::Calc> for the first time.  Usually this simply means having
C<Test::MockTime::DateCalc> at the start of a test script, before the things
you're going to test.

    use strict;
    use warnings;
    use Test::MockTime ':all';
    use Test::MockTime::DateCalc;

    use My::Foo::Bar;

    set_fixed_time('1981-01-01T00:00:00Z');
    is (My::Foo::Bar::something(), 1981);
    restore_time();

In a test script it's often good to have your own modules early to check
they correctly load their pre-requisites.  You might want a separate test
script for that so as not to accidentally rely on
C<Test::MockTime::DateCalc> loading C<Date::Calc>.

=head2 Other Faking Modules

C<Test::MockTime::DateCalc> can be used with other modules which mangle the
Perl-level C<time> too.  For example C<Time::Fake>,

    use Time::Fake;                # fakery first
    use Test::MockTime::DateCalc;

Or C<Time::Mock>,

    use Time::Mock;                # fakery first
    use Test::MockTime::DateCalc;

C<Time::Warp> (as of version 0.5) only exports a new C<time>, it's not a
core override and so can't be used with C<Test::MockTime::DateCalc>.

=head1 SEE ALSO

L<Date::Calc>, L<Test::MockTime>, L<Time::Fake>, L<Time::Mock>

L<faketime(1)>

=head1 HOME PAGE

http://user42.tuxfamily.org/test-mocktime-datecalc/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011 Kevin Ryde

Test-MockTime-DateCalc is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Test-MockTime-DateCalc is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Test-MockTime-DateCalc.  If not, see <http://www.gnu.org/licenses/>.

=cut
