use strict;
use warnings;
package Time::F;
$Time::F::VERSION = '0.024';
# ABSTRACT: Formatting times.

use Carp qw/ croak /;
use Exporter qw/ import /;
use Function::Parameters qw/ :strict /;

use Time::C::Util qw/ get_fmt_tok get_locale /;
use Time::P;

our @EXPORT = qw/ strftime /;


my %formatter; %formatter = (
    '%A'  => fun ($t, $l) { get_locale(weekdays => $l)->[$t->day_of_week() % 7]; },
    '%a'  => fun ($t, $l) { get_locale(weekdays_abbr => $l)->[$t->day_of_week() % 7]; },
    '%B'  => fun ($t, $l) { get_locale(months => $l)->[$t->month() - 1]; },
    '%b'  => fun ($t, $l) { get_locale(months_abbr => $l)->[$t->month() - 1]; },
    '%C'  => fun ($t, $l) { sprintf '%02d', substr($t->year, -4, 2) + 0; },
    '%-C' => fun ($t, $l) { substr($t->year, -4, 2) + 0; },
    '%c'  => fun ($t, $l) { strftime($t, get_locale(datetime => $l), locale => $l); },
    '%D'  => fun ($t, $l) { strftime($t, '%m/%d/%y', locale => $l); },
    '%d'  => fun ($t, $l) { sprintf '%02d', $t->day; },
    '%-d' => fun ($t, $l) { $t->day; },
    '%EC' => fun ($t, $l) { strftime($t, _fmt_era(C => $t, get_locale(era => $l)), locale => $l); },
    '%Ec' => fun ($t, $l) { strftime($t, get_locale(era_datetime => $l), locale => $l); },
    '%EX' => fun ($t, $l) { strftime($t, get_locale(era_time => $l), locale => $l); },
    '%Ex' => fun ($t, $l) { strftime($t, get_locale(era_date => $l), locale => $l); },
    '%EY' => fun ($t, $l) { strftime($t, _fmt_era(Y => $t, get_locale(era => $l)), locale => $l); },
    '%Ey' => fun ($t, $l) { strftime($t, _fmt_era(y => $t, get_locale(era => $l)), locale => $l); },
    '%e'  => fun ($t, $l) { sprintf '%2d', $t->day; },
    '%-e' => fun ($t, $l) { $t->day; },
    '%F'  => fun ($t, $l) { strftime($t, '%Y-%m-%d', locale => $l); },
    '%G'  => fun ($t, $l) { sprintf '%04d', $t->clone->day_of_week(4)->year; },
    '%-G' => fun ($t, $l) { $t->clone->day_of_week(4)->year; },
    '%g'  => fun ($t, $l) { sprintf '%02d', substr($formatter{'%G'}->($t, $l), -2); },
    '%-g' => fun ($t, $l) { substr($formatter{'%G'}->($t, $l), -2) + 0; },
    '%H'  => fun ($t, $l) { sprintf '%02d', $t->hour; },
    '%-H' => fun ($t, $l) { $t->hour; },
    '%h'  => fun ($t, $l) { $formatter{'%b'}->($t, $l); },
    '%I'  => fun ($t, $l) { my $I = $t->hour % 12; sprintf '%02d', $I ? $I : 12; },
    '%-I' => fun ($t, $l) { my $I = $t->hour % 12; $I ? $I : 12; },
    '%j'  => fun ($t, $l) { sprintf '%03d', $t->day_of_year; },
    '%-j' => fun ($t, $l) { $t->day_of_year; },
    '%k'  => fun ($t, $l) { sprintf '%2d', $t->hour; },
    '%-k' => fun ($t, $l) { $t->hour; },
    '%l'  => fun ($t, $l) { my $I = $t->hour % 12; sprintf '%2d', $I ? $I : 12; },
    '%-l' => fun ($t, $l) { my $I = $t->hour % 12; $I ? $I : 12; },
    '%M'  => fun ($t, $l) { sprintf '%02d', $t->minute; },
    '%-M' => fun ($t, $l) { $t->minute; },
    '%m'  => fun ($t, $l) { sprintf '%02d', $t->month; },
    '%-m' => fun ($t, $l) { $t->month; },
    '%n'  => fun ($t, $l) { "\n"; },
    '%OC' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%C'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OC." if @d < 100;
        return $d[$n];
    },
    '%Od' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%d'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Od." if @d < 32;
        return $d[$n];
    },
    '%Oe' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%e'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Oe." if @d < 32;
        return $d[$n];
    },
    '%OH' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%H'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OH." if @d < 24;
        return $d[$n];
    },
    '%OI' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%I'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OI." if @d < 13;
        return$d[$n];
    },
    '%Om' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%m'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Om." if @d < 13;
        return $d[$n];
    },
    '%OM' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%M'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OM." if @d < 60;
        return $d[$n];
    },
    '%Op' => fun ($t, $l) { $formatter{'%p'}->($t, $l); }, # one %c spec in my_MM locale erroneously says %Op instead of %p
    '%OS' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%S'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OS." if @d < 60;
        return $d[$n];
    },
    '%OU' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%U'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OU." if @d < 54;
        return @d > 31 ? $d[$n] : $n;
    },
    '%Ou' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%u'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Ou." if @d < 8;
        return $d[$n];
    },
    '%OV' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%V'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OV." if @d < 54;
        return $d[$n];
    },
    '%OW' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%W'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %OW." if @d < 54;
        return @d > 31 ? $d[$n] : $n;
    },
    '%Ow' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%w'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Ow." if @d < 7;
        return $d[$n];
    },
    '%Oy' => fun ($t, $l) {
        my @d = @{ get_locale(digits => $l) };
        my $n = $formatter{'%y'}->($t, $l);
        return $n if @d == 0;
        croak "Not enough digits in alt_digits for $l to represent %Oy." if @d < 100;
        return $d[$n];
    },
    '%P'  => fun ($t, $l) { $formatter{'%p'}->($t, $l); }, # a few %r specs in some locales erroneously say %P instead of %p (wal_ET, ur_PK, pa_PK, iw_IL, he_IL, en_GB, dv_MV, cy_GB)
    '%p'  => fun ($t, $l) { get_locale(am_pm => $l)->[not $t->hour < 12]; },
    '%X'  => fun ($t, $l) { strftime($t, get_locale(time => $l), locale => $l); },
    '%x'  => fun ($t, $l) { strftime($t, get_locale(date => $l), locale => $l); },
    '%R'  => fun ($t, $l) { strftime($t, '%H:%M', locale => $l); },
    '%r'  => fun ($t, $l) { strftime($t, get_locale(time_ampm => $l), locale => $l); },
    '%S'  => fun ($t, $l) { sprintf '%02d', $t->second; },
    '%-S' => fun ($t, $l) { $t->second; },
    '%s'  => fun ($t, $l) { $t->epoch; },
    '%T'  => fun ($t, $l) { strftime($t, '%H:%M:%S', locale => $l); },
    '%t'  => fun ($t, $l) { "\t"; },
    '%U'  => fun ($t, $l) {
        my $t2 = $t->clone->day_of_year(1);
        $t2->day++ while $t2->day_of_week != 7;
        if ($t2->day_of_year > $t->day_of_year) { return "00"; }
        sprintf '%02d', int(($t->day_of_year - $t2->day_of_year) / 7) + 1;
    },
    '%-U' => fun ($t, $l) {
        my $t2 = $t->clone->day_of_year(1);
        $t2->day++ while $t2->day_of_week != 7;
        if ($t2->day_of_year > $t->day_of_year) { return "0"; }
        int(($t->day_of_year - $t2->day_of_year) / 7) + 1;
    },
    '%u'  => fun ($t, $l) { $t->day_of_week; },
    '%V'  => fun ($t, $l) { sprintf '%02d', $t->week; },
    '%-V' => fun ($t, $l) { $t->week; },
    '%v'  => fun ($t, $l) { strftime($t, '%e-%b-%Y', locale => $l); },
    '%W'  => fun ($t, $l) {
        my $t2 = $t->clone->day_of_year(1);
        $t2->day++ while $t2->day_of_week != 1;
        if ($t2->day_of_year > $t->day_of_year) { return "00"; }
        sprintf '%02d', int(($t->day_of_year - $t2->day_of_year) / 7) + 1;
    },
    '%-W' => fun ($t, $l) {
        my $t2 = $t->clone->day_of_year(1);
        $t2->day++ while $t2->day_of_week != 1;
        if ($t2->day_of_year > $t->day_of_year) { return "0"; }
        int(($t->day_of_year - $t2->day_of_year) / 7) + 1;
    },
    '%w'  => fun ($t, $l) { $t->day_of_week == 7 ? 0 : $t->day_of_week; },
    '%Y'  => fun ($t, $l) { sprintf '%04d', $t->year; },
    '%-Y' => fun ($t, $l) { $t->year; },
    '%y'  => fun ($t, $l) { sprintf '%02d', substr $t->year, -2; },
    '%-y' => fun ($t, $l) { substr $t->year, -2; },
    '%Z'  => fun ($t, $l) { $t->tz; },
    '%z'  => fun ($t, $l) { my $z = $t->offset; sprintf '%s%02s%02s', ($z > 0 ? '-' : '+'), (($z - ($z % 60)) / 60), ($z % 60); },
    '%%'  => fun ($t, $l) { '%'; },
);


fun strftime ($t, $fmt, :$locale = 'C') {
    my $str = '';
    my $pos = 0;
    while (defined(my $tok = get_fmt_tok($fmt, $pos))) {
        if (exists $formatter{$tok}) {
            $str .= $formatter{$tok}->($t, $locale) // '';
        } elsif ($tok =~ m/^%/) {
            croak "Unsupported format specifier: $tok"
        } else {
            $str .= $tok;
        }
    }

    return $str;
}

fun _fmt_era ($E, $t, $eras) {
    foreach my $era (grep defined, @{ $eras }) {
        my @fields = split /:/, $era;
        my %s = strptime($fields[2], "%-Y/%m/%d");
        $s{year}++ if $s{year} < 1;
        if ($t->year > $s{year}) {
            return $fields[5] if $E eq 'Y';
            return $fields[4] if $E eq 'C';
            return $fields[1] + $t->year - $s{year} if $E eq 'y';
        } elsif ($t->year == $s{year}) {
            require Time::C;
            my $s = Time::C->mktime(%s);
            if ($t->epoch >= $s->epoch) {
                return $fields[5] if $E eq 'Y';
                return $fields[4] if $E eq 'C';
                return $fields[1] + $t->year - $s{year} if $E eq 'y';
            }
        }
    }
    return "%$E";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::F - Formatting times.

=head1 VERSION

version 0.024

=head1 SYNOPSIS

  use Time::F; # strftime automatically imported
  use Time::C;
  use feature 'say';

  # "mån 31 okt 2016 14:21:57"
  say strftime(Time::C->now_utc(), "%c", locale => "sv_SE");

=head1 DESCRIPTION

Formats a time using L<Time::P/Format Specifiers>, according to specified locale.

=head1 FUNCTIONS

=head2 strftime

  my $str = strftime($t, $fmt);
  my $str = strftime($t, $fmt, locale => $locale);

Formats a time using the formats specifiers in C<$fmt>, under the locale rulses of C<$locale>.

=over

=item C<$t>

C<$t> should be a L<Time::C> time object.

=item C<$fmt>

C<$fmt> should be a format specifier string, see L<Time::P/Format Specifiers> for more details.

=item C<< locale => $locale >>

C<$locale> should be a locale. If not specified it defaults to C<C>.

=back

=head1 SEE ALSO

=over

=item L<Time::P>

=item L<Time::C>

=item L<Time::Moment>

=item L<Time::Piece>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
