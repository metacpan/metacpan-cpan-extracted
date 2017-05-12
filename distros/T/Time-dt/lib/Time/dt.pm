package Time::dt;
$VERSION = v0.0.1;

# Copyright (C) 2013 Eric L. Wilhelm

use warnings;
use strict;
use Carp;

=head1 NAME

Time::dt - date and time succinctly

=head1 SYNOPSIS

  use Time::dt;
  
  say "iso timestamp: ", dt;
  say "stringification shmingification: ", dt->dt;

  Time::dt::strptime($timestamp, "%Y-%m-%d %H:%M:%S"); # epoch

=cut

BEGIN {require Exporter; *import = \&Exporter::import};
our @EXPORT    = qw(dt);
our @EXPORT_OK = qw(read_dt strptime);

{
  package Time::Piece::Tidy;
  use base 'Time::Piece';
  use overload '""' => \&dt;
  sub dt {
    my $self = shift;
    my $fmt = '%Y-%m-%d %H:%M:%S';
    $fmt .= ' %Z' if ($self->[10]); # XXX this is bad or wrong
    $self->strftime($fmt);
  }
  *cdate = \&dt;

=head2 zdt

String format with timezone.

  print $dt->zdt('US/Eastern');

=cut

sub zdt {
  my ($self, $tz) = @_;

  my $e = $self->epoch;
  local $ENV{TZ} = $tz;
  ref($self)->new($e)->dt;
} # zdt ################################################################

} # end package
########################################################################

=head1 Functions

=head2 dt

  my $dt = dt(time);

=cut

sub dt {
  my $t = shift;
  Time::Piece::Tidy->new($t);
}

=head2 read_dt

  my $dt = read_dt(

=cut

sub read_dt {
  my $ts = shift;
  dt(strptime($ts));
}

=head2 strptime

Returns the epoch seconds for a given parsed time.

  my $t = strptime($string, $format);

=cut

{
my %zones = (
  PST  => '-0800',
  PDT  => '-0700',
  MST  => '-0700',
  MDT  => '-0600',
  CST  => '-0600',
  CDT  => '-0500',
  EST  => '-0500',
  EDT  => '-0400',
  AST  => '-0400',
  ALST => '-0900',
  ALDT => '-0800',
  HST  => '-1000',
);
my $zk = join('|', keys %zones);
sub strptime {
  my ($string, $format) = @_;
  $format ||= '%Y-%m-%d %H:%M:%S %Z';

  my $is_local;
  if($format =~ s/%Z$/%z/) {
    $string =~ s/ ($zk)$/ $zones{$1}/; # hack to parse named zones
  }
  elsif($format =~ m/%z$/) {
    $string =~ s/:(\d\d)$/$1/; # fix broken tz
  }
  else {
    $is_local = 1; # no zone means localtime
  }

  my @vals = eval {Time::Piece::_strptime($string, $format)};
  die "$@ $string - $format" if $@;


  return $is_local
    ? Time::Local::timelocal(@vals[0..9])
    : Time::Local::timegm(@vals[0..9]);
}}

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2013 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
