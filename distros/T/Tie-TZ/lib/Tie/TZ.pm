# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

package Tie::TZ;
# require 5;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $TZ);

# uncomment this to run the ### lines
#use Smart::Comments;

$VERSION = 9;

@ISA = ('Exporter');
@EXPORT_OK = qw($TZ);
%EXPORT_TAGS = (all => \@EXPORT_OK);
tie $TZ, 'Tie::TZ';

my $tzset_if_available;
$tzset_if_available = sub {

  # Taking \&POSIX::tzset here makes $tzset_if_available the current
  # definition of that func.  If someone assigns *POSIX::tzset to change it
  # later then $tzset_if_available still goes to the old.  That should be
  # ok, since module imports of tzset() end up the same (ie. not tracking a
  # redefinition).  The only time a redefine might matter would be fakery
  # like Test::MockTime.  Stuff like that mainly mangles just the time
  # funcs, not tzset().  If it does change tzset() then it would have to get
  # in before any module imports anyway, which would probably mean the very
  # start of a program, and would be fine for this \&POSIX::tzset too.
  #
  require POSIX;
  $tzset_if_available = \&POSIX::tzset;

  if (! eval { POSIX::tzset(); 1 }) {
    if ($@ =~ /not implemented/) {
      # fail because not implemented, dummy out
      $tzset_if_available = sub {};

    } else {
      # Fail for some other reason, propagate this error and let POSIX give
      # future ones.  The first error is reported against the eval{} here,
      # but the goto in STORE() means subsequent ones are reported directly
      # against the $TZ assignment.  This isn't terribly important though,
      # since success or not-implemented are the only two normal cases.
      die $@;
    }
  }
};

sub TIESCALAR {
  my ($class) = @_;
  my $self = 'Tie::TZ oops, magic not used!';
  return bless \$self, $class;
}

sub FETCH {
  #### TiedTZ fetch: $ENV{'TZ'}
  return $ENV{'TZ'};
}

sub STORE {
  my ($self, $newval) = @_;
  ### TiedTZ store: $newval

  my $oldval = $ENV{'TZ'};
  if (defined $newval) {
    if (defined $oldval && $oldval eq $newval) {
      ### unchanged: $oldval
      return;
    }
    $ENV{'TZ'} = $newval;

  } else {
    if (! defined $oldval) {
      ### unchanged: undef
      return;
    }
    delete $ENV{'TZ'};
  }

  ### tzset() call

  # this was going to be "goto $tzset_if_available", with the incoming args
  # shifted off @_, but it's a call instead to avoid a bug in perl 5.8.9
  # where a goto to an xsub like this provokes a "panic restartop", at least
  # when done in the unwind of a "local" value for $TZ within an eval{}
  # within a caught die().
  #
  &$tzset_if_available();
}

1;
__END__

=for stopwords TZ Tie-TZ unsets startup eg Ryde

=head1 NAME

Tie::TZ - tied $TZ setting %ENV and calling tzset()

=head1 SYNOPSIS

 use Tie::TZ qw($TZ);
 $TZ = 'GMT';
 {
   local $TZ = 'EST+10';
   # ...
 }

=head1 DESCRIPTION

C<Tie::TZ> provides a tied C<$TZ> variable which gets and sets the TZ
environment variable C<$ENV{'TZ'}>.  When it changes C<%ENV> it calls
C<tzset()> (see L<POSIX>) if available, ensuring the C library notices the
change for subsequent C<localtime> etc.

    $TZ = 'GMT';
    # does  $ENV{'TZ'}='GMT'; POSIX::tzset();

For a plain set you can just as easily store and C<tzset> yourself (or have
a function do the combo).  The power of a tied variable comes when using
C<local> to have a different timezone temporarily.  Any C<goto>, C<return>,
C<die>, etc, exiting the block will restore the old setting, including a
C<tzset> for it.

    { local $TZ = 'GMT';
      print ctime();
      # TZ restored at block exit
    }

    { local $TZ = 'GMT';
      die 'Something';
      # TZ restored when the die unwinds
    }

Storing C<undef> to C<$TZ> deletes C<$ENV{'TZ'}> and unsets the environment
variable.  This generally means the timezone goes back to the system default
(F</etc/timezone> or wherever).

As an optimization, if a store to C<$TZ> is already what C<$ENV{'TZ'}>
contains then C<POSIX::tzset()> is not called.  This is helpful if some of
the settings you're using might be the same -- just store to C<$TZ> and it
notices when there's no change.  If you never store anything different from
the startup value then the C<POSIX> module is not even loaded.

If C<tzset> is not implemented on your system then C<Tie::TZ> just sets the
environment variable.  This is only likely on a very old or very limited C
library.  Of course setting the environment variable might or might not
affect the timezone in force (see L<perlport/Time and Date>).

=head2 Uses

Quite often C<tzset> is not actually needed.  Decent C libraries look for a
new TZ each time in the various C<localtime> etc functions.  Here are some
cases where you do need it,

=over 4

=item *

Using Perl-level C<localtime> in threaded Perl 5.8.8 (whether using threads
or not).  Normally Perl arranges to call C<tzset> if the C library doesn't
(based on a configure test, see L<Config>).  But in 5.8.8 and earlier Perl
didn't do that on C<localtime_r>, and in some versions of GNU C that
function needed an explicit C<tzset>.

=item *

Using C<localtime> from C code on older systems which don't check for a new
C<TZ> each time.  Even if Perl's configure test does the right thing for
Perl level calls you may not be so lucky deep in external libraries.

=item *

When using the global variables C<timezone>, C<daylight> and C<tzname>,
either from C code or from the C<POSIX> module C<tzname> function.

=back

=head1 EXPORTS

By default nothing is exported and you can use the full name
C<$Tie::TZ::TZ>,

    use Tie::TZ;
    $Tie::TZ::TZ = 'GMT';

Import C<$TZ> in the usual way (see L<Exporter>) as a shorthand, either by
name

    use Tie::TZ '$TZ';
    $TZ = 'GMT';

or C<":all"> imports everything (there's only C<$TZ> at the moment)

    use Tie::TZ ':all';
    $TZ = 'GMT';

=head1 OTHER NOTES

The C<Env> module can make a tied C<$TZ> in a similar way if you're
confident you don't need C<tzset>.  The C<local> trick above works equally
well with C<Env>.  You can also apply C<local> directly to C<$ENV{'TZ'}>,
eg. C<local $ENV{'TZ'} = 'EST+10'>, except you can't unset that way.
(Attempting to store C<undef> provokes a warning before Perl 5.10 and comes
out as the empty string, which might be subtly different to unset.)

When you get sick of the C library timezone handling have a look at
C<DateTime::TimeZone>.  Its copy of the Olson timezone database makes it big
(no doubt you could turf what you don't use), but it's all Perl and is much
friendlier for calculations in multiple zones.

=head1 SEE ALSO

L<POSIX>, L<Env>, L<perlport/Time and Date>, L<DateTime::TimeZone>

=head1 HOME PAGE

http://user42.tuxfamily.org/tie-tz/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Tie-TZ is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

=cut
