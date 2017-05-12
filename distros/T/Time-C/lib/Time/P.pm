use strict;
use warnings;
package Time::P;
$Time::P::VERSION = '0.024';
# ABSTRACT: Parse times from strings.

use Carp qw/ croak /;
use Exporter qw/ import /;
use Function::Parameters qw/ :lax /;
use Data::Munge qw/ list2re /;
use List::Util qw/ uniq /;

use Time::C::Util qw/ get_fmt_tok get_locale /;

use constant DEBUG => 0;

our @EXPORT = qw/ strptime /;


my %parser; %parser = (
    '%A'  => fun (:$locale) {
        my @weekdays = @{ get_locale(weekdays => $locale) };
        my $re = list2re(@weekdays);
        return qr"(?<A>$re)";
    },
    '%a'  => fun (:$locale) {
        my @weekdays_abbr = @{ get_locale(weekdays_abbr => $locale) };
        my $re = list2re(@weekdays_abbr);
        return qr"(?<a>$re)";
    },
    '%B'  => fun (:$locale) {
        my @months = @{ get_locale(months => $locale) };
        my $re = list2re(@months);
        return qr"(?<B>$re)";
    },
    '%b'  => fun (:$locale) {
        my @months_abbr = @{ get_locale(months_abbr => $locale) };
        my $re = list2re(@months_abbr);
        return qr"(?<b>$re)";
    },
    '%C'  => fun () { qr"(?<C>[0-9][0-9])"; },
    '%-C' => fun () { qr"(?<C>[0-9][0-9]?)"; },
    '%c'  => fun (:$locale) { _compile_fmt(get_locale(datetime => $locale), locale => $locale); },
    '%D'  => fun () {
        return $parser{'%m'}->(), qr!/!, $parser{'%d'}->(), qr!/!, $parser{'%y'}->();
    },
    '%d'  => fun () { qr"(?<d>[0-9][0-9])"; },
    '%-d' => fun () { qr"(?<d>[0-9][0-9]?)"; },
    '%EC' => fun (:$locale) {
        my @eras = _get_eras(period => $locale);
        return $parser{'%C'}->() if not @eras;
        my $re = list2re(@eras);
        return qr"(?<EC>$re)";
    },
    '%Ec' => fun (:$locale) { _compile_fmt(get_locale(era_datetime => $locale), locale => $locale); },
    '%EX' => fun (:$locale) { _compile_fmt(get_locale(era_time => $locale), locale => $locale); },
    '%Ex' => fun (:$locale) { _compile_fmt(get_locale(era_date => $locale), locale => $locale); },
    '%EY' => fun (:$locale) {
        my @eras = _get_eras(full => $locale);
        return $parser{'%Y'}->() if not @eras;

        my @ret = map { my $re = join "", _compile_fmt($_, locale => $locale); qr/$re/ } uniq @eras;
        my $full_re = join "|", @ret;
        return qr/$full_re/;
    },
    '%Ey' => fun () { qr"(?<Ey>[0-9]+)"; },
    '%e'  => fun () { qr"(?:\s(?<e>[0-9])|(?<e>[0-9][0-9]))"; },
    '%-e' => fun () { qr"(?<e>[0-9][0-9]?)"; },
    '%F'  => fun () {
        return $parser{'%Y'}->(), qr/-/, $parser{'%m'}->(), qr/-/, $parser{'%d'}->();
    },
    '%G'  => fun () { qr"(?<G>[0-9]{4})"; },
    '%-G' => fun () { qr"(?<G>[0-9]{1,4})"; },
    '%g'  => fun () { qr"(?<g>[0-9][0-9])"; },
    '%-g' => fun () { qr"(?<g>[0-9][0-9]?)"; },
    '%H'  => fun () { qr"(?<H>[0-9][0-9])"; },
    '%-H' => fun () { qr"(?<H>[0-9][0-9]?)"; },
    '%h'  => fun (:$locale) { $parser{'%b'}->(locale => $locale) },
    '%I'  => fun () { qr"(?<I>[0-9][0-9])"; },
    '%-I' => fun () { qr"(?<I>[0-9][0-9]?)"; },
    '%j'  => fun () { qr"(?<j>[0-9]{3})"; },
    '%-j' => fun () { qr"(?<j>[0-9]{1,3})"; },
    '%k'  => fun () { qr"(?:\s(?<k>[0-9])|(?<k>[0-9][0-9]))"; },
    '%-k' => fun () { qr"(?<k>[0-9][0-9]?)"; },
    '%l'  => fun () { qr"(?:\s(?<l>[0-9])|(?<l>[0-9][0-9]))"; },
    '%-l' => fun () { qr"(?<l>[0-9][0-9]?)"; },
    '%M'  => fun () { qr"(?<M>[0-9][0-9])"; },
    '%-M' => fun () { qr"(?<M>[0-9][0-9]?)"; },
    '%m'  => fun () { qr"(?<m>[0-9][0-9])"; },
    '%-m' => fun () { qr"(?<m>[0-9][0-9]?)"; },
    '%n'  => fun () { qr"\s+"; },
    '%OC' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%d'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OC." if @d < 100;
        my $re = list2re(@d);
        return qr"(?<OC>$re)";
    },
    '%Od' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%d'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Od." if @d < 32;
        my $re = list2re(@d);
        return qr"(?<Od>$re)";
    },
    '%Oe' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%e'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Oe." if @d < 32;
        my $re = list2re(@d);
        return qr"(?<Oe>$re)";
    },
    '%OH' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%H'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OH." if @d < 24;
        my $re = list2re(@d);
        return qr"(?<OH>$re)";
    },
    '%OI' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%I'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OI." if @d < 13;
        my $re = list2re(@d);
        return qr"(?<OI>$re)";
    },
    '%OM' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%M'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OM." if @d < 60;
        my $re = list2re(@d);
        return qr"(?<OM>$re)";
    },
    '%Om' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%m'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Om." if @d < 13;
        my $re = list2re(@d);
        return qr"(?<Om>$re)";
    },
    '%Op' => fun (:$locale) { $parser{'%p'}->(locale => $locale); }, # one %c spec in my_MM locale erroneously says %Op instead of %p
    '%OS' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%S'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OS." if @d < 60;
        my $re = list2re(@d);
        return qr"(?<OS>$re)";
    },
    '%OU' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%U'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OU." if @d < 54;
        my $re = list2re(@d);
        return qr"(?<OU>$re)";
    },
    '%Ou' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%u'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Ou." if @d < 8;
        my $re = list2re(@d);
        return qr"(?<Ou>$re)";
    },
    '%OV' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%V'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OV." if @d < 54;
        my $re = list2re(@d);
        return qr"(?<OV>$re)";
    },
    '%OW' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%W'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %OW." if @d < 54;
        my $re = list2re(@d);
        return qr"(?<OW>$re)";
    },
    '%Ow' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%w'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Ow." if @d < 7;
        my $re = list2re(@d);
        return qr"(?<Ow>$re)";
    },
    '%Oy' => fun (:$locale) {
        my @d = @{ get_locale(digits => $locale) };
        return $parser{'%y'}->() if not @d;
        croak "Not enough digits in alt_digits for $locale to represent %Oy." if @d < 100;
        my $re = list2re(@d);
        return qr"(?<Oy>$re)";
    },
    '%P'  => fun (:$locale) { $parser{'%p'}->(locale => $locale); }, # a few %r specs in some locales erroneously say %P instead of %p (wal_ET, ur_PK, pa_PK, iw_IL, he_IL, en_GB, dv_MV, cy_GB)
    '%p'  => fun (:$locale) {
        my @am_pm = @{ get_locale(am_pm => $locale) };
        return () unless @am_pm;
        my $re = list2re(@am_pm);
        return qr"(?<p>$re)";
    },
    '%X'  => fun (:$locale) { _compile_fmt(get_locale(time => $locale), locale => $locale); },
    '%x'  => fun (:$locale) { _compile_fmt(get_locale(date => $locale), locale => $locale); },
    '%R'  => fun () {
        return $parser{'%H'}->(), qr/:/, $parser{'%M'}->();
    },
    '%r'  => fun (:$locale) { _compile_fmt(get_locale(time_ampm => $locale), locale => $locale); },
    '%S'  => fun () { qr"(?<S>[0-9][0-9])"; },
    '%-S' => fun () { qr"(?<S>[0-9][0-9]?)"; },
    '%s'  => fun () { qr"\s*(?<s>[0-9]+)"; },
    '%T'  => fun () {
        return $parser{'%H'}->(), qr/:/, $parser{'%M'}->(), qr/:/, $parser{'%S'}->();
    },
    '%t'  => fun () { qr"\s+"; },
    '%U'  => fun () { qr"(?<U>[0-9][0-9])"; },
    '%-U' => fun () { qr"(?<U>[0-9][0-9]?)"; },
    '%u'  => fun () { qr"(?<u>[0-9])"; },
    '%V'  => fun () { qr"(?<V>[0-9][0-9])"; },
    '%-V' => fun () { qr"(?<V>[0-9][0-9]?)"; },
    '%v'  => fun (:$locale) {
        return $parser{'%e'}->(), qr/-/, $parser{'%b'}->(locale => $locale), qr/-/, $parser{'%Y'}->()
    },
    '%W'  => fun () { qr"(?<W>[0-9][0-9])"; },
    '%-W' => fun () { qr"(?<W>[0-9][0-9]?)"; },
    '%w'  => fun () { qr"(?<w>[0-9])"; },
    '%Y'  => fun () { qr"(?<Y>-?[0-9]{4})"; },
    '%-Y' => fun () { qr"(?<Y>-?[0-9]{1,4})"; },
    '%y'  => fun () { qr"(?<y>[0-9][0-9])"; },
    '%-y' => fun () { qr"(?<y>[0-9][0-9]?)"; },
    '%Z'  => fun () { qr"(?<Z>\S+)"; },
    '%z'  => fun () { qr"(?<z>[-+][0-9][0-9](?::?[0-9][0-9])?)"; },
    '%%'  => fun () { qr"%"; },
);


fun strptime ($str, $fmt, :$locale = 'C', :$strict = 1, :$struct = {}) {
    my %parse = ();

    my @res = _compile_fmt($fmt, locale => $locale);

    croak "Could not match '%s' using '%s'.", $str, $fmt if not @res;

    @res = (qr/^/, @res, qr/$/) if $strict;

    my $re;
    while (defined ($re = shift @res) and $str =~ m/\G$re/gc) {
        warn "matched with $re\n" if DEBUG;
        %parse = (%parse, %+);
    }

    if (@res) {
        croak sprintf "Could not match '%s' using '%s'. Match failed at position %d (%s) while trying to match with /%s/.", $str, $fmt, pos($str), substr($str, pos($str)), $re;
    }

    $struct = { %$struct, _coerce_struct(\%parse, $struct, locale => $locale) };

    return %$struct;
}

fun _compile_fmt ($fmt, :$locale) {
    my @res = ();

    my $pos = 0;

    # _get_tok will increment $pos for us
    while (defined(my $tok = get_fmt_tok($fmt, $pos))) {
        if (exists $parser{$tok}) {
            my @p_res = $parser{$tok}->(locale => $locale);
            warn "pushing @p_res to list\n" if DEBUG;
            push @res, @p_res;
        } elsif ($tok =~ /^%/) {
            croak "Unsupported format specifier: $tok";
        } else {
            my $re = qr/\Q$tok\E/;
            warn "pushing $re to list\n" if DEBUG;
            push @res, $re;
        }
    }

    warn "returning @res\n" if DEBUG;
    return @res;
}

fun _get_mday ($struct, :$locale) {
    my $mday = $struct->{'d'};
    if (not defined $mday) { $mday = $struct->{'e'}; }
    if (not defined $mday and defined(my $Od = $struct->{Od})) {
        my @d = @{ get_locale(digits => $locale) };
        $mday = _get_index($Od, @d);
    }
    if (not defined $mday and defined(my $Oe = $struct->{Oe})) {
        my @d = @{ get_locale(digits => $locale) };
        $mday = _get_index($Oe, @d);
    }

    return $mday;
}

fun _get_year ($struct, :$locale) {
    my $wyear = 0;
    my $year = $struct->{'Y'};
    if (not defined $year) {
        if (defined $struct->{'G'}) {
            $year = $struct->{'G'};
            $wyear = 1;
        } elsif (defined $struct->{'C'}) {
            $year = $struct->{'C'} * 100;
            $year += $struct->{'y'} if defined $struct->{'y'};
            if (defined $struct->{'g'} and not defined $struct->{'y'}) {
                $year += $struct->{'g'};
                $wyear = 1;
            }
        } elsif (defined $struct->{'y'}) {
            $year = $struct->{'y'} + 1900;
            require Time::C;
            if ($year < (Time::C->now_utc()->year - 50)) { $year += 100; }
        } elsif (defined $struct->{'g'}) {
            $year = $struct->{'g'} + 1900;
            require Time::C;
            if ($year < (Time::C->now_utc()->year - 50)) { $year += 100; }
            $wyear = 1;
        }
    }
    if (not defined $year) {
        my $Ey = $struct->{Ey};
        my $EC = $struct->{EC};

        if (defined $EC) {
            my @eras = @{ get_locale(era => $locale) };
            foreach my $era (@eras) {
                my @fields = split /:/, $era;
                next if $EC ne $fields[4];

                my %s = strptime($fields[2], "%-Y/%m/%d");
                $s{year}++ if $s{year} < 1;
                $year = $s{year};
                $year += $Ey - $fields[1] if defined $Ey;
                $year-- if not defined $Ey;
                last;
            }
        } elsif (defined $Ey) {
            my @eras = @{ get_locale(era => $locale) };
            foreach my $era (@eras) {
                my @fields = split /:/, $era;

                my %s = strptime($fields[2], "%-Y/%m/%d");
                $s{year}++ if $s{year} < 1;
                require Time::C;
                next if $s{year} > Time::C->now_utc()->year;

                $year = $s{year} + $Ey - $fields[1];
                last;
            }
        }
    }
    if (not defined $year and defined(my $Oy = $struct->{Oy})) {
        my @d = @{ get_locale(digits => $locale) };
        if (defined(my $C = $struct->{C})) {
            $year = $C * 100;
        } elsif (defined(my $OC = $struct->{OC})) {
            $year = _get_index($OC, @d) * 100;
        } else {
            $year = 1900;
        }
        $year += _get_index($Oy, @d);
        if (not defined $struct->{C}) {
            require Time::C;
            if ($year < (Time::C->now_utc()->year - 50)) { $year += 100; }
        }
    }

    return ($year, $wyear);
}

fun _get_wday($struct, :$locale) {
    my $wday = $struct->{'u'} // $struct->{'w'};

    if (not defined $wday) {
        if (defined $struct->{'A'}) {
            $wday = _get_index($struct->{'A'}, @{ get_locale(weekdays => $locale) });
        } elsif (defined $struct->{'a'}) {
            $wday = _get_index($struct->{'a'}, @{ get_locale(weekdays_abbr => $locale) });
        }
    }
    if (not defined $wday) {
        if (defined(my $Ou = $struct->{Ou})) {
            my @d = @{ get_locale(digits => $locale) };
            $wday = _get_index($Ou, @d);
        } elsif (defined(my $Ow = $struct->{Ow})) {
            my @d = @{ get_locale(digits => $locale) };
            $wday = _get_index($Ow, @d);
        }
    }
    $wday = 7 if defined $wday and $wday == 0;

    return $wday;
}

fun _get_u_week ($struct, :$locale) {
    my $u_week = $struct->{U};

    if (not defined $u_week and defined(my $OU = $struct->{OU})) {
        my @d = @{ get_locale(digits => $locale) };
        $u_week = _get_index($OU, @d);
    }

    return $u_week;
}

fun _get_w_week ($struct, :$locale) {
    my $w_week = $struct->{W};

    if (not defined $w_week and defined(my $OW = $struct->{OW})) {
        my @d = @{ get_locale(digits => $locale) };
        $w_week = _get_index($OW, @d);
    }

    return $w_week;
}

fun _get_v_week ($struct, :$locale) {
    my $v_week = $struct->{V};

    if (not defined $v_week and defined(my $OV = $struct->{OV})) {
        my @d = @{ get_locale(digits => $locale) };
        $v_week = _get_index($OV, @d);
    }

    return $v_week;
}

fun _get_month ($struct, :$locale) {
    my $month = $struct->{'m'};
    if (not defined $month) {
        if (defined $struct->{'B'}) {
            $month = _get_index($struct->{'B'}, @{ get_locale(months => $locale) }) + 1;
        } elsif (defined $struct->{'b'}) {
            $month = _get_index($struct->{'b'}, @{ get_locale(months_abbr => $locale) }) + 1;
        }
    }
    if (not defined $month and defined(my $Om = $struct->{Om})) {
        my @d = @{ get_locale(digits => $locale) };
        $month = _get_index($Om, @d);
    }

    return $month;
}

fun _get_hour ($struct, :$locale) {
    my $hour = $struct->{'H'};
    if (not defined $hour) { $hour = $struct->{'k'}; }
    if (not defined $hour) {
        $hour = $struct->{'I'} // $struct->{'l'};
        if (defined $hour and length $struct->{'p'}) {
            if (_get_index($struct->{'p'}, @{ get_locale(am_pm => $locale) })) {
                # PM
                if ($hour < 12) { $hour += 12; }
            } else {
                # AM
                if ($hour == 12) { $hour = 0; }
            }
        }
    }

    if (not defined $hour and defined(my $OH = $struct->{OH})) {
        my @d = @{ get_locale(digits => $locale) };
        $hour = _get_index($OH, @d);
    } elsif (not defined $hour and defined(my $OI = $struct->{OI})) {
        my @d = @{ get_locale(digits => $locale) };
        $hour = _get_index($OI, @d);
        if (length $struct->{p}) {
            if (_get_index($struct->{p}, @{ get_locale(am_pm => $locale) })) {
                # PM
                if ($hour < 12) { $hour += 12; }
            } else {
                # AM
                if ($hour == 12) { $hour = 0; }
            }
        }
    }

    return $hour;
}

fun _get_minute ($struct, :$locale) {
    my $min = $struct->{'M'};

    if (not defined $min and defined(my $OM = $struct->{OM})) {
        my @d = @{ get_locale(digits => $locale) };
        $min = _get_index($OM, @d);
    }

    return $min;
}

fun _get_second ($struct, :$locale) {
    my $sec = $struct->{'S'};

    if (not defined $sec and defined(my $OS = $struct->{OS})) {
        my @d = @{ get_locale(digits => $locale) };
        $sec = _get_index($OS, @d);
    }

    return $sec;
}

fun _coerce_struct ($struct, $orig, :$locale) {
    # First, if we know the epoch, great
    my $epoch = $struct->{'s'};

    # Then set up as many date bits we know about
    #  year + day of year
    #  year + month + day of month
    #  year + week + day of week

    my ($year, $wyear) = _get_year($struct, locale => $locale);

    my $yday = $struct->{'j'};

    my $month = _get_month($struct, locale => $locale);

    my $mday = _get_mday($struct, locale => $locale);

    my $u_week = _get_u_week($struct, locale => $locale);
    my $w_week = _get_w_week($struct, locale => $locale);
    my $v_week = _get_v_week($struct, locale => $locale);

    my $wday = _get_wday($struct, locale => $locale);

    if (not defined $w_week and defined $u_week) {
        $w_week = $u_week;
        if (not defined $wday) { $wday = 7; } # if no wday defined, should set to first day of week, and since the u_week starts at sunday, wday = 7
        $w_week-- if $wday == 7;
    }

    if (not defined $v_week and defined $w_week) {
        if ($wyear) { croak "Can't strptime a %G/%g year with a %W/%U week"; }

        require Time::C;
        my $t = Time::C->new($year // $orig->{year} // Time::C->now_utc->year);
        $v_week = $w_week;
        if (($t->day_of_week > 1) and ($t->day_of_week < 5)) { $v_week++; }
    }

    if ($wyear and defined $v_week and $v_week > 1) {
        require Time::C;
        $year = Time::C->mktime(year => $year, week => $v_week)->year;
    } elsif (defined $v_week and $v_week > 1 and defined $year) {
        require Time::C;
        if (Time::C->mktime(year => $year, week => $v_week)->year == $year + 1) {
            $year-- if not defined $month;
        }
    } elsif (defined $v_week and $v_week > 1 and defined $orig->{year}) {
        require Time::C;
        if (Time::C->mktime(year => $orig->{year}, week => $v_week)->year == $orig->{year} + 1) {
            $year = $orig->{year} - 1 if not defined $month;
        }
    }

    # Next try to set up time bits -- these are pretty easy in comparison

    my $hour = _get_hour($struct, locale => $locale);

    my $min = _get_minute($struct, locale => $locale);

    my $sec = _get_second($struct, locale => $locale);

    # And last see if we have some timezone or at least offset info

    my $tz = $struct->{'Z'}; # should verify that it's a useful tz
    if (defined $tz) {
        require Time::C;
        undef $tz if not defined eval { Time::C->now($tz); };
    }

    my $offset = $struct->{'z'};

    my $offset_n = defined $offset ? _offset_to_minutes($offset) : undef;

    my %struct = ();

    $struct{second} = $sec if defined $sec;
    $struct{minute} = $min if defined $min;
    $struct{hour} = $hour if defined $hour;
    $struct{mday} = $mday if defined $mday;
    $struct{month} = $month if defined $month;
    $struct{week} = $v_week if defined $v_week;
    $struct{wday} = $wday if defined $wday;
    $struct{yday} = $yday if defined $yday;
    $struct{year} = $year if defined $year;
    $struct{epoch} = $epoch if defined $epoch;
    $struct{tz} = $tz if defined $tz;
    $struct{offset} = $offset_n if defined $offset_n;

    return %struct;
}

fun _offset_to_minutes ($offset) {
    my ($sign, $hours, $minutes) = $offset =~ m/^([+-])([0-9][0-9]):?([0-9][0-9])?$/;
    return $sign eq '+' ? ($hours * 60 + $minutes) : -($hours * 60 + $minutes);
}

fun _get_index ($needle, @haystack) {
    if (not @haystack and $needle eq '') { return 0; }

    foreach my $i (0 .. $#haystack) {
        return $i if $haystack[$i] eq $needle;
    }
    croak "Could not find $needle in the list.";
}

fun _get_eras ($type, $locale) {
    my @eras = @{ get_locale(era => $locale) };
    my @ret = map { my @fields = split /:/; $type eq 'period' ? $fields[4] : $fields[5] } @eras;

    return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::P - Parse times from strings.

=head1 VERSION

version 0.024

=head1 SYNOPSIS

  use Time::P; # strptime() automatically exported.
  use Time::C;

  # "2016-10-30T16:07:34Z"
  my $t = Time::C->mktime(strptime("sön okt 30 16:07:34 UTC 2016", "%a %b %d %T %Z %Y", locale => "sv_SE"));

=head1 DESCRIPTION

Parses a string to get a time out of it using L<Format Specifiers> reminiscent of C's C<scanf> and indeed C<strptime> functions.

=head1 FUNCTIONS

=head2 strptime

  my %struct = strptime($str, $fmt);
  my %struct = strptime($str, $fmt, locale => $locale, strict => $strict, struct => \%struct);

C<strptime> takes a string and a format which it parses the string with, and returns key-value pairs of the parsed bits of time.

=over

=item C<$str>

C<$str> is the string to parse.

=item C<$fmt>

C<$fmt> is the format specifier used to parse the C<$str>. If it can't match C<$str> it will throw an exception. See L<Format Specifiers> for details on the supported format specifiers.

=item C<< locale => $locale >>

C<$locale> is an optional parameter which defaults to C<C>. It is used to determine how the format specifiers C<%a>, C<%A>, C<%b>, C<%B>, C<%c>, C<%p>, and C<%r> match. See L<Format Specifiers> for more details.

=item C<< strict => $strict >>

C<$strict> is an optional boolean flag which defaults to true. If it is a true value, the C<$fmt> must describe the string entirely. If it is false, the C<$fmt> may describe only part of the string, and any extra bits, either before or after, are discarded.

=item C<< struct => \%struct >>

If passed a reference to a hash C<%struct>, that hash will be updated with the bits that were parsed from the string. The hash will also be equal to the key-value pairs being returned. If it is not supplied, a reference to an empty hash will be used in its stead.

=back

If the format reads in a timezone that isn't well-defined, it will be silently ignored, and any offset that is parsed will be used instead.

See L<Time::C/mktime> for making a C<Time::C> object out of the returned structure. Or see L<Time::C/strptime> for a constructor that will do it for you.

=head1 Format Specifiers

The format specifiers work in a format to parse distinct portions of a string. Any part of the format that isn't a format specifier will be matched verbatim. All format specifiers start with a C<%> character. Some implementations of C<strptime> will support some of them, and other implementations will support others.

Some format specifiers can have a C<-> inserted between the C<%> and the letter, and if so they will no longer need any leading whitespace or C<0> to be matched. The ones which support this are: C<%-C>, C<%-d>, C<%-e>, C<%-G>, C<%-g>, C<%-H>, C<%-I>, C<%-j>, C<%-k>, C<%-l>, C<%-M>, C<%-m>, C<%-S>, C<%-U>, C<%-V>, C<%-W>, C<%-Y>, and C<%-y>.

This implementation will support the ones described below:

=over

=item C<%A>

Full weekday, depending on the locale, e.g. C<söndag>.

=item C<%a>

Abbreviated weekday, depending on the locale, e.g. C<sön>.

=item C<%B>

Full month name, depending on the locale, e.g. C<oktober>.

=item C<%b>

Abbreviated month name, depending on the locale, e.g. C<okt>.

=item C<%C>

2 digit century, e.g. C<20> - C<20> actually means the C<21st> century.

If you specify C<%-C>, it will be 1 or 2 digits if the century is low enough.

=item C<%c>

The date and time representation for the current locale, e.g. C<sön okt 30 16:07:34 UTC 2016>.

=item C<%D>

Equivalent to C<%m/%d/%y>, e.g. C<10/30/16> - this is used mostly in the US. Internationally C<%F> is much preferred.

=item C<%d>

2 digit day of month, e.g. C<30>.

If you specify C<%-d>, it will be 1 or 2 digits if the day of the month is low enough.

=item C<%E*>

The C<%E*> format specifiers that are supported are:

=over

=item C<%Ec>

Similar to C<%c>, but using an alternate way of displaying the year. See C<%EY>, C<%EC>, and C<%Ey>.

=item C<%EC>

Similarly to C<%C>, it (usually) describes a period longer than 1 year, depending on the locale. There are only a few locales that define this: C<ja_JP>, C<lo_LA>, and C<th_TH>; in other locales it functions like C<%C>.

Taking the C<ja_JP> locale as an example, it defines a number of periods, ostensibly relating to when they got a new emperor, and these periods are what the C<%EC> represents rather than centuries like C<%C>.

=item C<%EX>

Similar to C<%x>, but using an alternate way of displaying the time. There are only a few locales that define this: C<lo_LA>, and C<th_TH>; in other locales it functions like C<%X>.

=item C<%Ex>

Similar to C<%X>, but using an alternate way of displaying the year. There are only a few locales that define this: C<ja_JP>, C<lo_LA>, and C<th_TH>; in other locales it functions like C<%x>. See C<%EY>, C<%EC>, and C<%Ey> for details on how the year is displayed.

=item C<%EY>

Similarly to C<%Y>, it describes a year fully, but depends on the C<%EC> and possibly the C<%Ey> of the locale. There are only a few locales that define this: C<ja_JP>, C<lo_LA>, and C<th_TH>; in other locales it functions like C<%Y>.

=item C<%Ey>

Similarly to C<%y>, it describes the number of years since the period, only C<%y>'s period is C<%C>, while C<%Ey>'s period is C<%EC>. There are only a few locales that define this: C<ja_JP>, C<lo_LA>, and C<th_TH>; in other locales it functions like C<%y>.

=back

=item C<%e>

1/2 digit day of month, space padded, e.g. C<30>.

If you specify C<%-e>, it will not be space padded if it is low enough.

=item C<%F>

Equivalent to C<%Y-%m-%d>, e.g. C<2016-10-30>.

=item C<%G>

Year, 4 digits, representing the week-based year since year 0, e.g. C<2016> - i.e. if the date being represented has a week that overlaps with the previous or next year, the year for any date in that week will count as the year that has 4 or more days of the week in it, counting from Monday til Sunday. Should be combined with a C<%V> week specifier (a C<%W> or C<%U> week specifier will not work).

If you specify C<%-G>, it will be 1, 2, 3, or 4 digits if the year is low enough.

=item C<%g>

Like C<%G> but without century, and which will be interpreted as being within 50 years of the current year, whether that means adding 1900 or 2000 to it, e.g. C<16>.

If you specify C<%-g>, it will be 1 or 2 digits if the year is low enough.

=item C<%H>

2 digit hour in 24-hour time, e.g. C<16>.

If you specify C<%-H>, it will be 1 or 2 digits if the hour is low enough.

=item C<%h>

Equivalent to C<%b>, e.g. C<okt>.

=item C<%I>

2 digit hour in 12-hour time, e.g. C<04>.

If you specify C<%-I>, it will be 1 or 2 digits if the hour is low enough.

=item C<%j>

3 digit day of the year, e.g. C<304>.

If you specify C<%-j>, it will be 1, 2, or 3 digits if the day of the year is low enough.

=item C<%k>

1/2 digit hour in 24-hour time, space padded, e.g. C<16>.

If you specify C<%-k>, it will not be space padded if it is low enough.

=item C<%l>

1/2 digit hour in 12-hour time, space padded, e.g. C< 4>.

If you specify C<%-l>, it will not be space padded if it is low enough.

=item C<%M>

2 digit minute, e.g. C<07>.

If you specify C<%-M>, it will be 1 or 2 digits if the minute is low enough.

=item C<%m>

2 digit month, e.g. C<10>.

If you specify C<%-m>, it will be 1 or 2 digits if the month is low enough.

=item C<%n>

Arbitrary whitespace, like C<m/\s+/> - if used as a formatting specifier rather than a parsing specifier, it will result in a C<\n> (i.e. a newline).

=item C<%O*>

The C<%O*> format specifiers work like their non-C<O> counterparts, except they use an alternate set of digits for representing the number depending on the locale. Not all C<%O*> specifiers are actually supported by all locales, as some only define numbers up to a certain point. Some don't specify an alternate set of digits at all, in which case they should work I<exactly> like their non-C<O> counterparts.

The C<%O*> format specifiers that are supported are:

=over

=item C<%OC>

=item C<%Od>

=item C<%Oe>

=item C<%OH>

=item C<%OI>

=item C<%OM>

=item C<%Om>

=item C<%OS>

=item C<%OU>

=item C<%Ou>

=item C<%OV>

=item C<%OW>

=item C<%Ow>

=item C<%Oy>

=back

=item C<%p>

Matches the locale version of C<a.m.> or C<p.m.>, if the locale has that. Otherwise matches the empty string.

=item C<%X>

The time representation for the current locale, e.g. C<16:07:34>.

=item C<%x>

The date representation for the current locale, e.g. C<2016-10-30>.

=item C<%R>

Equivalent to C<%H:%M>, e.g. C<16:07>.

=item C<%r>

The time representation with am/pm for the current locale. For example in the C<POSIX> locale, it is equivalent to C<%I:%M:%S %p>.

=item C<%S>

2 digit second, e.g. C<34>.

If you specify C<%-S>, it will be 1 or 2 digits if the second is low enough.

=item C<%s>

The epoch, i.e. the number of seconds since C<1970-01-01T00:00:00Z>.

=item C<%T>

Equivalent to C<%H:%M:%S>, e.g. C<16:07:34>.

=item C<%t>

Arbitrary whitespace, like C<m/\s+/> - if used as a formatting specifier rather than a parsing specifier, it will result in a C<\t> (i.e. a tab).

=item C<%U>

2 digit week number of the year, Sunday-based week, e.g. C<44>.

If you specify C<%-U>, it will be 1 or 2 digits if the week is low enough.

=item C<%u>

1 digit weekday, Monday-based week, e.g. C<7>.

=item C<%V>

2 digit week number of the year, Monday-based week, e.g. C<43>, where week C<1> is the first week of the year that has 4 days or more. Any preceding days will belong to the last week of the prior year, see C<%G>.

If you specify C<%-V>, it will be 1 or 2 digits if the week is low enough.

=item C<%v>

Equivalent to C<%e-%b-%Y>, which depends on the locale, e.g. C<30-okt-2016>.

=item C<%W>

2 digit week number of the year, Monday-based week, e.g. C<43>.

If you specify C<%-W>, it will be 1 or 2 digits if the week is low enough.

=item C<%w>

1 digit weekday, Sunday-based week, e.g. C<0>.

=item C<%Y>

Year, 4 digits, representing the full year since year 0, e.g. C<2016>.

If you specify C<%-Y>, it will be from 1 to 4 digits if the year is low enough.

=item C<%y>

2 digit year without century, which will be interpreted as being within 50 years of the current year, whether that means adding 1900 or 2000 to it, e.g. C<16>.

If you specify C<%-y>, it will be 1 or 2 digits if the year is low enough.

=item C<%Z>

Time zone name, e.g. C<CET>, or C<Europe/Stockholm>.

=item C<%z>

Offset from UTC in hours and minutes, or just hours, e.g. C<+0100>.

=item C<%%>

A literal C<%> sign.

=back

=head1 SEE ALSO

=over

=item L<Time::C>

The companion to this module, which can create an actual time representation from the structure we parsed.

=item L<Time::Piece>

Also provides a C<strptime()>, but it doesn't deal well with timezones or offsets.

=item L<POSIX::strptime>

Also provides a C<strptime()>, but it also doesn't deal well with timezones or offsets.

=item L<Time::Strptime>

Also provides a C<strptime()>, but it doesn't handle C<%c>, C<%x>, or C<%X> format specifiers at all, only supports a C<POSIX> version of C<%r>, and is arguably buggy with C<%a>, C<%A>, C<%b>, C<%B>, and C<%p>.

=item L<DateTime::Format::Strptime>

Provides an OO-interface for strptime, but it has the same issues as C<Time::Strptime>.

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
