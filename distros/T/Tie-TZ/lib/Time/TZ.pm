# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package Time::TZ;
# require 5;
use strict;
use Carp;
use Tie::TZ;
use vars qw($VERSION);

# uncomment this to run the ### lines
#use Smart::Comments;

$VERSION = 9;

sub new {
  my ($class, %self) = @_;
  my $self = bless \%self, $class;
  unless (delete $self{'defer'}) {
    $self->tz;
  }
  return $self;
}

sub name {
  my ($self) = @_;
  return $self->{'name'};
}

sub tz {
  my ($self) = @_;
  my $choose = delete $self->{'choose'};
  if ($choose) {
    foreach (@$choose) {
      if ($self->tz_known($_)) {
        ### Time-TZ choose: $_
        return ($self->{'tz'} = $_);
      }
    }
    my $name = $self->name;
    my $msg = "TZ" . (defined $name ? " '$name'" : '')
      . ': no zone known to the system among: '
        . join(' ',@$choose);
    if (defined (my $tz = delete $self->{'fallback'})) {
      warn $msg,", using $tz instead\n";
      return ($self->{'tz'} = $tz);
    }
    croak $msg;
  }
  return $self->{'tz'};
}

my %tz_known = (UTC => 1, GMT => 1);
my $zonedir;
sub tz_known {
  my ($class_or_self, $tz) = @_;
  ### tz_known(): $tz
  if (! defined $tz || $tz_known{$tz}) {
    return 1;
  }

  # EST-10 or EST-10EDT etc
  if ($tz =~ /^[A-Z]+[0-9+-]+([A-Z]+)?($|,)/) {
    ### yes, std+offset form
    return 1;
  }

  {
    require File::Spec;
    $zonedir ||= File::Spec->catdir (File::Spec->rootdir,
                                     'usr','share','zoneinfo');
    my $filename = $tz;
    $filename =~ s/^://;
    $filename = File::Spec->rel2abs ($filename, $zonedir);
    ### $filename
    if (-e $filename) {
      ### yes, file exists
      return 1;
    }
  }

  # any hour or minute different from GMT in any of 12 calendar months
  my $timet = time();
  local $Tie::TZ::TZ = $tz;
  foreach (1 .. 12) {
    my $mon = $_;
    my $delta = $mon * 30 * 86400;
    my $t = $timet + $delta;
    my ($l_sec,$l_min,$l_hour,$l_mday,$l_mon,$l_year,$l_wday,$l_yday,$l_isdst)
      = localtime ($t);
    my ($g_sec,$g_min,$g_hour,$g_mday,$g_mon,$g_year,$g_wday,$g_yday,$g_isdst)
      = gmtime ($t);
    if ($l_hour != $g_hour || $l_min != $g_min) {
      ### yes, different from GMT in mon: $mon
      return 1;
    }
  }

  ### no
  return 0;
}

sub localtime {
  my ($self, $timet) = @_;
  if (! defined $timet) { $timet = time(); }
  local $Tie::TZ::TZ = $self->tz;
  return localtime ($timet);
}

sub call {
  my $self = shift;
  my $subr = shift;
  local $Tie::TZ::TZ = $self->tz;
  return &$subr(@_);
}

1;
__END__

=for stopwords TZ Tie-TZ ie placename UTC localtime Ryde

=head1 NAME

Time::TZ -- object-oriented TZ settings

=for test_synopsis my ($auck, $frank, @parts, $timet)

=head1 SYNOPSIS

 use Time::TZ;
 $auck = Time::TZ->new (tz => 'Pacific/Auckland');

 $frank = Time::TZ->new (name     => 'Frankfurt',
                         choose   => [ 'Europe/Frankfurt',
                                       'Europe/Berlin' ],
                         fallback => 'CET-1CEDT,M3.5.0,M10.5.0/3');

 @parts = $auck->localtime($timet);

=head1 DESCRIPTION

This is an object-oriented approach to C<TZ> environment variable settings,
ie. C<$ENV{'TZ'}>.  A C<Time::TZ> object holds a TZ string and has methods
to make calculations in that zone by temporarily changing the C<TZ>
environment variable (see L<Tie::TZ>).

The advantage of this approach is that it needs only a modest amount of code
and uses the same system timezones as other programs.  Of course what system
timezones are available and whether they're up-to-date etc is another
matter, and switching C<TZ> for each calculation can be disappointingly slow
(for example in the GNU C Library).

=head1 FUNCTIONS

=over 4

=item C<< $tz = Time::TZ->new (key=>value, ...) >>

Create and return a new TZ object.  The possible key/value parameters are

    tz        TZ string
    choose    arrayref of TZ strings
    fallback  TZ string
    name      free-form name string

If C<choose> is given then the each TZ string in the array is checked and
the first known to the system is used (see C<tz_known> below).  C<choose> is
good if a place has different settings on different systems or new enough
systems.

    my $brem = Time::TZ->new (choose => [ 'Europe/Bremen',
                                          'Europe/Berlin' ]);

If none of the C<choose> settings are known then C<new> croaks.  If you
supply a C<fallback> then it just carps and uses that fallback value.

    my $brem = Time::TZ->new (choose => [ 'Europe/Bremen',
                                          'Europe/Berlin' ],
                              fallback => 'CET-1');

The C<name> parameter is not used for any timezone calculations, it's just a
handy way to keep a human-readable placename with the object.

=item C<$bool = Time::TZ-E<gt>tz_known ($str)>

Return true if C<TZ> setting C<$str> is known to the system (the C library
etc).

    $bool = Time::TZ->tz_known ('EST+10');          # true
    $bool = Time::TZ->tz_known ('some bogosity');   # false

The way this works is unfortunately rather system dependent.  The
"name+/-offset" forms are always available, as are "GMT" and "UTC".  On a
GNU system place names are checked under F</usr/share/zoneinfo>.  Otherwise
a check is made to see if C<$str> gives C<localtime> different from
C<gmtime> on one of a range of values through the year.

The time check works for the GNU C Library where a bad timezone comes out as
GMT, but might not be enough elsewhere.  Place names the same as GMT are no
good of course, and if the system makes a bogus zone come out as say the
default local time then they won't be detected (unless that local time
happens to be GMT too).  If wrong the suggestion for now is not to use
C<choose> but put in a setting unconditionally,

    my $acc = Time::TZ->new (tz => 'SomeWhere');

=back

=head2 Object Methods

=over 4

=item C<$str = $tz-E<gt>tz()>

Return the C<TZ> string of C<$tz>.

=item C<$str = $tz-E<gt>name()>

Return the name of C<$tz>, or C<undef> if none set.

=back

=head2 Time Operations

=over 4

=item C<ret = $tz-E<gt>call ($subr)>

=item C<ret = $tz-E<gt>call ($subr, $arg, ...)>

Call C<$subr> with the C<TZ> environment variable temporarily set to
C<$tz-E<gt>tz>.  The return value is the return from C<$subr>, with the same
scalar or array context as the C<call> itself.

    $tz->call (sub { print "the time is ",ctime() });

    my $year = $tz->call (\&Date::Calc::This_Year);

Arguments are passed on to C<$subr>.  For an anonymous sub there's no need
for that, but they can be good for a named sub,

    my @ret = $tz->call (\&foo, 1, 2, 3);

=item C<@lt = $tz-E<gt>localtime ()>

=item C<@lt = $tz-E<gt>localtime ($time_t)>

Call C<localtime> (see L<perlfunc/localtime>) in the given C<$tz> timezone.
C<$time_t> is a value from C<time()>, or defaults to the current C<time()>.
The return is the usual list of 9 localtime values.

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
          = $tz->localtime;

=back

=head1 SEE ALSO

L<Tie::TZ>, L<perlvar/%ENV>, L<Time::localtime>, L<DateTime::TimeZone>

=head1 HOME PAGE

http://user42.tuxfamily.org/tie-tz/index.html

=head1 COPYRIGHT

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
