use strict;
use warnings;
package Time::C;
$Time::C::VERSION = '0.024';
# ABSTRACT: Convenient time manipulation.

use overload (
    '""' => sub { shift->string },
    bool => sub { 1 },
    fallback => 1,
);

use Carp qw/ croak /;
use Function::Parameters qw/ :strict /;
use Time::C::Sentinel;
use Time::D;
use Time::P ();
use Time::F ();
use Time::Moment;
use Time::Zone::Olson;



method new ($c: $year =, $month =, $day =, $hour =, $minute =, $second =, $tz =) {
    my $t;
    my %defineds = (
        epoch_d => (defined($year) and defined($month) and defined($day) and defined($hour) and defined($minute) and defined($second)),
        year => defined($year),
        month => defined($month),
        mday => defined($day),
        week => 0,
        wday => 0,
        yday => 0,
        hour => defined($hour),
        minute => defined($minute),
        second => defined($second),
        tz_d => defined($tz),
        offset => 0,
    );

    if (not defined $year) {
        $t = $c->now_utc();
        %$t = ( %$t, %defineds );
        return $t;
    }

    my $tm = Time::Moment->new(year => $year, month => $month // 1, day => $day // 1, hour => $hour // 0, minute => $minute // 0, second => $second // 0, offset => 0);

    if (not defined $tz) { $tz = 'UTC'; }

    if ($tz ne 'UTC' and $tz ne 'GMT') {
        my $offset = _get_offset($tm->epoch, $tz);
        $tm = $tm->with_offset_same_local($offset);
        $offset = _get_offset($tm->epoch, $tz);
        $tm = $tm->with_offset_same_local($offset);
    }

    $t = $c->localtime($tm->epoch, $tz);
    %$t = (%$t, %defineds);
    return $t;
}


method mktime ($c: :$epoch =, :$second =, :$minute =, :$hour =, :$mday =, :$month =, :$wday =, :$week =, :$yday =, :$year =, :$tz =, :$offset =) {

    # Alright, time to try and construct a Time::C object with what we have
    # We'll start with the easiest one: epoch
    # Then go on to creating it from the date bits, and the time bits

    my $t;
    my %defineds = (
        epoch_d => defined($epoch),
        year => defined($year),
        month => defined($month),
        mday => defined($mday),
        week => defined($week),
        wday => defined($wday),
        yday => defined($yday),
        hour => defined($hour),
        minute => defined($minute),
        second => defined($second),
        tz_d => defined($tz),
        offset => defined($offset),
    );

    if (defined $epoch) {
        $t = Time::C->gmtime($epoch);

        if (defined $tz) {
            $t->tz = $tz;
        } elsif (defined $offset) {
            $t->offset = $offset;
        }

        $t->{tz_d} = $defineds{tz_d};

        return $t;
    } elsif (defined $year) { # We have a year at least...
        if (defined $month) {
            if (defined $mday) {
                $t = Time::C->new($year, $month, $mday);
            } else {
                $t = Time::C->new($year, $month);
            }
        } elsif (defined $week) {
            $t = Time::C->new($year);
            $t->day_of_week++ while ($t->week > 1);
            $t = $t->week($week)->day_of_week(1);

            if (defined $wday) { $t->day_of_week = $wday; }
            else { $t->{wday} = 0; }
        } elsif (defined $yday) {
            $t = Time::C->new($year)->day_of_year($yday);
        } else { # we have neither month, week, or day of year!
            $t = Time::C->new($year);
        }

        # Now add the time bits on top...
        if (defined $hour) { $t->hour = $hour; }
        if (defined $minute) { $t->minute = $minute; }
        if (defined $second) { $t->second = $second; }
    } else {
        # If we don't have a year, let's use the current year
        $year = Time::C->now($tz)->tz('UTC', 1)->year;
        if (defined $month) {
            if (defined $mday) {
                $t = Time::C->new($year, $month, $mday);
            } else {
                $t = Time::C->new($year, $month);
            }

            # Now add the time bits on top...
            if (defined $hour) { $t->hour = $hour; }
            if (defined $minute) { $t->minute = $minute; }
            if (defined $second) { $t->second = $second; }
        } elsif (defined $week) {
            $t = Time::C->new($year);
            $t->day_of_week++ while ($t->week > 1);
            $t = $t->week($week)->day_of_week(1);

            if (defined $wday) { $t->day_of_week = $wday; }
            else { $t->{wday} = 0; }

            # Now add the time bits on top...
            if (defined $hour) { $t->hour = $hour; }
            if (defined $minute) { $t->minute = $minute; }
            if (defined $second) { $t->second = $second; }
        } elsif (defined $yday) {
            $t = Time::C->new($year)->day_of_year($yday);

            # Now add the time bits on top...
            if (defined $hour) { $t->hour = $hour; }
            if (defined $minute) { $t->minute = $minute; }
            if (defined $second) { $t->second = $second; }
        } else {
            # We have neither year, month, week, or day of year ...
            # So let's just make a time for today's date
            $t = Time::C->now($tz)->second_of_day(0)->tz('UTC', 1);

            # Mark these as being undefined
            $t->{epoch_d} = $t->{tz_d} = $t->{offset} = $t->{year} =
              $t->{month} = $t->{mday} = $t->{week} = $t->{wday} = $t->{yday} =
              $t->{hour} = $t->{minute} = $t->{second} = 0;

            croak "Could not mktime: No date specified and no time given."
              if not defined $hour and not defined $minute and not defined $second;

            # And add the time bits on top...
            # - if hour not defined, use current hour
            # - if hour and minute not defined, use current minute
            if (defined $hour) { $t->hour = $hour; } else { $t->hour = Time::C->now($tz)->tz('UTC', 1)->hour; }
            if (defined $minute) { $t->minute = $minute; } elsif (not defined $hour) { $t->second_of_day = Time::C->now($tz)->tz('UTC', 1)->second(0)->second_of_day; }
            if (defined $second) { $t->second = $second; }
        }
        $t->{year} = 0;
    }

    # And last, adjust for timezone bits

    if (defined $tz) {
        $t = $t->tz($tz, 1);
    } elsif (defined $offset) {
        $t->_tm = $t->tm->with_offset_same_local($offset);
        $t->offset = $offset;
    }

    return $t;
}


method localtime ($c: $epoch, $tz = $ENV{TZ}) {
    my %defineds = (
        epoch_d => 1,
        year => 1,
        month => 1,
        mday => 1,
        week => 1,
        wday => 1,
        yday => 1,
        hour => 1,
        minute => 1,
        second => 1,
        tz_d => defined($tz),
        offset => 0,
    );
    $tz = 'UTC' unless defined $tz;
    _verify_tz($tz);
    bless {epoch => $epoch, tz => $tz, %defineds}, $c;
}


method gmtime ($c: $epoch) { $c->localtime( $epoch, 'UTC' ); }


method now ($c: $tz = $ENV{TZ}) { $c->localtime( time, $tz ); }


method now_utc ($c:) { $c->localtime( time, 'UTC' ); }


method from_string ($c: $str, :$format = undef, :$locale = 'C', :$strict = 1, :$tz = 'UTC') {
    my %p = _parse($str, $format, $tz, locale => $locale, strict => $strict);

    return $c->mktime(%p);
}


method strptime ($c: $str, $format, :$locale = 'C', :$strict = 1) {
    my %struct;
    if (ref $c) {
        my $t = $c;
        if ($t->{year}) { $struct{year} = $t->year; }
        if ($t->{month}) { $struct{month} = $t->month; }
        if ($t->{mday}) { $struct{mday} = $t->day; }
        if ($t->{week}) { $struct{week} = $t->week; }
        if ($t->{wday}) { $struct{wday} = $t->day_of_week; }
        if ($t->{yday}) { $struct{yday} = $t->day_of_year; }
        if ($t->{hour}) { $struct{hour} = $t->hour; }
        if ($t->{minute}) { $struct{minute} = $t->minute; }
        if ($t->{second}) { $struct{second} = $t->second; }
        if ($t->{tz_d}) { $struct{tz} = $t->{tz}; }
        if ($t->{offset}) { $struct{offset} = $t->offset; }
    }
    %struct = Time::P::strptime($str, $format, locale => $locale, strict => $strict, struct => \%struct);

    if (ref $c) {
        my $t = $c;

        if (defined $struct{tz}) {
            $t->tz = $struct{tz};
        } elsif (defined $struct{offset}) {
            $t->offset = $struct{offset};
        }

        if (defined $struct{epoch}) { return $t->epoch($struct{epoch}); }

        if (defined $struct{year}) { $t->year = $struct{year}; }

        if (defined $struct{month}) {
            $t->month = $struct{month};
            if (defined $struct{mday}) { $t->day = $struct{mday}; }
        } elsif (defined $struct{week}) {
            $t->week = $struct{week};
            if (defined $struct{wday}) { $t->day_of_week = $struct{wday}; }
        } elsif (defined $struct{yday}) {
            $t->day_of_year = $struct{yday};
        }

        if (defined $struct{hour}) { $t->hour = $struct{hour}; }
        if (defined $struct{minute}) { $t->minute = $struct{minute}; }
        if (defined $struct{second}) { $t->second = $struct{second}; }

        return $t;
    } else {
        return $c->mktime(%struct);
    }
}

fun _verify_tz ($tz) {
    _get_offset(time, $tz);
}

my %tz_offset = (
    -720 => 'Etc/GMT+12',
    -660 => 'Etc/GMT+11',
    -600 => 'Etc/GMT+10',
    -540 => 'Etc/GMT+9',
    -480 => 'Etc/GMT+8',
    -420 => 'Etc/GMT+7',
    -360 => 'Etc/GMT+6',
    -300 => 'Etc/GMT+5',
    -240 => 'Etc/GMT+4',
    -180 => 'Etc/GMT+3',
    -120 => 'Etc/GMT+2',
    -60  => 'Etc/GMT+1',
    0    => 'UTC',
    60   => 'Etc/GMT-1',
    120  => 'Etc/GMT-2',
    180  => 'Etc/GMT-3',
    240  => 'Etc/GMT-4',
    300  => 'Etc/GMT-5',
    360  => 'Etc/GMT-6',
    420  => 'Etc/GMT-7',
    480  => 'Etc/GMT-8',
    540  => 'Etc/GMT-9',
    600  => 'Etc/GMT-10',
    660  => 'Etc/GMT-11',
    720  => 'Etc/GMT-12',
    780  => 'Etc/GMT-13',
    840  => 'Etc/GMT-14',
);

fun _get_tz ($offset) {
    return 'UTC' unless $offset;

    return $tz_offset{$offset} if defined $tz_offset{$offset};

    my $min = $offset % 60;
    my $hour = int $offset / 60;
    my $sign = '+';
    if ($hour < 0) { $sign = '-'; $hour = -$hour; }

    return sprintf "%s%02s:%02s", $sign, $hour, $min;
}

fun _parse ($str, $format = undef, $tz = 'UTC', :$locale = 'C', :$strict = 1) {
    if (defined $format) {
        my %struct = ();
        my $e = eval { %struct = Time::P::strptime($str, $format, locale => $locale, strict => $strict); 1; };
        return %struct if $e;

        croak sprintf "Could not parse %s using %s: %s", $str, $format, $@;
    }

    my $tm = eval { Time::Moment->from_string($str); };
    croak sprintf "Could not parse %s.", $str if not defined $tm;

    my $epoch = $tm->epoch;
    my $offset = $tm->offset;

    my @ret = (epoch => $epoch, offset => $offset);
    if ($offset == Time::Zone::Olson->new({timezone => $tz})->local_offset($epoch)) {
        push @ret, tz => $tz;
    }

    return @ret;
}



method epoch ($t: $new_epoch = undef) :lvalue {
    my $epoch = $t->{epoch};

    my $setter = sub {
        $t->{epoch} = $_[0];

        %$t = (%$t, epoch_d => 1, year => 1, yday => 1, month => 1, mday => 1, week => 1, wday => 1, hour => 1,  minute => 1, second => 1, );

        return $t if defined $new_epoch;
        return $_[0];
    };

    return $setter->($new_epoch) if defined $new_epoch;

    sentinel value => $epoch, set => $setter;
}


method tz ($t: $new_tz = undef, $override = 0) :lvalue {
    my $setter = sub {
        _verify_tz($_[0]);

        if ($override) {
            my $l = Time::C->new($t->year, $t->month, $t->day, $t->hour, $t->minute, $t->second, $_[0]);
            $t->{epoch} = $l->epoch;
        }

        $t->{tz} = $_[0];
        $t->{tz_d} = 1;

        return $t if defined $new_tz;
        return $t->{tz};
    };

    return $setter->($new_tz) if defined $new_tz;

    sentinel value => $t->{tz}, set => $setter;
}

fun _get_offset ($epoch, $tz) {
    my $offset = eval { Time::Zone::Olson->new({timezone => $tz})
      ->local_offset($epoch); };

    if (not defined $offset) {
        if ($tz =~ /^([+-])(\d+):(\d+)$/) {
            my ($sign, $hour, $min) = ($1, $2, $3);
            $offset = 60 * $hour + $min;
            $offset = -$offset if $sign eq '-';
        }
    }

    croak sprintf "Unknown timezone %s.", $tz
      if not defined $offset;

    return $offset;
}


method offset ($t: $new_offset = undef) :lvalue {
    my $setter = sub {
        $t->{tz} = _get_tz($_[0]);
        $t->{offset} = 1;

        return $t if defined $new_offset;
        return $_[0];
    };

    return $setter->($new_offset) if defined $new_offset;

    my $offset = _get_offset($t->{epoch}, $t->{tz});

    sentinel value => $offset, set => $setter;
}


method tm ($t: $new_tm = undef) :lvalue {
    my $setter = sub {
        $t->_tm = $_[0];
        $t->epoch = $t->epoch; # update definedness values

        return $t if defined $new_tm;
        return $_[0];
    };

    return $setter->($new_tm) if defined $new_tm;

    sentinel value => $t->_tm(), set => $setter;
}

method _tm ($t: $new_tm = undef) :lvalue {
    $t->{tz} = 'UTC' if not defined $t->{tz};

    my $setter = sub {
        $t->{epoch} = $_[0]->with_offset_same_instant(0)->epoch;

        return $t if defined $new_tm;
        return $_[0];
    };

    return $setter->($new_tm) if defined $new_tm;

    my $tm = Time::Moment->from_epoch($t->{epoch});

    if ($t->{tz} ne 'GMT' and $t->{tz} ne 'UTC') {
        $tm = $tm->with_offset_same_instant($t->offset);
    }

    sentinel value => $tm, set => $setter;
}


# need to parse the @args specially since F::P can't handle the signature
method string ($t: @args) :lvalue {
    my ($new_str, $format, $locale, $strict) = (undef, undef, 'C', 1);
    if (@args % 2) { $new_str = shift @args; }
    my %args = @args;
    $format = delete $args{format} if exists $args{format};
    $locale = delete $args{locale} if exists $args{locale};
    $strict = delete $args{strict} if exists $args{strict};
    croak sprintf "In method string: no such named parameter: %s", sort keys %args if %args;

    $t->{tz} = 'UTC' if not defined $t->{tz};

    my $setter = sub {
        my %struct = _parse($_[0], $format, $t->{tz}, locale => $locale, strict => $strict);

        if (defined $struct{tz}) {
            $t->tz = $struct{tz};
        } elsif (defined $struct{offset}) {
            $t->offset = $struct{offset};
        }

        if (defined $struct{epoch}) { return $t->epoch($struct{epoch}); }

        if (defined $struct{year}) { $t->year = $struct{year}; }

        if (defined $struct{month}) {
            $t->month = $struct{month};
            if (defined $struct{mday}) { $t->day = $struct{mday}; }
        } elsif (defined $struct{week}) {
            $t->week = $struct{week};
            if (defined $struct{wday}) { $t->day_of_week = $struct{wday}; }
        } elsif (defined $struct{yday}) {
            $t->day_of_year = $struct{yday};
        }

        if (defined $struct{hour}) { $t->hour = $struct{hour}; }
        if (defined $struct{minute}) { $t->minute = $struct{minute}; }
        if (defined $struct{second}) { $t->second = $struct{second}; }

        return $t if defined $new_str;
        return $_[0];
    };

    return $setter->($new_str) if defined $new_str;

    my $str;
    if (defined $format) {
        $str = Time::F::strftime($t, $format, locale => $locale);
    } else {
        $str = $t->tm->to_string;
    }

    sentinel value => $str, set => $setter;
}


method strftime ($t: @args) :lvalue { $t->string(@args); }


method year ($t: $new_year = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->with_year($_[0]))->year;
        $t->{year} = 1;

        return $t if defined $new_year;
        return $ret;
    };

    return $setter->($new_year) if defined $new_year;

    sentinel value => $tm->year, set => $setter;
}


method quarter ($t: $new_quarter = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_months(3*$_[0] - $tm->month))->quarter;
        $t->{month} = 1;

        return $t if defined $new_quarter;
        return $ret;
    };

    return $setter->($new_quarter) if defined $new_quarter;

    sentinel value => $tm->quarter, set => $setter;
}


method month ($t: $new_month = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_months($_[0] - $tm->month))->month;
        $t->{month} = 1;

        return $t if defined $new_month;
        return $ret;
    };

    return $setter->($new_month) if defined $new_month;

    sentinel value => $tm->month, set => $setter;
}


method week ($t: $new_week = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_weeks($_[0] - $tm->week))->week;
        $t->{week} = 1;

        return $t if defined $new_week;
        return $ret;
    };

    return $setter->($new_week) if defined $new_week;

    sentinel value => $tm->week, set => $setter;
}


method day ($t: $new_day = undef) :lvalue { $t->day_of_month(@_) }


method day_of_month ($t: $new_day = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_days($_[0] - $tm->day_of_month))->day_of_month;
        $t->{mday} = 1;

        return $t if defined $new_day;
        return $ret;
    };

    return $setter->($new_day) if defined $new_day;

    sentinel value => $tm->day_of_month, set => $setter;
}


method day_of_year ($t: $new_day = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_days($_[0] - $tm->day_of_year))->day_of_year;
        $t->{yday} = 1;

        return $t if defined $new_day;
        return $ret;
    };

    return $setter->($new_day) if defined $new_day;

    sentinel value => $tm->day_of_year, set => $setter;
}


method day_of_quarter ($t: $new_day = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_days($_[0] - $tm->day_of_quarter))->day_of_quarter;
        $t->{mday} = 1;

        return $t if defined $new_day;
        return $ret;
    };

    return $setter->($new_day) if defined $new_day;

    sentinel value => $tm->day_of_quarter, set => $setter;
}


method day_of_week ($t: $new_day = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_days($_[0] - $tm->day_of_week))->day_of_week;
        $t->{wday} = 1;

        return $t if defined $new_day;
        return $ret;
    };

    return $setter->($new_day) if defined $new_day;

    sentinel value => $tm->day_of_week, set => $setter;
}


method hour ($t: $new_hour = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_hours($_[0] - $tm->hour))->hour;
        $t->{hour} = 1;

        return $t if defined $new_hour;
        return $ret;
    };

    return $setter->($new_hour) if defined $new_hour;

    sentinel value => $tm->hour, set => $setter;
}


method minute ($t: $new_minute = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_minutes($_[0] - $tm->minute))->minute;
        $t->{minute} = 1;

        return $t if defined $new_minute;
        return $ret;
    };

    return $setter->($new_minute) if defined $new_minute;

    sentinel value => $tm->minute, set => $setter;
}


method second ($t: $new_second = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_seconds($_[0] - $tm->second))->second;
        $t->{second} = 1;

        return $t if defined $new_second;
        return $ret;
    };

    return $setter->($new_second) if defined $new_second;

    sentinel value => $tm->second, set => $setter;
}


method second_of_day ($t: $new_second = undef) :lvalue {
    my $tm = $t->tm();

    my $setter = sub {
        my $ret = ($t->_tm = $tm->plus_seconds($_[0] - $tm->second_of_day))->second_of_day;
        $t->{second} = $t->{minute} = $t->{hour} = 1;

        return $t if defined $new_second;
        return $ret;
    };

    return $setter->($new_second) if defined $new_second;

    sentinel value => $tm->second_of_day, set => $setter;
}



method diff ($t: $t2) {
    my $epoch =
      ref $t2 ?
        $t2->can('epoch') ?
          $t2->epoch :
          croak "Object with no ->epoch method passed (". ref $t2 .")." :
        $t2;
    return Time::D->new($t->epoch, $epoch);
}


method clone($t:) {
    my $c = ref $t;

    my $t2 = { %$t };
    bless $t2, $c;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::C - Convenient time manipulation.

=head1 VERSION

version 0.024

=head1 SYNOPSIS

  use Time::C;

  my $t = Time::C->from_string('2016-09-23T04:28:30Z');

  # 2016-01-01T04:28:30Z
  $t->month = $t->day = 1;

  # 2016-01-01T00:00:00Z
  $t->hour = $t->minute = $t->second = 0;

  # 2016-02-04T00:00:00Z
  $t->month += 1; $t->day += 3;

  # 2016-03-03T00:00:00Z
  $t->day += 28;

  # print all days of the week (2016-02-29T00:00:00Z to 2016-03-06T00:00:00Z)
  $t->day_of_week = 1;
  do { say $t } while ($t->day_of_week++ < 7);

=head1 DESCRIPTION

Makes manipulating time structures more convenient. Internally uses L<Time::Moment>, and L<Time::Zone::Olson>.

=head1 CONSTRUCTORS

=head2 new

  my $t = Time::C->new();
  my $t = Time::C->new($year);
  my $t = Time::C->new($year, $month);
  my $t = Time::C->new($year, $month, $day);
  my $t = Time::C->new($year, $month, $day, $hour);
  my $t = Time::C->new($year, $month, $day, $hour, $minute);
  my $t = Time::C->new($year, $month, $day, $hour, $minute, $second);
  my $t = Time::C->new($year, $month, $day, $hour, $minute, $second, $tz);

Creates a Time::C object for the specified time, or the current time if no C<$year> is specified.

=over

=item C<$year>

This is the year. If not specified, C<new()> will call C<now_utc()>. The year is 1-based and starts with year 1 corresponding to 1 AD. Legal values are in the range 1-9999.

=item C<$month>

This is the month. If not specified it defaults to C<1>. The month is 1-based and starts with month 1 corresponding to January. Legal values are in the range 1-12.

=item C<$day>

This is the day of the month. If not specified it defaults to C<1>. The day is 1-based and starts with day 1 being the first day of the month. Legal values are in the range 1-31.

=item C<$hour>

This is the hour. If not specified it defaults to C<0>. The hour is 0-based and starts with hour 0 corresponding to midnight. Legal values are in the range 0-23.

=item C<$minute>

This is the minute. If not specified it defaults to C<0>. The minute is 0-based and starts with minute 0 being the first minute of the hour. Legal values are in the range 0-59.

=item C<$second>

This is the second. If not specified it defaults to C<0>. The second is 0-based and starts with second 0 being the first second of the minute. Legal values are in the range 0-59.

=item C<$tz>

This is the timezone specification such as C<Europe/Stockholm> or C<UTC>. If not specified it defaults to C<UTC>.

=back

=head2 mktime

  my $t = Time::C->mktime(
    epoch => $epoch,
    second => $second,
    minute => $minute,
    hour => $hour,
    mday => $mday,
    month => $month,
    wday => $wday,
    week => $week,
    yday => $yday,
    year => $year,
    tz => $tz,
    offset => $offset,
  );

Creates a Time::C object for the specified arguments. All the arguments are optional, as long as there is at least one way to specify some kind of time with them.

If there is no date specified, it will default to today's date. If there is no timezone or offset specified, it will default to UTC. If there is a date, but no time specified, it will default to midnight.

=over

=item C<< epoch => $epoch >>

If the C<$epoch> is specified, it overrides all the other options but C<$tz> and C<$offset>, and this basically becomes a call to C<< Time::C->gmtime($epoch); >>, applying the C<$tz> or C<$offset> afterwards.

=item C<< second => $second >>

C<$second> sets the second of the day/hour/minute, depending on what other options were specified.

=item C<< minute => $minute >>

C<$minute> sets the minute of the day/hour, depending on what other options were specified.

=item C<< hour => $hour >>

C<$hour> sets the hour of the day.

=item C<< mday => $mday >>

C<$mday> sets the day of the month, if a C<$month> was specified.

=item C<< month => $month >>

C<$month> sets the month of the year. If no C<$mday> is specified, it will default to the C<1st> day of the month.

=item C<< wday => $wday >>

C<$wday> sets the day of the week, if a C<$week> was specified and no C<$month> was specified.

=item C<< week => $week >>

C<$week> sets the week of the year if no C<$month> was specified. If no C<$wday> was specified, it will default to the C<1st> day of the week, i.e. C<Monday>. 

=item C<< yday => $yday >>

C<$yday> sets the day of the year if neither C<$month> or C<$week> was specified.

=item C<< year => $year >>

C<$year> specifies the year, and if no C<$month>, C<$week>, or C<$yday> is specified, the day will default to C<January 1st>.

=item C<< tz => $tz >>

C<$tz> specifies the timezone, and will default to C<UTC> if neither C<$tz> or C<$offset> is given.

=item C<< offset => $offset >>

C<$offset> specifies the offset from C<UTC> in minutes, and will default to C<0> if neither C<$tz> nor C<$offset> are given.

=back

=head2 localtime

  my $t = Time::C->localtime($epoch);
  my $t = Time::C->localtime($epoch, $tz);

Creates a Time::C object for the specified C<$epoch> and optional C<$tz>.

=over

=item C<$epoch>

This is the time in seconds since the system epoch, usually C<1970-01-01T00:00:00Z>.

=item C<$tz>

This is the timezone specification, such as C<Europe/Stockholm> or C<UTC>. If not specified defaults to the timezone specified in C<$ENV{TZ}>, or C<UTC> if that is unspecified.

=back

=head2 gmtime

  my $t = Time::C->gmtime($epoch);

Creates a Time::C object for the specified C<$epoch>. The timezone will be C<UTC>.

=over

=item C<$epoch>

This is the time in seconds since the system epoch, usually C<1970-01-01T00:00:00Z>.

=back

=head2 now

  my $t = Time::C->now();
  my $t = Time::C->now($tz);

Creates a Time::C object for the current epoch in the timezone specified in C<$tz> or C<$ENV{TZ}> or C<UTC> if the first two are unspecified.

=over

=item C<$tz>

This is the timezone specification, such as C<Europe/Stockholm> or C<UTC>. If not specified defaults to the timezone specified in C<$ENV{TZ}>, or C<UTC> if that is unspecified.

=back

=head2 now_utc

  my $t = Time::C->now_utc();

Creates a Time::C object for the current epoch in C<UTC>.

=head2 from_string

  my $t = Time::C->from_string($str);
  my $t = Time::C->from_string($str, format => $format);
  my $t = Time::C->from_string($str, format => $format, locale => $locale);
  my $t = Time::C->from_string($str, format => $format, locale => $locale, strict => $strict);
  my $t = Time::C->from_string($str, format => $format, locale => $locale, strict => $strict, tz => $tz);

Creates a Time::C object for the specified C<$str>, using the optional C<$format> to parse it, and the optional C<$tz> to set an unambigous timezone, if it matches the offset the parsing operation gave.

=over

=item C<$str>

This is the string that will be parsed by either L<Time::P/strptime> or L<Time::Moment/from_string>.

=item C<< format => $format >>

If specified, will be passed to L<Time::P/strptime> for parsing. Otherwise, L<Time::Moment/from_string> will be used.

=item C<< locale => $locale >>

If C<strptime> is used for parsing, it will be given the specified C<$locale>. Defaults to C<C>.

=item C<< strict => $strict >>

If C<strptime> is used for parsing, it will be given the specified C<$strict>. Defaults to C<1>.

=item C<< tz => $tz >>

If there is no valid timezone specified in the format, but C<$tz> is given and matches the offset, then C<$tz> will be set as the timezone. If it doesn't match, and there was no valid timezone specified in the format, a generic timezone matching the offset will be set, such as C<UTC> for an offset of C<0>. This variable will also default to C<UTC>.

=back

=head2 strptime

  my $t = Time::C->strptime($str, $format);
  my $t = Time::C->strptime($str, $format, locale => $locale);
  my $t = Time::C->strptime($str, $format, locale => $locale, strict => $strict);

  $t = $t->strptime($str, $format);
  $t = $t->strptime($str, $format, locale => $locale);
  $t = $t->strptime($str, $format, locale => $locale, strict => $strict);

Creates a Time::C object for the specified C<$str> using the C<$format> to parse it with L<Time::P/strptime>.

This doesn't need to be used solely as a constructor; if it's called on an already existing C<Time::C> object, the values parsed from the C<$str> will be updated in the object, following the same rules as C<< Time::C->mktime >> for precedence (i.e. if an epoch is supplied, none of the other values matter, and if a month is supplied, the weeks and weekdays won't be considered, and so on).

=over

=item C<$str>

This is the string that will be parsed by L<Time::P/strptime>.

=item C<$format>

This is the format that L<Time::P/strptime> will be given.

=item C<< locale => $locale >>

Gives the C<$locale> parameter to L<Time::P/strptime>. Defaults to C<C>.

=item C<< strict => $strict >>

Gives the C<$strict> parameter to L<Time::P/strptime>. Defaults to C<1>.

=back

=head1 ACCESSORS

These accessors will work as C<LVALUE>s, meaning you can assign to them to change the time being represented.

Note that an assignment expression will return the I<computed> value rather than the assigned value. This means that in the expression C<< my $wday = $t->day_of_week = 8; >> the value assigned to C<$wday> will be C<1> because the value returned from the day_of_week assignment wraps around after 7, and in fact starts the subsequent week. Similarly in the expression C<< my $mday = $t->month(2)->day_of_month = 30; >> the value assigned to C<$mday> will be either C<1> or C<2> depending on if it's a leap year or not, and the month will have changed to C<3>.

=head2 epoch

  my $epoch = $t->epoch;
  $t->epoch = $epoch;
  $t->epoch += 3600;
  $t->epoch++;
  $t->epoch--;

  $t = $t->epoch($new_epoch);

Returns or sets the epoch, i.e. the number of seconds since C<1970-01-01T00:00:00Z>.

If the form C<< $t->epoch($new_epoch) >> is used, it likewise changes the epoch but returns the entire object.

=head2 tz

  my $tz = $t->tz;
  $t->tz = $tz;

  $t = $t->tz($new_tz);
  $t = $t->tz($new_tz, $override);

Returns or sets the timezone. If the timezone can't be recognised it dies.

If the form C<< $t->tz($new_tz) >> is used, it likewise changes the timezone but returns the entire object.

If C<$override> is a C<true> value, it changes the C<< $t->epoch >> as well, so that the date/time remains the same, but in a new timezone.

=head2 offset

  my $offset = $t->offset;
  $t->offset = $offset;
  $t->offset += 60;

  $t = $t->offset($new_offset);

Returns or sets the current offset in minutes. If the offset is set, it tries to find a generic C<Etc/GMT+X> or C<+XX:XX> timezone that matches the offset and updates the C<tz> to this. If it fails, it dies with an error.

If the form C<< $t->offset($new_offset) >> is used, it likewise sets the timezone from C<$new_offset> but returns the entire object.

=head2 tm

  my $tm = $t->tm;
  $t->tm = $tm;

  $t = $t->tm($new_tm);

Returns a Time::Moment object for the current epoch and offset. On setting, it changes the current epoch.

If the form C<< $t->tm($new_tm) >> is used, it likewise changes the current epoch but returns the entire object.

=head2 string

  my $str = $t->string;
  my $str = $t->string(format => $format);
  my $str = $t->string(format => $format, locale => $locale);
  $t->string = $str;
  $t->string(format => $format) = $str;
  $t->string(format => $format, locale => $locale) = $str;
  $t->string(format => $format, strict => $strict) = $str;
  $t->string(format => $format, locale => $locale, strict => $strict) = $str;

  $t = $t->string($new_str, format => $format);
  $t = $t->string($new_str, format => $format, locale => $locale);
  $t = $t->string($new_str, format => $format, strict => $strict);
  $t = $t->string($new_str, format => $format, locale => $locale, strict => $strict);

Renders the current time to a string using the optional strftime C<$format> and C<$locale>. If the C<$format> is not given it defaults to C<undef>. When setting this value, it tries to parse the string using L<Time::P/strptime> with the C<$format>, C<$locale>, and C<$strict> settings, or L<Time::Moment/from_string> if no C<$format> was given.

If the format specifies a timezone, it will be updated if it is valid. If not, it checks if the detected C<offset> matches the current C<tz>, and if so, the C<tz> is kept, otherwise it will get changed to a generic C<tz> in the form of C<Etc/GMT+X> or C<+XX:XX>.

If the form C<< $t->string($new_str) >> is used, it likewise updates the epoch and timezone but returns the entire object.

=over

=item C<$new_str>

If specified, it will update the object by parsing the C<$new_str> with L<Time::P/strptime> if a C<$format> was passed, or L<Time::Moment/from_string> otherwise.

=item C<< format => $format >>

If specified, will be passed to L<Time::P/strptime> for parsing, or L<Time::F/strftime> for formatting.

=item C<< locale => $locale >>

If the C<$format> contains a locale-specific format specifier (see L<Time::P/Format Specifiers>), it will get the locale data for C<$locale>. Defaults to C<C>.

=item C<< strict => $strict >>

If C<strptime> is used for parsing, it will be given the specified C<$strict>. Defaults to C<1>.

=back

=head2 strftime

Functions exactly like C<string>.

=head2 year

  my $year = $t->year;
  $t->year = $year;
  $t->year += 10;
  $t->year++;
  $t->year--;

  $t = $t->year($new_year);

Returns or sets the current year, updating the epoch accordingly.

If the form C<< $t->year($new_year) >> is used, it likewise sets the current year but returns the entire object.

The year is 1-based where the year 1 corresponds to 1 AD. Legal values are in the range 1-9999.

=head2 quarter

  my $quarter = $t->quarter;
  $t->quarter = $quarter;
  $t->quarter += 4;
  $t->quarter++;
  $t->quarter--;

  $t = $t->quarter($new_quarter);

Returns or sets the current quarter of the year, updating the epoch accordingly.

If the form C<< $t->quarter($new_quarter) >> is used, it likewise sets the current quarter but returns the entire object.

The quarter is 1-based where quarter 1 is the first three months of the year. Legal values are in the range 1-4.

=head2 month

  my $month = $t->month;
  $t->month = $month;
  $t->month += 12;
  $t->month++;
  $t->month--;

  $t = $t->month($new_month);

Returns or sets the current month of the year, updating the epoch accordingly.

If the form C<< $t->month($new_month) >> is used, it likewise sets the month but returns the entire object.

The month is 1-based where month 1 is January. Legal values are in the range 1-12.

=head2 week

  my $week = $t->week;
  $t->week = $week;
  $t->week += 4;
  $t->week++;
  $t->week--;

  $t = $t->week($new_week);

Returns or sets the current week or the year, updating the epoch accordingly.

If the form C<< $t->week($new_week) >> is used, it likewise sets the current week but returns the entire object.

The week is 1-based where week 1 is the first week of the year according to ISO 8601. The first week may actually have some days in the previous year, and the last week may have some days in the subsequent year. Legal values are in the range 1-53.

=head2 day

  my $day = $t->day;
  $t->day = $day;
  $t->day += 31;
  $t->day++;
  $t->day--;

  $t = $t->day($new_day);

Returns or sets the current day of the month, updating the epoch accordingly.

If the form C<< $t->day($new_day) >> is used, it likewise sets the current day of the month but returns the entire object.

The day is 1-based where day 1 is the first day of the month. Legal values are in the range 1-31.

=head2 day_of_month

Functions exactly like C<day>.

=head2 day_of_year

  my $yday = $t->day_of_year;
  $t->day_of_year = $yday;
  $t->day_of_year += 365;
  $t->day_of_year++;
  $t->day_of_year--;

  $t = $t->day_of_year($new_day);

Returns or sets the current day of the year, updating the epoch accordingly.

If the form C<< $t->day_of_year($new_day) >> is used, it likewise sets the current day of the year but returns the entire object.

The day is 1-based where day 1 is the first day of the year. Legal values are in the range 1-366.

=head2 day_of_quarter

  my $qday = $t->day_of_quarter;
  $t->day_of_quarter = $qday;
  $t->day_of_quarter += 90;
  $t->day_of_quarter++;
  $t->day_of_quarter--;

  $t = $t->day_of_quarter($new_day);

Returns or sets the current day of the quarter, updating the epoch accordingly.

If the form C<< $t->day_of_quarter($new_day) >> is used, it likewise sets the current day of the quarter but returns the entire object.

The day is 1-based where day 1 is the first day in the first month of the quarter. Legal values are in the range 1-92.

=head2 day_of_week

  my $wday = $t->day_of_week;
  $t->day_of_week = $wday;
  $t->day_of_week += 7;
  $t->day_of_week++;
  $t->day_of_week--;

  $t = $t->day_of_week($new_day);

Returns or sets the current day of the week, updating the epoch accordingly. This module uses L<Time::Moment> which counts days in the week starting from 1 with Monday, and ending on 7 with Sunday.

If the form C<< $t->day_of_week($new_day) >> is used, it likewise sets the current day of the week but returns the entire object.

The day is 1-based where day 1 is Monday. Legal values are in the range 1-7.

=head2 hour

  my $hour = $t->hour;
  $t->hour = $hour;
  $t->hour += 24;
  $t->hour++;
  $t->hour--;

  $t = $t->hour($new_hour);

Returns or sets the current hour of the day, updating the epoch accordingly.

If the form C<< $t->hour($new_hour) >> is used, it likewise sets the current hour but returns the entire object.

The hour is 0-based where hour 0 is midnight. Legal values are in the range 0-23.

=head2 minute

  my $minute = $t->minute;
  $t->minute = $minute;
  $t->minute += 60;
  $t->minute++;
  $t->minute--;

  $t = $t->minute($new_minute);

Returns or sets the current minute of the hour, updating the epoch accordingly.

If the form C<< $t->minute($new_minute) >> is used, it likewise sets the current minute but returns the entire object.

The minute is 0-based where minute 0 is the first minute of the hour. Legal values are in the range 0-59.

=head2 second

  my $second = $t->second;
  $t->second = $second;
  $t->second += 60;
  $t->second++;
  $t->second--;

  $t = $t->second($new_second);

Returns or sets the current second of the minute, updating the epoch accordingly.

If the form C<< $t->second($new_second) >> is used, it likewise sets the current second but returns the entire object.

The second is 0-based where second 0 is the first second of the minute. Legal values are in the range 0-59.

=head2 second_of_day

  my $second = $t->second_of_day;
  $t->second_of_day = $second;
  $t->second_of_day += 86400;
  $t->second_of_day++;
  $t->second_of_day--;

  $t = $t->second_of_day($new_second);

Returns or sets the current second of the day, updating the epoch accordingly.

If the form C<< $t->second_of_day($new_second) >> is used, it likewise sets the current second but returns the entire object.

The second is 0-based where second 0 is the first second of the day. Legal values are in the range 0-86399.

=head1 METHODS

=head2 diff

  my $d = $t1->diff($t2);
  my $d = $t1->diff($epoch);

Creates a L<Time::D> object from C<$t1> and C<$t2> or C<$epoch>. It accepts either an arbitrary object that has an C<< ->epoch >> accessor returning an epoch, or a straight epoch.

=head2 clone

  my $t2 = $t1->clone();

Returns a copy of C<$t1>.

=head1 SEE ALSO

=over

=item L<Time::D>

Like C<Time::C> but for durations.

=item L<Time::R>

If you need C<Time::C> times to recurr at regular intervals.

=item L<Time::F>

For formatting strings using an strftime format.

=item L<Time::P>

For parsing times from strings.

=item L<Time::Moment>

This implements most of the logic of this module.

=item L<Time::Zone::Olson>

Interfaces with the Olson timezone database.

=item L<Time::Piece>

A great time library, which is even in core perl.

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
