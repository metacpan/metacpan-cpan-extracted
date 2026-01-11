package WWW::Noss::Timestamp;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.02';

use Time::Piece;

my %MONTHS = (
    'jan' => '01',
    'feb' => '02',
    'mar' => '03',
    'apr' => '04',
    'may' => '05',
    'jun' => '06',
    'jul' => '07',
    'aug' => '08',
    'sep' => '09',
    'oct' => '10',
    'nov' => '11',
    'dec' => '12',
);

# Regex taken from the loose parser in the DateTime::Format::Mail module.
my $mail_rx = qr{
    ^ \s*
    # Optional week day name
    (?i:
        (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun|[A-Z][a-z][a-z]) ,? # Day name + comma
    )?
    \s*
    (?<dom>\d{1,2}) # Day of month
    [-\s]*
    (?i: (?<month> Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ) # month
    [-\s]*
    (?<year>(?:\d\d)?\d\d) # year
    \s+
    (?<hour>\d?\d):(?<min>\d?\d) (?: :(?<sec>\d?\d) )? # hour:min:sec
    # Optional time zone
    (?:
        \s+ "? (?<tz>
            [+-] \d{4}     # standard
            | [A-Z]+       # obsolete (ignored)
            | GMT [+-] \d+ # empirical (converted)
            | [A-Z]+\d+    # wierd emprical (ignored)
            | [a-zA-Z/]+   # linux (ignored)
            | [+-]{0,2} \d{3,5} # corrupted standard
        ) "?
    )?
    (?: \s+ \([^\)]+\) )? # friendly tz name; empirical
    \s* \.? $
}x;

# Regex adapted from DateTime::Format::RFC3339.
my $rfc3339_rx = qr{
    ^
    # yyyy-mm-dd
    (?<year> \d{4})-(?<month> \d{2})-(?<dom> \d{2})
    T # date/time seperator
    # hh:mm:ss
    (?<hour> \d{2}):(?<min> \d{2}):(?<sec> \d{2})
    # nanoseconds (ignored)
    (?: \. \d{1,9}\d*)?
    (?<tz>
        Z # UTC (zulu)
        | [+-]\d{2}:\d{2}
    )
    $
}x;

sub mail {

    my ($class, $time) = @_;

    $time =~ $mail_rx or return undef;

    my $dom   = sprintf "%02d", $+{ dom };
    my $month = $MONTHS{ lc $+{ month } };
    my $year  =
        length $+{ year } == 4
        ? $+{ year }
        : $+{ year } >= 69
          ? "19$+{ year }"
          : "20$+{ year }";
    my $hour  = sprintf "%02d", $+{ hour } // 0;
    my $min   = sprintf "%02d", $+{ min }  // 0;
    my $sec   = sprintf "%02d", $+{ sec }  // 0;
    my $tz    =
        (defined $+{ tz } and $+{ tz } =~ /^([+-])(\d{4})$/)
        ? $1 . sprintf "%04d", $2
        : '-0000';

    my $tp = eval {
        Time::Piece->strptime(
            join(' ', $dom, $month, $year, $hour, $min, $sec, $tz),
            '%d %m %Y %H %M %S %z',
        );
    };

    return defined $tp ? $tp->epoch : undef;

}

sub rfc3339 {

    my ($class, $time) = @_;

    $time =~ $rfc3339_rx or return undef;

    my $year  = $+{ year };
    my $month = $+{ month };
    my $dom   = $+{ dom };
    my $hour  = $+{ hour };
    my $min   = $+{ min };
    my $sec   = $+{ sec };
    my $tz    =
        $+{ tz } eq 'Z'
        ? '-0000'
        : $+{ tz } =~ s/://gr;

    my $tp = eval {
        Time::Piece->strptime(
            join(' ', $year, $month, $dom, $hour, $min, $sec, $tz),
            '%Y %m %d %H %M %S %z'
        );
    };

    return defined $tp ? $tp->epoch : undef;

}

1;

=head1 NAME

WWW::Noss::Timestamp - Parse timestamps

=head1 USAGE

  use WWW::Noss::Timestamp;

  my $epoch = WWW::Noss::Timestamp->rfc3339(
    '2025-07-12T00:23:00Z'
  );

=head1 DESCRIPTION

B<WWW::Noss::Timestamp> is a module that provides methods for parsing various
timestamp formats used by RSS and Atom feeds. This is a private module, please
consult the L<noss(1)> manual for user documentation.

=head1 METHODS

Each method is invoked as a class method. Methods will return the timestamp's
seconds since the Unix epoch or C<undef> on failure.

=over 4

=item $epoch = WWW::Noss::Timestamp->mail($str)

Parse RFC2822/822 timestamps, used by RSS feeds. This is a lenient parser that
is capable of parsing some non-standard timestamps.

=item $epoch = WWW::Noss::Timestamp->rfc3339($str)

Parse RFC3339 timestamps, used by Atom feeds.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<noss>

=cut

# vim: expandtab shiftwidth=4
