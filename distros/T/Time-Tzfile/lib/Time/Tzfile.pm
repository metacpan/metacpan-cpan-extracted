package Time::Tzfile;
$Time::Tzfile::VERSION = '0.04';
use strict;
use warnings;

use autodie;
use Config;

#ABSTRACT: read binary tzfiles into Perl data structures


sub parse {
  my ($class, $args) = @_;

  my $tzdata = parse_raw($class, $args);

  my $abbrev = $tzdata->[4][0];
  # swap null char for pipe so length() works
  $abbrev =~ s/\0/|/g;

  my @timestamps = ();
  for (0..$#{$tzdata->[2]})
  {
    my $struct = $tzdata->[3][ $tzdata->[2][$_] ];
    my $abbr_substring = substr $abbrev, $struct->[2];
    my ($abbrev, $junk) = split /\|/, $abbr_substring, 2;
    push @timestamps, {
      epoch => $tzdata->[1][$_],
      offset=> $struct->[0],
      is_dst=> $struct->[1],
      type  => $abbrev,
    };
  }
  return \@timestamps;
}


sub parse_raw {
  my ($class, $args) = @_;

  open my $fh, '<:raw', $args->{filename};
  my $use_version_one = $args->{use_version_one};
  my $header = parse_header($fh);

  if ($header->[1] == 2 # it will have the 64 bit entries
      && !$use_version_one  # not forcing to 32bit timestamps
      && ($Config{use64bitint} eq 'define' # Perl is 64bit int capable
          || $Config{longsize} >= 8)
     ) {

    # jump past the version one body
    skip_to_next_record($fh, $header);

    # parse the v2 header
    $header = parse_header($fh);

    return [
      $header,
      parse_time_counts_64($fh, $header),
      parse_time_type_indices($fh, $header),
      parse_types($fh, $header),
      parse_timezone_abbrev($fh, $header),
      parse_leap_seconds_64($fh, $header),
      parse_std($fh, $header),
      parse_gmt($fh, $header),
    ];
  }
  else {
    return [
      $header,
      parse_time_counts($fh, $header),
      parse_time_type_indices($fh, $header),
      parse_types($fh, $header),
      parse_timezone_abbrev($fh, $header),
      parse_leap_seconds($fh, $header),
      parse_std($fh, $header),
      parse_gmt($fh, $header),
    ];
  }
}

sub parse_bytes (*$@) {
  my ($fh, $bytes_to_read, $template) = @_;

  my $bytes_read = read $fh, my($bytes), $bytes_to_read;
  die "Expected $bytes_to_read bytes but got $bytes_read"
    unless $bytes_read == $bytes_to_read;

  return [] unless $template;

  my @data = unpack $template, $bytes;
  return \@data;
}

sub parse_header {
  my ($fh) = @_;
  my $header = parse_bytes($fh, 44, 'a4 a x15 N N N N N N');

  die 'This file does not appear to be a tzfile'
    if $header->[0] ne 'TZif';

  return $header;
}

sub parse_time_counts {
  my ($fh, $header) = @_;
  my $byte_count    =  4   * $header->[5];
  my $template      = 'l>' x $header->[5];
  return parse_bytes($fh, $byte_count, $template);
}

sub parse_time_counts_64 {
  my ($fh, $header) = @_;
  my $byte_count    =  8  * $header->[5];
  my $template      = 'q>' x $header->[5];
  return parse_bytes($fh, $byte_count, $template);
}

sub parse_time_type_indices {
  my ($fh, $header) = @_;
  my $byte_count    = 1   * $header->[5];
  my $template      = 'C' x $header->[5];
  return parse_bytes($fh, $byte_count, $template);
}

sub parse_types {
  my ($fh, $header) = @_;
  my $byte_count    = 6     * $header->[6];
  my $template      = 'l>cC' x $header->[6];
  my $data          = parse_bytes($fh, $byte_count, $template);

  my @mappings   = ();
  for (my $i = 0; $i < @$data-2; $i += 3) {
    push @mappings, [
      $data->[$i],
      $data->[$i + 1],
      $data->[$i + 2],
    ];
  }
  return \@mappings;
}

sub parse_timezone_abbrev {
  my ($fh, $header) = @_;
  my $byte_count    = 1   * $header->[7];
  my $template      = 'a' . $header->[7];
  return parse_bytes($fh, $byte_count, $template);
}

sub parse_leap_seconds {
  my ($fh, $header) = @_;
  my $byte_count    = 8      * $header->[4];
  my $template      = 'l>l>' x $header->[4];
  my $data          = parse_bytes($fh, $byte_count, $template);
  my @mappings   = ();
  for (my $i = 0; $i < @$data-1; $i += 2) {
    push @mappings, {
      timestamp => $data->[$i],
      offset    => $data->[$i + 1],
    };
  }
  return \@mappings;
}

sub parse_leap_seconds_64 {
  my ($fh, $header) = @_;
  my $byte_count    = 12     * $header->[4];
  my $template      = 'q>l>' x $header->[4];
  my $data          = parse_bytes($fh, $byte_count, $template);
  my @mappings   = ();
  for (my $i = 0; $i < @$data-1; $i += 2) {
    push @mappings, [
      $data->[$i],
      $data->[$i + 1],
    ];
  }
  return \@mappings;
}

sub parse_gmt {
  my ($fh, $header) = @_;
  my $byte_count    = 1   * $header->[2];
  my $template      = 'c' x $header->[2];
  return parse_bytes($fh, $byte_count, $template);
}

sub parse_std {
  my ($fh, $header) = @_;
  my $byte_count    = 1   * $header->[3];
  my $template      = 'c' x $header->[3];
  return parse_bytes($fh, $byte_count, $template);
}

sub skip_to_next_record {
  my ($fh, $header) = @_;
  my $bytes_to_skip = 4 * $header->[5]
                    + 1 * $header->[5]
                    + 6 * $header->[6]
                    + 1 * $header->[7]
                    + 8 * $header->[4]
                    + 1 * $header->[2]
                    + 1 * $header->[3];
  parse_bytes($fh, $bytes_to_skip);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Tzfile - read binary tzfiles into Perl data structures

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Time::Tzfile;

  # get 64bit timestamps if available
  my $tzdata = Time::Tzfile->parse({filename => '/usr/share/zoneinfo/Europe/London'});

  # always get 32bit timestamps
  my $tzdata = Time::Tzfile->parse({
    filename        => '/usr/share/zoneinfo/Europe/London',
    use_version_one => 1,
  });

  # get an unassembled raw parse of the file
  my $tzdata = Time::Tzfile->parse_raw({
    filename => '/usr/share/zoneinfo/Europe/London'});

=head1 METHODS

=head2 parse ({filename => /path/to/tzfile, use_version_one => 1})

The C<parse> takes a hashref containing the filename of the tzfile to open
and optionally a flag to use the version one (32bit) tzfile entry. Returns an
arrayref of hashrefs:

  {
    epoch   => 1234566789, # offset begins here
    offset  => 3600,       # offset in seconds
    type    => GMT,        # official abbreviation
    is_dst  => 0,          # is daylight saving bool
  }

Tzfiles can have two entries in them: the version one entry with 32bit timestamps
and the version two entry with 64bit timestamps. If the tzfile has the version
two entry, and if C<perl> is compiled with 64bit support, this method will
automatically return the version two entry. If you want to force the version one
entry, include the C<use_version_one> flag in the method arguments.

See L<#SYNOPSIS> for examples.

N.B. AFAIK all binary tzfiles are compiled with UTC timestamps, so this method
ignores the leap, GMT and STD time entries for calculating offsets. If you
want to include them, use L<#parse_raw> as an input to your own calculations.

=head2 parse_raw ({filename => /path/to/tzfile, use_version_one => 1})

This method reads the binary file into an arrayref of arrayrefs. Use this if
you'd like to inspect the tzfile data, or use it as an input into your own
programs.

The arrayref looks like this:

  [
    header          # version and counts for the body
    transitions     # historical timestamps when TZ changes occur
    transition_idx  # index of ttinfo structs which apply to transitions
    ttinfo_structs  # gmt offset, dst flag & the tz abbrev idx
    tz_abbreviation # tz abbreviation string (EDT, GMT, BST etc)
    leap_seconds    # timestamp & offset to apply leap secs
    std_wall        # arrayref of std wall clock indicators
    gmt_local       # arrayref of gm local indicators
  ]

=head1 SEE ALSO

=over 4

=item * L<DateTime::TimeZone> - automatically uses text versions of the Olsen db to calculate timezone offsets

=item * L<DateTime::TimeZone::Tzfile> - applies TZ offsets from binary tzfiles to DateTime objects

=item * L<Time::Zone::Olson> - another module for parsing Tzfiles

=back

=head1 TZFILE FORMAT INFO

I found these resources useful guides to understanding the tzfile format

=over 4

=item * Tzfile L<manpage|http://linux.die.net/man/5/tzfile>

=item * Very useful description of tzfile format from L<Bloomberg|https://bloomberg.github.io/bde/baltzo__zoneinfobinaryreader_8h_source.html>

=item * Wikipedia L<entry|https://en.wikipedia.org/wiki/IANA_time_zone_database> on the TZ database

=back

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
