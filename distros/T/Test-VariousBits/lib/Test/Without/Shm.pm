# Copyright 2011, 2012, 2013, 2015, 2017 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.


# cf doio.c
#   Perl_do_ipcget() for shmget
#   Perl_do_shmio() for shmread,shmwrite
#   Perl_do_ipcctl() for shmget
#

package Test::Without::Shm;
require 5;
use strict;

use vars '$VERSION';
$VERSION = 7;

# uncomment this to run the ### lines
#use Devel::Comments;

### Test-Without-Shm loads ...

my %modes = (notimp => 1,
             nomem  => 1,
             normal => 1);
my $current_mode = 'normal';  # default

sub _croak {
  require Carp;
  Carp::croak(@_);
}

sub mode {
  my ($class, $mode) = @_;
  ### Test-Without-Shm mode(): @_

  if (@_ > 1) {
    $modes{$mode} or _croak "No such $class mode: ",$mode;
    $current_mode = $mode;
  }
  return $current_mode;
}

sub import {
  my $class = shift;
  ### Test-Without-Shm import(): @_

  if (! @_) {
    # default
    $current_mode = 'notimp';
  } else {
    foreach (@_) {
      if ($_ eq '-notimp') {
        $current_mode = 'notimp';
      } elsif ($_ eq '-nomem') {
        $current_mode = 'nomem';
      } elsif ($_ eq '-normal') {
        $current_mode = 'normal';
      } else {
        _croak 'Test::Without::Shm unrecognised import option: ',$_;
      }
    }
  }
}

sub unimport {
  $current_mode = 'normal';
}


*CORE::GLOBAL::shmget = \&Test_Without_Shm_shmget;
sub Test_Without_Shm_shmget ($$$) {
  my ($key, $size, $flags) = @_;
  ### Test-Without-Shm shmget() ...

  if ($current_mode eq 'notimp') {
    # this message string per doio.c Perl_do_ipcget()
    _croak "shmget not implemented";
  }
  if ($current_mode eq 'nomem') {
    require POSIX;
    $! = POSIX::ENOMEM();
    return undef;
  }
  return CORE::shmget ($key, $size, $flags);
}

*CORE::GLOBAL::shmread = \&Test_Without_Shm_shmread;
sub Test_Without_Shm_shmread ($$$$) {
  my ($id,$var,$pos,$size) = @_;
  if ($current_mode eq 'notimp') {
    # this message string per doio.c Perl_do_shmio()
    _croak "shm I/O not implemented";
  }
  return CORE::shmread($id,$var,$pos,$size);
}

*CORE::GLOBAL::shmwrite = \&Test_Without_Shm_shmwrite;
sub Test_Without_Shm_shmwrite ($$$$) {
  my ($id,$str,$pos,$size) = @_;
  if ($current_mode eq 'notimp') {
    # this message per doio.c Perl_do_shmio()
    _croak "shm I/O not implemented";
  }
  return CORE::shmwrite($id,$str,$pos,$size);
}

*CORE::GLOBAL::shmctl = \&Test_Without_Shm_shmctl;
sub Test_Without_Shm_shmctl ($$$) {
  my ($id,$cmd,$arg) = @_;
  if ($current_mode eq 'notimp') {
    # this message string per doio.c Perl_do_ipcctl()
    _croak "shmctl not implemented";
  }
  return CORE::shmctl($id,$cmd,$arg);
}

1;
__END__

=for stopwords Ryde Test-VariousBits shm shmget ie fakery

=head1 NAME

Test::Without::Shm - simulate shmget() etc not available

=head1 SYNOPSIS

 # pretend shm not implemented on the system
 perl -MTest::Without::Shm myprog.pl ...

 # pretend not enough memory for shm
 perl -MTest::Without::Shm=-nomem myprog.pl ...

=head1 DESCRIPTION

This module overrides the Perl core functions

    shmget()
    shmread()
    shmwrite()
    shmctl()

to pretend that their System-V style shared memory is either not implemented
or there's not enough memory.

This fakery can be used during testing to check how module code etc might
behave on a system without shm or when there's not enough memory.  A module
might throw an error, use an I/O fallback, etc.

The shm functions are overridden using the C<CORE::GLOBAL> mechanism (see
L<CORE/OVERRIDING CORE FUNCTIONS>) so C<Test::Without::Shm> must be loaded
before compiling any code which might use the shm functions.

=head1 COMMAND LINE

The default import behaviour is to pretend shm is not implemented on the
system.  C<-M> can be used on the command line when running a program,

    perl -MTest::Without::Shm myprog.pl ...

The C<-nomem> option pretends that shm exists but there's not enough memory,

    perl -MTest::Without::Shm=-nomem myprog.pl ...

For the usual C<ExtUtils::MakeMaker> test harness the C<-M> can be put in
the C<HARNESS_PERL_SWITCHES> environment variable in the usual way,

    HARNESS_PERL_SWITCHES="-MTest::Without::Shm" make test

=head1 IMPORTS

The same effect as the above C<-M> can be had in a script,

    use Test::Without::Shm;   # shm not implemented

or for C<-nomem>

    use Test::Without::Shm '-nomem';

If you want to load the C<Test::Without::Shm> module but not activate it
then give a C<()> in the usual way to skip its C<import()> action,

    # setups, but no "without" yet
    use Test::Without::Shm ();

Don't forget that this must be done before any code using the C<shm...()>
functions, which probably means somewhere early in the mainline script.

The import options are

=over

=item C<-notimp>

Make shm "not implemented", as if the system doesn't have the underlying
functions.  This makes the Perl functions croak with "shmget not
implemented", or "shm I/O not implemented", etc.

=item C<-nomem>

Make C<shmget()> fail with C<ENOMEM> as if the system says there's not
enough memory to make a shm segment.  This is arranged even when the system
doesn't have shm (ie. when "not implemented" would be the normal state).

=back

=head1 FUNCTIONS

=over

=item C<$mode = Test::Without::Shm-E<gt>mode ()>

=item C<Test::Without::Shm-E<gt>mode ($mode)>

Get or set the shm fakery mode.  C<$mode> is a string

    "notimp"
    "nomem"
    "normal"

Normal mode means the C<shm...()> functions are Perl's normal behaviour,
whatever that might be.  In the current implementation this is done by
leaving the C<CORE::GLOBAL> setups installed but dispatching to the actual
C<CORE::shm...()> routines.

=back

=head1 SEE ALSO

L<perlfunc/shmget>,
L<CORE>,
L<shmget(2)>,
L<IPC::SysV>

Perl sources C<doio.c> C<Perl_do_ipcget()>, C<Perl_do_shmio()> and
C<Perl_do_ipcctl()>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/test-variousbits/index.html>

=head1 COPYRIGHT

Copyright 2011, 2012, 2013, 2015, 2017 Kevin Ryde

Test-VariousBits is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3, or (at your option) any
later version.

Test-VariousBits is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Test-VariousBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
