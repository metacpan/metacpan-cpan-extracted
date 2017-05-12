package Time::Duration::Parse::AsHash;

our $DATE = '2017-01-02'; # DATE
our $VERSION = '0.10.6'; # VERSION

#IFUNBUILT
# # use strict;
# # use warnings;
#END IFUNBUILT

use Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( parse_duration );

my %Units = ( map(($_, "nanoseconds" ), qw(ns nanosecond nanoseconds)),
              map(($_, "milliseconds"), qw(ms millisecond milliseconds milisecond miliseconds)),
              map(($_, "microseconds"), qw(microsecond microseconds)),
              map(($_, "seconds"), qw(s second seconds sec secs)),
              map(($_, "minutes"), qw(m minute minutes min mins)),
              map(($_,   "hours"), qw(h hr hour hours)),
              map(($_,    "days"), qw(d day days)),
              map(($_,   "weeks"), qw(w week weeks)),
              map(($_,  "months"), qw(M month months mon mons mo mos)),
              map(($_,   "years"), qw(y year years)),
              map(($_, "decades"), qw(decade decades)),
          );
my %Converts = (
    nanoseconds  => ["seconds" => 1e-9],
    microseconds => ["seconds" => 1e-6],
    milliseconds => ["seconds" => 1e-3],
    decades      => ["years"   => 10],
);

sub parse_duration {
    my $timespec = shift;

    # You can have an optional leading '+', which has no effect
    $timespec =~ s/^\s*\+\s*//;

    # Treat a plain number as a number of seconds (and parse it later)
    if ($timespec =~ /^\s*(-?\d+(?:[.,]\d+)?)\s*$/) {
        $timespec = "$1s";
    }

    # Convert hh:mm(:ss)? to something we understand
    $timespec =~ s/\b(\d+):(\d\d):(\d\d(?:\.\d+)?)\b/$1h $2m $3s/g;
    $timespec =~ s/\b(\d+):(\d\d)\b/$1h $2m/g;

    my %res;
    while ($timespec =~ s/^\s*(-?\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)(?:\s*(?:,|and)\s*)*//i) {
        my($amount, $unit) = ($1, $2);
        $unit = lc($unit) unless length($unit) == 1;

        if (my $canon_unit = $Units{$unit}) {
            $amount =~ s/,/./;
            if (my $convert = $Converts{$canon_unit}) {
                $canon_unit = $convert->[0];
                $amount *= $convert->[1];
            }
            $res{$canon_unit} += $amount;
        } else {
            die "Unknown timespec: $1 $2";
        }
    }

    if ($timespec =~ /\S/) {
        die "Unknown timespec: $timespec";
    }

    for (keys %res) {
        delete $res{$_} if $res{$_} == 0;
    }

    if ($_[0]) {
        return
            ( $res{seconds} || 0) +
            (($res{minutes} || 0) *        60) +
            (($res{hours}   || 0) *      3600) +
            (($res{days}    || 0) *     86400) +
            (($res{weeks}   || 0) *   7*86400) +
            (($res{months}  || 0) *  30*86400) +
            (($res{years}   || 0) * 365*86400);
    }

    \%res;
}

1;
# ABSTRACT: Parse string that represents time duration

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Duration::Parse::AsHash - Parse string that represents time duration

=head1 VERSION

version 0.10.6

=head1 SYNOPSIS

 use Time::Duration::Parse::AsHash;

 my $res = parse_duration("2 minutes and 3 seconds");    # => {minutes=>2, seconds=>3}
    $res = parse_duration("2m3.2s", 1); # => 123.2

    $res = parse_duration("01:02:03", 1); # => 3723

=head1 DESCRIPTION

Time::Duration::Parse::AsHash is like L<Time::Duration::Parse> except:

=over

=item * By default it returns a hashref of parsed duration elements instead of number of seconds

There are some circumstances when you want this, e.g. when feeding into
L<DateTime::Duration> and you want to count for leap seconds.

To return number of seconds like Time::Duration::Parse, pass a true value as the
second argument.

=item * By default seconds are not rounded

For example: C<"0.1s"> or C<100ms> will return result C<< { seconds => 0.1 } >>,
and C<"2.3s"> will return C<< { seconds => 2.3 } >>.

Also, <01:02:03> being recognized as C<1h2min3s>,
C<01:02:03.4567> will also be recognized as C<1h2min3.4567s>.

=item * It recognizes more duration units

C<milliseconds> (C<ms>), which will be returned in the C<seconds> key, for
example C<"400ms"> returns C<< { seconds => 0.4 } >>.

C<microseconds>. This will also be returned in C<seconds> key.

C<nanoseconds> (C<ns>). This will also be returned in C<seconds> key.

C<decades>. This will be returned in C<years> key, for example C<"1.5 decades">
will return C<< { years => 15 } >>.

=item * It has a lower startup overhead

By avoiding modules like L<Carp> and L<Exporter::Lite>, even L<strict> and
L<warnings> (starts up in ~3m vs ~9ms on my computer).

=back

=head1 FUNCTIONS

=head2 parse_duration($str [, $as_secs ]) => hash

Parses duration string and returns hash (unless when the second argument is
true, in which case will return the number of seconds). Dies on parse failure.

Currently two forms of string are recognized: the first is a series of number
and time units (e.g. "2 days, 3 hours, 4.5 minutes" or "2h3m4s") and the second
is time in the format of hh:mm:ss (the seconds can contain decimal numbers) or
hh:mm.

This function is exported by default.

Note that if the function is instructed to return number of seconds, the result
is an approximation: leap seconds are not regarded (so a minute is always 60
seconds), a month is always 30 days, a year is always 365 days.

=head1 SEE ALSO

L<Time::Duration::Parse>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
