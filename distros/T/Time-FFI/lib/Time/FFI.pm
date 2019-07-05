package Time::FFI;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use FFI::Platypus;
use FFI::Platypus::Buffer;
use FFI::Platypus::Memory;
use Time::FFI::tm;

our $VERSION = '0.002';

our @EXPORT_OK = qw(asctime ctime gmtime localtime mktime strftime strptime);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $ffi = FFI::Platypus->new(lib => [undef], ignore_not_found => 1);
$ffi->type('record(Time::FFI::tm)' => 'tm');
my $char_size = $ffi->sizeof('char');

if (defined $ffi->find_symbol('asctime_r')) {
  $ffi->attach([asctime_r => 'asctime'] => ['tm', 'opaque'] => 'string' => sub {
    my ($xsub, $tm) = @_;
    my $rc = $xsub->($tm, my $buf = calloc(26, $char_size));
    free $buf;
    croak "asctime: $!" unless defined $rc;
    return $rc;
  });
} else {
  $ffi->attach(asctime => ['tm'] => 'string' => sub {
    my ($xsub, $tm) = @_;
    my $rc = $xsub->($tm);
    croak "asctime: $!" unless defined $rc;
    return $rc;
  });
}

if (defined $ffi->find_symbol('ctime_r')) {
  $ffi->attach([ctime_r => 'ctime'] => ['time_t*', 'opaque'] => 'string' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time, my $buf = calloc(26, $char_size));
    free $buf;
    croak "ctime: $!" unless defined $rc;
    return $rc;
  });
} else {
  $ffi->attach(ctime => ['time_t*'] => 'string' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time);
    croak "ctime: $!" unless defined $rc;
    return $rc;
  });
}

if (defined $ffi->find_symbol('gmtime_r')) {
  $ffi->attach([gmtime_r => 'gmtime'] => ['time_t*', 'tm'] => 'opaque' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time, my $tm = Time::FFI::tm->new);
    croak "gmtime: $!" unless defined $rc;
    return $tm;
  });
} else {
  $ffi->attach(gmtime => ['time_t*'] => 'tm' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time);
    croak "gmtime: $!" unless defined $rc;
    return $rc;
  });
}

if (defined $ffi->find_symbol('localtime_r')) {
  $ffi->attach([localtime_r => 'localtime'] => ['time_t*', 'tm'] => 'opaque' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time, my $tm = Time::FFI::tm->new);
    croak "localtime: $!" unless defined $rc;
    return $tm;
  });
} else {
  $ffi->attach(localtime => ['time_t*'] => 'tm' => sub {
    my ($xsub, $time) = @_;
    $time = time unless defined $time;
    my $rc = $xsub->(\$time);
    croak "localtime: $!" unless defined $rc;
    return $rc;
  });
}

$ffi->attach(mktime => ['tm'] => 'time_t' => sub {
  my ($xsub, $tm) = @_;
  my $rc = $xsub->($tm);
  croak "mktime: $!" if $rc == -1;
  return $rc;
});

$ffi->attach(strftime => ['opaque', 'size_t', 'string', 'tm'] => 'size_t' => sub {
  my ($xsub, $format, $tm) = @_;
  my $max_size = length($format) * 20;
  my $buf_size = 200;
  my $rc = 0;
  my $buf;
  until ($rc != 0) {
    $rc = $xsub->($buf = realloc($buf, $buf_size * $char_size), $buf_size, $format, $tm);
    last if $buf_size > $max_size;
  } continue {
    $buf_size *= 2;
  }
  my $str = buffer_to_scalar $buf, $rc * $char_size;
  free $buf;
  return $str;
});

$ffi->attach(strptime => ['string', 'string', 'tm'] => 'string' => sub {
  my ($xsub, $str, $format, $tm, $remaining) = @_;
  $tm = Time::FFI::tm->new unless defined $tm;
  my $rc = $xsub->($str, $format, $tm);
  croak "strptime: Failed to match input to format string" unless defined $rc;
  $$remaining = $rc if defined $remaining;
  return $tm;
});

1;

=head1 NAME

Time::FFI - libffi interface to POSIX date and time functions

=head1 SYNOPSIS

  use Time::FFI qw(localtime mktime strptime strftime);

  my $tm = strptime '1995-01-02 13:15:39', '%Y-%m-%d %H:%M:%S';
  my $epoch = mktime $tm;
  print "$epoch: ", strftime('%I:%M:%S %p on %B %e, %Y', $tm);
  my $piece = $tm->to_object('Time::Piece', 1);

  my $tm = localtime time;
  my $datetime = $tm->to_object('DateTime', 1);

  my $tm = gmtime time;
  my $moment = $tm->to_object('Time::Moment', 0);

=head1 DESCRIPTION

B<Time::FFI> provides a L<libffi|FFI::Platypus> interface to POSIX date and
time functions found in F<time.h>.

The L</gmtime> and L</localtime> functions behave very differently from the
core functions of the same name, as well as those exported by L<Time::Piece>,
so you may wish to call them as e.g. C<Time::FFI::gmtime> rather than importing
them.

All functions will throw an exception in the event of an error. For functions
other than L</strftime> and L</strptime>, this exception will contain the
syscall error message, and L<perlvar/$!> will also have been set by the
syscall, so you could check it after trapping the exception for finer exception
handling.

=head1 FUNCTIONS

All functions are exported individually, or with the C<:all> export tag.

=head2 asctime

  my $str = asctime $tm;

Returns a string in the format C<Wed Jun 30 21:49:08 1993\n> representing the
passed L<Time::FFI::tm> record. The thread-safe L<asctime_r(3)> function is
used if available.

=head2 ctime

  my $str = ctime $epoch;
  my $str = ctime;

Returns a string in the format C<Wed Jun 30 21:49:08 1993\n> representing the
passed epoch timestamp (defaulting to the current time) in the local time zone.
This is equivalent to L<POSIX/ctime> but uses the thread-safe L<ctime_r(3)>
function if available.

=head2 gmtime

  my $tm = gmtime $epoch;
  my $tm = gmtime;

Returns a L<Time::FFI::tm> record representing the passed epoch timestamp
(defaulting to the current time) in UTC. The thread-safe L<gmtime_r(3)>
function is used if available.

=head2 localtime

  my $tm = localtime $epoch;
  my $tm = localtime;

Returns a L<Time::FFI::tm> record representing the passed epoch timestamp
(defaulting to the current time) in the local time zone. The thread-safe
L<localtime_r(3)> function is used if available.

=head2 mktime

  my $epoch = mktime $tm;

Returns the epoch timestamp representing the passed L<Time::FFI::tm> record
interpreted in the local time zone.

=head2 strftime

  my $str = strftime $format, $tm;

Returns a string formatted according to the passed format string, representing
the passed L<Time::FFI::tm> record. Consult your system's L<strftime(3)> manual
for available format descriptors.

=head2 strptime

  my $tm = strptime $str, $format;
     $tm = strptime $str, $format, $tm;
  my $tm = strptime $str, $format, undef, \my $remaining;
     $tm = strptime $str, $format, $tm, \my $remaining;

Returns a L<Time::FFI::tm> record representing the passed string, parsed
according to the passed format. Consult your system's L<strptime(3)> manual for
available format descriptors.

A L<Time::FFI::tm> record may be passed as the third argument, in which case it
will be modified in place to (on most systems) update only the date/time
elements which were parsed from the string. Additionally, an optional scalar
reference may be passed as the fourth argument, in which case it will be set to
the remaining unprocessed characters of the input string if any.

This function is usually not available on Windows.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Time::Piece>, L<Time::Moment>, L<DateTime>, L<POSIX>, L<POSIX::strptime>
