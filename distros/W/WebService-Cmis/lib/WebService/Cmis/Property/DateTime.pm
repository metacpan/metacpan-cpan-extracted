package WebService::Cmis::Property::DateTime;

=head1 NAME

WebService::Cmis::Property::DateTime

Representation of a propertyDateTime of a cmis object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis::Property ();
use Time::Local ();
our @ISA = qw(WebService::Cmis::Property);
our $TZSTRING;  # timezone string for servertime; "Z" or "+01:00" etc.

=head1 METHODS

=over 4

=item parse($isoDate) -> $epoch

convert the given string into epoch seconds. The date string
must be in ISO date format, e.g. 2011-01-18T16:05:54.951+01:00

=cut

sub parse {
  my ($this, $isoDate) = @_;

  return unless defined $isoDate;

  if ($isoDate =~ /(\d\d\d\d)(?:-(\d\d)(?:-(\d\d))?)?(?:T(\d\d)(?::(\d\d)(?::(\d\d(?:\.\d+)?))?)?)?(Z|[-+]\d\d(?::\d\d)?)?/) {
    my ($Y, $M, $D, $h, $m, $s, $tz) = ($1, $2 || 1, $3 || 1, $4 || 0, $5 || 0, $6 || 0, $7 || '');

    # strip milliseconds
    $s =~ s/\.\d+$//;

    $M--;

    return Time::Local::timegm($s, $m, $h, $D, $M, $Y).$tz;
  }

  # format does not match
  return;
}

=item unparse($perlValue) $cmisValue

converts a perl representation back to a format understood by cmis

=cut

sub unparse {
  my ($this, $value) = @_;

  $value = $this->{value} if ref($this) && !defined $value;
  $value ||= 0;

  my $milliseconds;
  if ($value =~ s/(\.\d+)$//) {
    $milliseconds = $1;
  }

  return 'none' if !defined $value || $value eq '';

  my $tz;
  if ($value =~ /^(\d+)(Z|[-+]\d\d(?::\d\d)?)?$/) {
    $value = $1;
    $tz = $2 || '';
  } else {
    return 'none';
  }

  my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = gmtime($value);
  #print STDERR "unparsing hour=$hour\n";
  #print STDERR "isdst=$isdst\n";

  my $formatString = '$year-$mo-$dayT$hour:$min:$sec$isotz';

  $formatString =~ s/\$m(illi)?seco?n?d?s?/sprintf('%.3u',$sec)/gei;
  $formatString =~ s/\$seco?n?d?s?/sprintf('%.2u',$sec)/gei;
  $formatString =~ s/\$minu?t?e?s?/sprintf('%.2u',$min)/gei;
  $formatString =~ s/\$hour?s?/sprintf('%.2u',$hour)/gei;
  $formatString =~ s/\$day/sprintf('%.2u',$day)/gei;
  $formatString =~ s/\$mo/sprintf('%.2u',$mon+1)/gei;
  $formatString =~ s/\$year?/sprintf('%.4u',$year + 1900)/gei;
  $formatString =~ s/\$isotz/$tz/g;

  return $formatString;
}

=item getTZString

Get timezone offset of the local time from GMT in seconds.
Code taken from CPAN module 'Time' - "David Muir Sharnoff disclaims any
copyright and puts his contribution to this module in the public domain.

=cut

sub getTZString {

  # time zone designator (+hh:mm or -hh:mm)
  unless (defined $TZSTRING) {
    my $offset = _tzOffset();
    my $sign = ($offset < 0) ? '-' : '+';
    $offset = abs($offset);
    my $hours = int($offset / 3600);
    my $mins = int(($offset - $hours * 3600) / 60);
    if ($hours || $mins) {
      $TZSTRING = sprintf("$sign%02d:%02d", $hours, $mins);
    } else {
      $TZSTRING = 'Z';
    }
  }

  return $TZSTRING;
}

sub _tzOffset {
  my $time = time();
  my @l = localtime($time);
  my @g = gmtime($time);

  my $off = $l[0] - $g[0] + ($l[1] - $g[1]) * 60 + ($l[2] - $g[2]) * 3600;

  # subscript 7 is yday.

  if ($l[7] == $g[7]) {

    # done
  } elsif ($l[7] == $g[7] + 1) {
    $off += 86400;
  } elsif ($l[7] == $g[7] - 1) {
    $off -= 86400;
  } elsif ($l[7] < $g[7]) {

    # crossed over a year boundary.
    # localtime is beginning of year, gmt is end
    # therefore local is ahead
    $off += 86400;
  } else {
    $off -= 86400;
  }

  return $off;
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
