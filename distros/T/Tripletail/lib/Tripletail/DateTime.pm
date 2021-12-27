# -----------------------------------------------------------------------------
# Tripletail::DateTime - 日付と時刻を扱う
# -----------------------------------------------------------------------------
package Tripletail::DateTime;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Tripletail;
use Tripletail::DateTime::Calendar::Gregorian qw(toGregorian fromGregorian fromGregorianRollOver addGregorianMonthsClip addGregorianYearsClip);
use Tripletail::DateTime::Calendar::MonthDay qw(monthLength);
use Tripletail::DateTime::Calendar::OrdinalDate qw(toOrdinalDate isGregorianLeapYear);
use Tripletail::DateTime::Calendar::WeekDate qw(toWeekDate);
use Tripletail::DateTime::Clock::POSIX qw(posixDayLength posixSecondsToUTCTime utcTimeToPOSIXSeconds);
use Tripletail::DateTime::Clock::UTC qw(getCurrentTime);
use Tripletail::DateTime::Format::Apache qw(parseApacheDateTime);
use Tripletail::DateTime::Format::DateCmd qw(parseDateCmdDateTime);
use Tripletail::DateTime::Format::Generic qw($RE_GENERIC_TIMEZONE parseGenericDateTime parseGenericTimeZone renderGenericTimeZone);
use Tripletail::DateTime::Format::RFC733 qw(parseRFC733DateTime renderRFC733DateTime);
use Tripletail::DateTime::Format::RFC822 qw($RE_RFC822_TIMEZONE parseRFC822DateTime renderRFC822DateTime parseRFC822TimeZone renderRFC822TimeZone);
use Tripletail::DateTime::Format::W3CDTF qw($RE_W3CDTF_TIMEZONE parseW3CDTF parseW3CDTFTimeZone renderW3CDTF renderW3CDTFTimeZone);
use Tripletail::DateTime::JPEra qw(parseJPEra renderJPEra);
use Tripletail::DateTime::JPHoliday ();
use Tripletail::DateTime::LocalTime qw(getCurrentTimeZone timeToTimeOfDay timeOfDayToTime utcToLocalTime localTimeToUTC);
use Tripletail::DateTime::Math qw(quot widenYearOf2Digits);

our @WDAY_NAME       = qw(Sun    Mon    Tue     Wed       Thu      Fri    Sat     );
our @WDAY_NAME_LONG  = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

our @J_WDAY_NAME     = qw(日 月 火 水 木 金 土);

our @MONTH_NAME      = qw(Jan     Feb      Mar   Apr   May Jun  Jul  Aug    Sep       Oct     Nov      Dec     );
our @MONTH_NAME_LONG = qw(January February March April May June July August September October November December);

our @J_MONTH_NAME    = qw(睦月 如月 弥生 卯月 皐月 水無月 文月 葉月 長月 神無月 霜月 師走);

our @ANIMAL_NAME     = qw(子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥);

sub __a2h {
    my $i = 0;
    return map { $_ => ++$i } @_;
}

sub __a2r {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/;
}

1;

use fields qw(localDay localDayTime timeZone);

sub _new {
    my Tripletail::DateTime $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{localDay    } = undef; # Modified Julian Day (integer)
    $this->{localDayTime} = undef; # Number of seconds from midnight (integer)
    $this->{timeZone    } = undef; # Number of minutes offset from UTC (integer)

    $this->set(@_);
    return $this;
}

sub clone {
    my Tripletail::DateTime $this = shift;

    return __PACKAGE__->_new($this);
}

my @PARSERS = (
    \&parseGenericDateTime,
    \&parseDateCmdDateTime,
    \&parseApacheDateTime,
    \&parseRFC733DateTime,
    \&parseRFC822DateTime,
    \&parseW3CDTF
   );
sub set {
    my Tripletail::DateTime $this = shift;
    my                      $val  = shift;

    if (!defined $val) {
        # Set it to the current date and time.
        my $tz          = getCurrentTimeZone();
        my ($day, @tod) = utcToLocalTime($tz, getCurrentTime());

        $this->{localDay    } = $day;
        $this->{localDayTime} = timeOfDayToTime(@tod);
        $this->{timeZone    } = $tz;
    }
    elsif (ref $val) {
        if (UNIVERSAL::isa($val, __PACKAGE__)) {
            %$this = %$val;
        }
        else {
            die __PACKAGE__."#set: arg[1] is a reference. (第1引数がリファレンスです)\n";
        }
    }
    else {
        foreach my $parser (@PARSERS) {
            if (my ($localDay, $localDayTime, $timeZone) = $parser->($val)) {
                $this->{localDay    } = $localDay;
                $this->{localDayTime} = $localDayTime;
                $this->{timeZone    } = $timeZone;
                return $this;
            }
        }

        die __PACKAGE__."#set: failed to parse the date: $val (不正な日付形式です)\n";
    }
}

sub setEpoch {
    my Tripletail::DateTime $this  = shift;
    my                      $epoch = shift;

    if (!defined $epoch) {
        die __PACKAGE__."#setEpoch: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $epoch) {
        die __PACKAGE__."#setEpoch: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($epoch !~ m/^-?\d+$/) {
        die __PACKAGE__."#setEpoch: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    my ($utctDay , $utctDayTime) = posixSecondsToUTCTime($epoch);
    my ($localDay, @localTOD   ) = utcToLocalTime($this->{timeZone}, $utctDay, $utctDayTime);

    $this->{localDay    } = $localDay;
    $this->{localDayTime} = timeOfDayToTime(@localTOD);

    return $this;
}

sub setJulianDay {
    no integer;
    my Tripletail::DateTime $this = shift;
    my                      $jd   = shift;

    if (!defined $jd) {
        die __PACKAGE__."#setJulianDay: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $jd) {
        die __PACKAGE__."#setJulianDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($jd !~ m/^-?[\d\.]+$/) {
        die __PACKAGE__."#setJulianDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    return $this->setEpoch(int(($jd - 2440587.5) * posixDayLength()));
}

sub setYear {
    my Tripletail::DateTime $this = shift;
    my $year                      = shift;

    if (!defined $year) {
        die __PACKAGE__."#setYear: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $year) {
        die __PACKAGE__."#setYear: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($year !~ m/^-?\d+$/) {
        die __PACKAGE__."#setYear: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    my (undef, $month, $day) = toGregorian($this->{localDay});
    $this->{localDay} = fromGregorian($year, $month, $day);

    return $this;
}

sub setMonth {
    my Tripletail::DateTime $this  = shift;
    my                      $month = shift;

    if (!defined $month) {
        die __PACKAGE__."#setMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref($month)) {
        die __PACKAGE__."#setMonth: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($month !~ m/^-?\d+$/) {
        die __PACKAGE__."#setMonth: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }
    elsif ($month == 0) {
        die __PACKAGE__."#setMonth: arg[1] == 0. (月が0です)\n";
    }
    elsif ($month >= 13) {
        die __PACKAGE__."#setMonth: arg[1] >= 13. (月が13以上です)\n";
    }
    elsif ($month <= -13) {
        die __PACKAGE__."#setMonth: arg[1] <= -13. (月が-13以下です)\n";
    }

    if ($month < 0) {
        $month += 13;
    }

    my ($year, undef, $day) = toGregorian($this->{localDay});
    $this->{localDay} = fromGregorian($year, $month, $day);

    return $this;
}

sub setDay {
    my Tripletail::DateTime $this = shift;
    my                      $day  = shift;

    if (!defined($day)) {
        die __PACKAGE__."#setDay: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref($day)) {
        die __PACKAGE__."#setDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($day !~ m/^-?\d+$/) {
        die __PACKAGE__."#setDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }
    elsif ($day == 0) {
        die __PACKAGE__."#setDay: arg[1] == 0. (日が0です)\n";
    }

    my ($year, $month, undef) = toGregorian($this->{localDay});
    my $length                = monthLength(scalar isGregorianLeapYear($year), $month);

    if ($day > $length) {
        die sprintf(
            __PACKAGE__."#setDay: %04d-%02d-%02d does not exist. (%04d-%02d-%02dの日付は存在しません\n",
            $year, $month, $day,
            $year, $month, $day);
    }
    elsif ($day < -1 * $length) {
        die sprintf(
            __PACKAGE__."#setDay: %04d-%02d-%02d does not exist. (%04d-%02d-%02dの日付は存在しません)\n",
            $year, $month, $day + $length + 1,
            $year, $month, $day + $length + 1);
    }

    if ($day < 0) {
        $day += $length + 1;
    }

    $this->{localDay} = fromGregorian($year, $month, $day);

    return $this;
}

sub setHour {
    my Tripletail::DateTime $this = shift;
    my                      $hour = shift;

    if (!defined $hour) {
        die __PACKAGE__."#setHour: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $hour) {
        die __PACKAGE__."#setHour: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($hour !~ m/^-?\d+$/) {
        die __PACKAGE__."#setHour: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }
    elsif ($hour >= 24) {
        die __PACKAGE__."#setHour: arg[1] >= 24. (第1引数が24以上です)\n";
    }
    elsif ($hour <= -24) {
        die __PACKAGE__."#setHour: arg[1] <= -24. (第1引数が-24以下です)\n";
    }

    if ($hour < 0) {
        $hour += 24;
    }

    my (undef, $minute, $second) = timeToTimeOfDay($this->{localDayTime});
    $this->{localDayTime} = timeOfDayToTime($hour, $minute, $second);

    return $this;
}

sub setMinute {
    my Tripletail::DateTime $this   = shift;
    my                      $minute = shift;

    if (!defined $minute) {
        die __PACKAGE__."#setMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $minute) {
        die __PACKAGE__."#setMinute: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($minute !~ m/^-?\d+$/) {
        die __PACKAGE__."#setMinute: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }
    elsif ($minute >= 60) {
        die __PACKAGE__."#setHour: arg[1] >= 60. (第1引数が60以上です)\n";
    }
    elsif ($minute <= -60) {
        die __PACKAGE__."#setHour: arg[1] <= -60. (第1引数が-60以下です)\n";
    }

    if ($minute < 0) {
        $minute += 60;
    }

    my ($hour, undef, $second) = timeToTimeOfDay($this->{localDayTime});
    $this->{localDayTime} = timeOfDayToTime($hour, $minute, $second);

    return $this;
}

sub setSecond {
    my Tripletail::DateTime $this   = shift;
    my                      $second = shift;

    if (!defined $second) {
        die __PACKAGE__."#setSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $second) {
        die __PACKAGE__."#setSecond: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($second !~ m/^-?\d+$/) {
        die __PACKAGE__."#setSecond: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }
    elsif ($second >= 60) {
        die __PACKAGE__."#setSecond: arg[1] >= 60. (第1引数が60以上です)\n";
    }
    elsif ($second <= -60) {
        die __PACKAGE__."#setSecond: arg[1] <= -60. (第1引数が-60以下です)\n";
    }

    if ($second < 0) {
        $second += 60;
    }

    my ($hour, $minute, undef) = timeToTimeOfDay($this->{localDayTime});
    $this->{localDayTime} = timeOfDayToTime($hour, $minute, $second);

    return $this;
}

sub setTimeZone {
    my Tripletail::DateTime $this = shift;
    my                      $str  = shift;

    my $tz = do {
        if (!defined $str) {
            getCurrentTimeZone();
        }
        elsif (ref $str) {
            die __PACKAGE__."#setTimeZone: arg[1] is a reference. (第1引数がリファレンスです)\n";
        }
        elsif ($str =~ m/^([+\-])(\d{2})(?::)?(\d{2})$/) {
            ($1 eq '-' ? -1 : 1) * ($2 * 60 + $3);
        }
        elsif ($str =~ m/^-?\d+$/) {
            $str * 60;
        }
        elsif (defined(my $tz = parseGenericTimeZone($str))) {
            $tz;
        }
        else {
            die __PACKAGE__."#setTimeZone: unrecognized time-zone: $str (認識できないタイムゾーンです)\n";
        }
    };

    my @localTOD0                = timeToTimeOfDay($this->{localDayTime});
    my ($utctDay , $utctDayTime) = localTimeToUTC($this->{timeZone}, $this->{localDay}, @localTOD0);
    my ($localDay, @localTOD   ) = utcToLocalTime($tz, $utctDay, $utctDayTime);

    $this->{localDay    } = $localDay;
    $this->{localDayTime} = timeOfDayToTime(@localTOD);
    $this->{timeZone    } = $tz;

    return $this;
}

sub getEpoch {
    my Tripletail::DateTime $this = shift;

    my @localTOD                = timeToTimeOfDay($this->{localDayTime});
    my ($utctDay, $utctDayTime) = localTimeToUTC($this->{timeZone}, $this->{localDay}, @localTOD);

    return utcTimeToPOSIXSeconds($utctDay, $utctDayTime);
}

sub getJulianDay {
    no integer;
    my Tripletail::DateTime $this = shift;

    return ($this->getEpoch / posixDayLength()) + 2440587.5;
}

sub getYear {
    my Tripletail::DateTime $this = shift;
    return (toGregorian($this->{localDay}))[0];
}

sub getMonth {
    my Tripletail::DateTime $this = shift;
    return (toGregorian($this->{localDay}))[1];
}

sub getDay {
    my Tripletail::DateTime $this = shift;
    return (toGregorian($this->{localDay}))[2];
}

sub getHour {
    my Tripletail::DateTime $this = shift;
    return (timeToTimeOfDay($this->{localDayTime}))[0];
}

sub getMinute {
    my Tripletail::DateTime $this = shift;
    return (timeToTimeOfDay($this->{localDayTime}))[1];
}

sub getSecond {
    my Tripletail::DateTime $this = shift;
    return (timeToTimeOfDay($this->{localDayTime}))[2];
}

sub getWday {
    my Tripletail::DateTime $this = shift;
    return (toWeekDate($this->{localDay}))[2] % 7;
}

sub getTimeZone {
    my Tripletail::DateTime $this = shift;

    return quot($this->{timeZone}, 60);
}

sub getAnimal {
    my Tripletail::DateTime $this = shift;

    return ($this->getYear - 4) % 12;
}

sub getAllHolidays {
    my Tripletail::DateTime $this = shift;

    my $table = $Tripletail::DateTime::JPHoliday::HOLIDAY{sprintf '%04d', $this->getYear};
    return $table ? { %$table } : {};
}

sub isHoliday {
    my Tripletail::DateTime $this = shift;
    my                      $type = shift || 0;

    if ($type == 1) {
        if ($this->getWday == 0 or defined $this->getHolidayName) {
            return 1;
        }
    }
    elsif ($type == 2) {
        if (defined $this->getHolidayName) {
            return 1;
        }
    }
    else {
        my $wday = $this->getWday;
        if ($wday == 0 or $wday == 6 or defined $this->getHolidayName) {
            return 1;
        }
    }

    return undef;
}

sub isLeapYear {
    my Tripletail::DateTime $this = shift;

    my ($year, undef) = toOrdinalDate($this->{localDay});
    return isGregorianLeapYear($year) ? 1 : undef;
}

sub getHolidayName {
    my Tripletail::DateTime $this = shift;

    my $holidays = $this->getAllHolidays;
    my $key      = sprintf '%02d-%02d', $this->getMonth, $this->getDay;

    if (defined(my $name = $holidays->{$key})) {
        return $name;
    }
    else {
        return undef;
    }
}

sub getCalendar {
    my Tripletail::DateTime $this = shift;

    my ($year, $month, undef) = toGregorian($this->{localDay});
    my $length                = monthLength(scalar isGregorianLeapYear($year), $month);

    return [ map { $this->clone->setDay($_) } (1 .. $length) ];
}

sub getCalendarMatrix {
	my Tripletail::DateTime $this = shift;

	my $opt = {
		type => 'normal',
		begin => 'sun',
	};
	my $arg = ref($_[0]) ? shift : {@_};
	foreach my $key (keys %$arg) {
		$key =~ s/^-//; # key is copied.
		$opt->{$key} = $arg->{$key};
	}

	my $begin = {
		qw(sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6)
	}->{lc($opt->{begin})};
	if( !defined($begin) )
	{
		die __PACKAGE__."#getCalendarMatrix: opt[begin] is invalid: $opt->{begin} (beginの指定が不正です)\n";
	}

	if($opt->{type} ne 'normal' && $opt->{type} ne 'fixed') {
		die __PACKAGE__."#getCalendarMatrix: opt[type] is invalid: $opt->{type} (typeの指定が不正です)\n";
	}

	my $this_month_1st = $this->clone->setDay(1);

	my $start_day;
	{
		my $daysback = ($this_month_1st->getWday()+7 - $begin)%7;
		$start_day = $this_month_1st->clone()->addDay(-$daysback);
	}

	my $weeks;
	if( $opt->{type} eq 'fixed' )
	{
		$weeks = 6;
	}else
	{
		my $end_day = $start_day->clone()->addDay(6*7);
		my $daysback = $end_day->getDay()-1;
		$weeks = 6 - int($daysback/7);
	}
	my $day = $start_day->clone();
	my $matrix = [];
	foreach (1..$weeks)
	{
		my @week;
		foreach(0..6)
		{
			push(@week, $day->clone());
			$day->addDay(1);
		}
		push(@$matrix, \@week);
	}

	return $matrix;
}

sub minusSecond {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop(@_);

    return $lhs->getEpoch() - $rhs->getEpoch();
}

# These two operations are in fact the same.
sub spanSecond {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop(@_);

    return $lhs->getEpoch() - $rhs->getEpoch();
}

sub minusMinute {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    foreach my $dt ($lhs, $rhs) {
        my ($hour, $minute, undef) = timeToTimeOfDay($dt->{localDayTime});
        $dt->{localDayTime} = timeOfDayToTime($hour, $minute, 0);
    }

    my $delta = $lhs->getEpoch() - $rhs->getEpoch();
    return quot($delta, 60);
}

sub spanMinute {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop(@_);
    my $delta       = $lhs->getEpoch() - $rhs->getEpoch();

    return quot($delta, 60);
}

sub minusHour {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    foreach my $dt ($lhs, $rhs) {
        my ($hour, undef, undef) = timeToTimeOfDay($dt->{localDayTime});
        $dt->{localDayTime} = timeOfDayToTime($hour, 0, 0);
    }

    my $delta = $lhs->getEpoch() - $rhs->getEpoch();
    return quot($delta, 60 * 60);
}

sub spanHour {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop(@_);
    my $delta       = $lhs->getEpoch() - $rhs->getEpoch();

    return quot($delta, 60 * 60);
}

sub spanDay {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop(@_);
    my $delta       = $lhs->getEpoch() - $rhs->getEpoch();

    return quot($delta, 60 * 60 * 24);
}

sub minusDay {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop({-sameTimeZone => 1}, @_);

    return $lhs->{localDay} - $rhs->{localDay};
}

sub spanMonth {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    my $sign        = ($lhs->{localDay} < $rhs->{localDay} or
                         ($lhs->{localDay} == $rhs->{localDay} and $lhs->{localDayTime} < $rhs->{localDayTime}))
                      ? -1
                      :  1;
    if ($sign < 0) {
        ($lhs, $rhs) = ($rhs, $lhs);
    }

    my ($lYear, $lMonth, $lDay) = toGregorian($lhs->{localDay});
    my ($rYear, $rMonth, $rDay) = toGregorian($rhs->{localDay});

    my $delta = ($lYear - $rYear) * 12 + ($lMonth - $rMonth);
    if ($lDay < $rDay or
          ($lDay == $rDay and $lhs->{localDayTime} < $rhs->{localDayTime})) {

        $delta--;
    }

    return $delta * $sign;
}

sub minusMonth {
    my Tripletail::DateTime $this = shift;

    my ($lhs  , $rhs          ) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    my ($lYear, $lMonth, undef) = toGregorian($lhs->{localDay});
    my ($rYear, $rMonth, undef) = toGregorian($rhs->{localDay});

    return ($lYear - $rYear) * 12 + $lMonth - $rMonth;
}

sub spanYear {
    my Tripletail::DateTime $this = shift;

    my ($lhs, $rhs) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    my $sign        = ($lhs->{localDay} < $rhs->{localDay} or
                         ($lhs->{localDay} == $rhs->{localDay} and $lhs->{localDayTime} < $rhs->{localDayTime}))
                      ? -1
                      :  1;
    if ($sign < 0) {
        ($lhs, $rhs) = ($rhs, $lhs);
    }

    my ($lYear, $lMonth, $lDay) = toGregorian($lhs->{localDay});
    my ($rYear, $rMonth, $rDay) = toGregorian($rhs->{localDay});

    my $delta = $lYear - $rYear;
    if ($lMonth < $rMonth or
          ($lMonth == $rMonth and $lDay < $rDay) or
            ($lMonth == $rMonth and $lDay == $rDay and $lhs->{localDayTime} < $rhs->{localDayTime})) {

        $delta--;
    }

    return $delta * $sign;
}

sub minusYear {
    my Tripletail::DateTime $this = shift;

    my ($lhs  , $rhs        ) = $this->__prepare_biop({-sameTimeZone => 1}, @_);
    my ($lYear, undef, undef) = toGregorian($lhs->{localDay});
    my ($rYear, undef, undef) = toGregorian($rhs->{localDay});

    return $lYear - $rYear;
}

sub __prepare_biop {
    my Tripletail::DateTime $this = shift;
    my %opts = !blessed $_[0] && UNIVERSAL::isa($_[0], 'HASH') ? %{+shift} : ();

    my $findCaller = sub {
        for (my $i = 1; ; $i++) {
            my (undef, undef, undef, $subname) = caller($i);
            if ($subname !~ m/^__/) {
                return $subname;
            }
        }
        return '(unknown)';
    };

    my @values = do {
        if (@_ == 0) {
            die sprintf(
                "%s#%s: arg[1] is not defined. (第1引数が指定されていません)\n",
                __PACKAGE__, $findCaller->());
        }
        elsif (@_ == 1) {
            # $val1->method($val2);
            ($this, $_[0]);
        }
        else {
            # $x->method($val1, $val2);
            ($_[0], $_[1]);
        }
    };

    my @objects = map {
        if (UNIVERSAL::isa($_, __PACKAGE__)) {
            $_->clone();
        }
        else {
            __PACKAGE__->_new($_);
        }
      } @values;

    if ($opts{-sameTimeZone} and
          $objects[0]->{timeZone} != $objects[1]->{timeZone}) {

        die sprintf(
            "%s#%s: This operation is not defined for two dates in different time-zones. ".
              "(タイムゾーンの異なる二つの日付においては、この演算は定義されません)\n",
            __PACKAGE__, $findCaller->());
    }
    else {
        return @objects;
    }
}

sub addSecond {
    my Tripletail::DateTime $this  = shift;
    my                      $delta = shift;

    if (!defined $delta) {
        die __PACKAGE__."#addSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $delta) {
        die __PACKAGE__."#addSecond: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($delta !~ m/^-?\d+$/) {
        die __PACKAGE__."#addSecond: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->setEpoch($this->getEpoch + $delta);

    return $this;
}

sub addMinute {
    my Tripletail::DateTime $this  = shift;
    my                      $delta = shift;

    if (!defined $delta) {
        die __PACKAGE__."#addMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $delta) {
        die __PACKAGE__."#addMinute: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($delta !~ m/^-?\d+$/) {
        die __PACKAGE__."#addMinute: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->setEpoch($this->getEpoch + $delta * 60);

    return $this;
}

sub addHour {
    my Tripletail::DateTime $this  = shift;
    my                      $delta = shift;

    if (!defined $delta) {
        die __PACKAGE__."#addHour: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $delta) {
        die __PACKAGE__."#addHour: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($delta !~ m/^-?\d+$/) {
        die __PACKAGE__."#addHour: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->setEpoch($this->getEpoch + $delta * 60 * 60);

    return $this;
}

sub addDay {
    my Tripletail::DateTime $this = shift;
    my                      $days = shift;

    if (!defined $days) {
        die __PACKAGE__."#addDay: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $days) {
        die __PACKAGE__."#addDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($days !~ m/^-?\d+$/) {
        die __PACKAGE__."#addDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->{localDay} += $days;

    return $this;
}

sub addMonth {
    my Tripletail::DateTime $this   = shift;
    my                      $months = shift;

    if (!defined $months) {
        die __PACKAGE__."#addMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $months) {
        die __PACKAGE__."#addMonth: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($months !~ m/^-?\d+$/) {
        die __PACKAGE__."#addMonth: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->{localDay} = addGregorianMonthsClip($months, $this->{localDay});

    return $this;
}

sub addYear {
    my Tripletail::DateTime $this  = shift;
    my                      $years = shift;

    if (!defined $years) {
        die __PACKAGE__."#addYear: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $years) {
        die __PACKAGE__."#addYear: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($years !~ m/^-?\d+$/) {
        die __PACKAGE__."#addYear: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->{localDay} = addGregorianYearsClip($years, $this->{localDay});

    return $this;
}

sub nextDay {
    return shift->addDay(1);
}

sub prevDay {
    return shift->addDay(-1);
}

sub firstDay {
    return shift->setDay(1);
}

sub lastDay {
    return shift->setDay(-1);
}

sub addBusinessDay {
    my Tripletail::DateTime $this = shift;
    my                      $day  = shift;
    my                      $type = shift;

    if (!defined $day) {
        die __PACKAGE__."#addBusinessDay: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $day) {
        die __PACKAGE__."#addBusinessDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($day !~ m/^-?\d+$/) {
        die __PACKAGE__."#addBusinessDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
    }

    $this->addDay($day);
    while ($this->isHoliday($type)) {
        $this->nextDay;
    }

    return $this;
}

my %RENDERER_OF = (
    rfc822 => \&renderRFC822DateTime,
    rfc850 => \&renderRFC733DateTime,
    w3c    => \&renderW3CDTF,
    mysql  => sub {
        my ($day , $dayTime, $tz  ) = @_;
        my ($y   , $m      , $d   ) = toGregorian($day);
        my ($hour, $min    , $sec ) = timeToTimeOfDay($dayTime);

        return sprintf(
            '%04d-%02d-%02d %02d:%02d:%02d',
            $y, $m, $d, $hour, $min, $sec);
    }
   );
sub toStr {
    my Tripletail::DateTime $this = shift;
    my                      $format = shift || 'mysql';

    if (defined(my $renderer = $RENDERER_OF{$format})) {
        return $renderer->($this->{localDay}, $this->{localDayTime}, $this->{timeZone});
    }
    else {
        die __PACKAGE__."#toStr: unsupported format: $format (サポートしていないフォーマットが指定されました)\n";
    }
}

sub strFormat {
	# THINKME: There are just too many opportunities for optimization in
	# this single method.
	my Tripletail::DateTime $this   = shift;
	my                      $format = shift;

	$format =~ s/%%/\0PERCENT\0/g;

	$format =~ s/%a/$WDAY_NAME[$this->getWday]/eg;
	$format =~ s/%A/$WDAY_NAME_LONG[$this->getWday]/eg;
	$format =~ s/%J/$J_WDAY_NAME[$this->getWday]/eg;

	$format =~ s/%b/$MONTH_NAME[$this->getMonth - 1]/eg;
	$format =~ s/%B/$MONTH_NAME_LONG[$this->getMonth - 1]/eg;
	$format =~ s/%_B/$J_MONTH_NAME[$this->getMonth - 1]/eg;

	$format =~ s/%d/sprintf '%02d', $this->getDay/eg;
	$format =~ s/%_d/$this->getDay/eg;

	$format =~ s/%m/sprintf '%02d', $this->getMonth/eg;
	$format =~ s/%_m/$this->getMonth/eg;

	$format =~ s/%w/$this->getWday/eg;

	$format =~ s/%y/substr sprintf('%04d', $this->getYear), 2, 2/eg;
	$format =~ s/%Y/sprintf '%04d', $this->getYear/eg;
	$format =~ s/%_Y/renderJPEra($this->{localDay})/eg;

	$format =~ s/%H/sprintf '%02d', $this->getHour/eg;
	$format =~ s/%_H/$this->getHour/eg;
	$format =~ s/%I/sprintf '%02d', $this->getHour % 12/eg;
	$format =~ s/%_I/$this->getHour % 12/eg;

	my $ampm = sub {
		my $noon = $this->clone->setHour(12)->setMinute(0)->setSecond(0);
		($this->spanSecond($noon) >= 0) ? $_[1] : $_[0];
	};
	$format =~ s/%P/$ampm->('a.m.', 'p.m.')/eg;
	$format =~ s/%_P/$ampm->('午前', '午後')/eg;

	$format =~ s/%M/sprintf '%02d', $this->getMinute/eg;
	$format =~ s/%_M/$this->getMinute/eg;

	$format =~ s/%S/sprintf '%02d', $this->getSecond/eg;
	$format =~ s/%_S/sprintf $this->getSecond/eg;

	$format =~ s/%E/$ANIMAL_NAME[$this->getAnimal]/eg;

	$format =~ s/%z/renderRFC822TimeZone($this->{timeZone})/eg;
	$format =~ s/%_z/renderW3CDTFTimeZone($this->{timeZone})/eg;
	$format =~ s/%Z/my $name = renderGenericTimeZone($this->{timeZone}); defined($name) ? uc $name : ''/eg;

	$format =~ s/%T/sprintf '%02d:%02d:%02d', $this->getHour, $this->getMinute, $this->getSecond/eg;

	$format =~ s/\0PERCENT\0/%/g;
	$format;
}

my %MONTH_HASH      = __a2h(@MONTH_NAME);
my %MONTH_LONG_HASH = __a2h(@MONTH_NAME_LONG);
my %J_MONTH_HASH    = __a2h(@J_MONTH_NAME);

my $re_2year  = qr/\d{2}/;
my $re_4year  = qr/\d{4}/;
my $re_2month = qr/0[1-9]|1[0-2]/;
my $re_2day   = qr/0[1-9]|[12][0-9]|3[01]/;
my $re_2hms   = qr/[0-5][0-9]/;

my $re_1month = qr/0?[1-9]|1[0-2]/;
my $re_1day   = qr/0?[1-9]|[12][0-9]|3[01]/;
my $re_1hms   = qr/0?[0-9]|[1-5][0-9]/;

my $re_hms    = qr/($re_2hms):($re_2hms):($re_2hms)/;

my $re_wdy          = __a2r(@WDAY_NAME);
my $re_wdy_long     = __a2r(@WDAY_NAME_LONG);
my $re_month        = __a2r(@MONTH_NAME);
my $re_month_long   = __a2r(@MONTH_NAME_LONG);
my $re_j_wday       = __a2r(@J_WDAY_NAME);
my $re_j_month      = __a2r(@J_MONTH_NAME);
my $re_animal_name  = __a2r(@ANIMAL_NAME);

my $re_ampm   = qr/[ap]\.?m\.?/i;
my $re_j_ampm = qr/午前|午後/;

sub parseFormat {
	my Tripletail::DateTime $this = shift;
	my $format = shift;
	my $str = shift;

	if(!defined($format)) {
		die __PACKAGE__."#parseFormat: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($format)) {
		die __PACKAGE__."#parseFormat: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	if(!defined($str)) {
		die __PACKAGE__."#parseFormat: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($str)) {
		die __PACKAGE__."#parseFormat: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}

	my $f = $format;
	my $regex = '';
	my @parse; # [フォーマット文字, パーサ関数], ...
	while (length $f) {
		if($f =~ s/^([^%]+)//) {
			$regex .= "\Q$1\E";
		} elsif($f =~ s/^%a//) {
			$regex .= $re_wdy;
		} elsif($f =~ s/^%A//) {
			$regex .= $re_wdy_long;
		} elsif($f =~ s/^%J//) {
			$regex .= $re_j_wday;
		} elsif($f =~ s/^%b//) {
			$regex .= "($re_month)";
			push @parse, [b => sub { $MONTH_HASH{$_[0]} }];
		} elsif($f =~ s/^%B//) {
			$regex .= "($re_month_long)";
			push @parse, [B => sub { $MONTH_LONG_HASH{$_[0]} }];
		} elsif($f =~ s/^%_B//) {
			$regex .= "($re_j_month)";
			push @parse, [_B => sub { $J_MONTH_HASH{$_[0]} }];
		} elsif($f =~ s/^%d//) {
			$regex .= "($re_2day)";
			push @parse, ['d'];
		} elsif($f =~ s/^%_d//) {
			$regex .= "($re_1day)";
			push @parse, ['_d'];
		} elsif($f =~ s/^%m//) {
			$regex .= "($re_2month)";
			push @parse, ['m'];
		} elsif($f =~ s/^%_m//) {
			$regex .= "($re_1month)";
			push @parse, ['_m'];
		} elsif($f =~ s/^%w//) {
			$regex .= "[0-6]";
		} elsif($f =~ s/^%y//) {
			$regex .= "($re_2year)";
			push @parse, ['y' => sub {
				widenYearOf2Digits($_[0]);
			}];
		} elsif($f =~ s/^%Y//) {
			$regex .= "($re_4year)";
			push @parse, ['Y'];
		} elsif($f =~ s/^%_Y//) {
			$regex .= qr/(\D+(?:\d+|元)年)/;
			push @parse, [_Y => sub {
				parseJPEra($_[0]);
			}];
		} elsif($f =~ s/^%H//) {
			$regex .= "($re_2hms)";
			push @parse, ['H'];
		} elsif($f =~ s/^%_H//) {
			$regex .= "($re_1hms)";
			push @parse, ['_H'];
		} elsif($f =~ s/^%I//) {
			$regex .= "($re_2hms)";
			push @parse, ['I'];
		} elsif($f =~ s/^%_I//) {
			$regex .= "($re_1hms)";
			push @parse, ['_I'];
		} elsif($f =~ s/^%P//) {
			$regex .= "($re_ampm)";
			push @parse, [P => sub {
				($_[0] =~ m/^a/i) ? 0 : 1;
			}];
		} elsif($f =~ s/^%_P//) {
			$regex .= "($re_j_ampm)";
			push @parse, [_P => sub {
				$_[0] eq '午前' ? 0 : 1;
			}];
		} elsif($f =~ s/^%M//) {
			$regex .= "($re_2hms)";
			push @parse, ['M'];
		} elsif($f =~ s/^%_M//) {
			$regex .= "($re_1hms)";
			push @parse, ['_M'];
		} elsif($f =~ s/^%S//) {
			$regex .= "($re_2hms)";
			push @parse, ['S'];
		} elsif($f =~ s/^%_S//) {
			$regex .= "($re_1hms)";
			push @parse, ['_S'];
		} elsif($f =~ s/^%E//) {
			$regex .= $re_animal_name;
		} elsif($f =~ s/^%z//) {
			$regex .= "($RE_RFC822_TIMEZONE)";
			push @parse, [z => sub {
				my $tz = parseRFC822TimeZone($_[0]);
				if (defined $tz) {
					return $tz;
				}
				else {
					die __PACKAGE__."#parseFormat: failed to parse RFC 822 time-zone: $str (RFC 822タイムゾーンの解析に失敗しました)\n";
				}
			}];
		} elsif($f =~ s/^%_z//) {
			$regex .= "($RE_W3CDTF_TIMEZONE)";
			push @parse, [_z => sub {
				my $tz = parseW3CDTFTimeZone($_[0]);
				if (defined $tz) {
					return $tz;
				}
				else {
					die __PACKAGE__."#parseFormat: failed to parse W3CDTF time-zone: $str (W3CDTFタイムゾーンの解析に失敗しました)\n";
				}
			}];
		} elsif($f =~ s/^%Z//) {
			$regex .= "($RE_GENERIC_TIMEZONE)";
			push @parse, [Z => sub {
				my $tz = parseGenericTimeZone($_[0]);
				if (defined $tz) {
					return $tz;
				}
				else {
					die __PACKAGE__."#parseFormat: failed to parse generic time-zone: $str (一般的タイムゾーンの解析に失敗しました)\n";
				}
			}];
		} elsif($f =~ s/^%T//) {
			$regex .= "($re_2hms:$re_2hms:$re_2hms)";
			push @parse, [T => sub {
				$_[0] =~ m/$re_hms/;
				($1, $2, $3);
			}];
		} elsif($f =~ s/^%%//) {
			$regex .= '\%';
		} else {
			die __PACKAGE__."#parseFormat: failed to parse format: $f (フォーマットの指定が不正です)\n";
		}
	}

	# フォーマット文字列に求められる制約は以下の通り:
	#   年が得られなければならない。
	#   情報の重複があってはならない。(年を二つなど)
	#   12hourとampmは常にセットで。
	my %group = (
		year => [qw(y Y _Y)],
		mon  => [qw(b B _B m _m)],
		day  => [qw(d _d)],
		hour => [qw(H _H)],
		min  => [qw(M _M)],
		sec  => [qw(S _S)],
		tz   => [qw(z _z Z)],

		'12hour' => [qw(I _I)],
		ampm     => [qw(P _P)],
	);
	my %rev_group = do {
		my %ret;
		while(my ($key, $value) = each %group) {
			$ret{$_} = $key foreach @$value;
		}
		%ret;
	};

	my %occur;
	my $check_dup = sub {
		my $group = shift;
		if($occur{$group}++) {
			my $err = {year => 'year',
				mon  => 'month',
				day  => 'day',
				hour => 'hour',
				min  => 'minute',
				sec  => 'second',
				tz   => 'timezone'}->{$group};
			die __PACKAGE__."#parseFormat: the format has multiple ${err}s. (複数の${err}が指定されています)\n";
		}
	};
	foreach my $ent (@parse) {
		if($ent->[0] eq 'T') {
			$check_dup->('hour');
			$check_dup->('min');
			$check_dup->('sec');
		} else {
			$check_dup->($rev_group{$ent->[0]});
		}
	}

	# hourが在る時には ampm は在っても無視され、12hour が在ればdie。
	# hourが無くampm/12hourの内どちらか片方のみが在ればdie。
	if($occur{hour}) {
		if($occur{'12hour'}) {
			die __PACKAGE__."#parseFormat: the format has both of 24-hour and 12-hour. (24時間表記の時と12時間表記の時の両方が指定されています)\n";
		}
	} else {
		if($occur{ampm} xor $occur{'12hour'}) {
			die __PACKAGE__."#parseFormat: the format has only one-half of 12-hour and AM/PM. (12時間表記の時とAM/PMの両方が必要です)\n";
		}
	}

	if(!$occur{year}) {
		die __PACKAGE__."#parseFormat: the format does not have any years. (フォーマットに年の指定が必要です)\n";
	}

	my @matched = ($str =~ m/^$regex$/m);
	if(!@matched) {
		die __PACKAGE__."#parseFormat: arg[2] does not match to arg[1]. (指定されたフォーマットに一致しません)\n";
	}

	if(@matched != @parse) {
		die __PACKAGE__."#parseFormat: internal error: generated regex must be invalid. (内部エラー:生成された正規表現が不正です)\n";
	}

	my %greg = (
		year => undef,
		mon  => 1,
		day  => 1,
		hour => 0,
		min  => 0,
		sec  => 0,
		tz   => $this->{timeZone},

		'12hour' => undef,
		ampm     => undef, # AM => 0, PM => 1
	);
	for(my $i = 0; $i < @parse; $i++) {
		my $ent = $parse[$i];
		my $matched = $matched[$i];

		if($ent->[0] eq 'T') {
			@greg{qw(hour min sec)} = $ent->[1]->($matched);
		} else {
			my $group = $rev_group{$ent->[0]};
			if($ent->[1]) {
				$greg{$group} = $ent->[1]->($matched);
			} else {
				$greg{$group} = $matched;
			}
		}
	}

	if(defined($greg{'12hour'}) && defined($greg{ampm})) {
		$greg{hour} = $greg{ampm} * 12 + $greg{'12hour'};
	}

	$this->{localDay    } = fromGregorianRollOver($greg{year}, $greg{mon}, $greg{day});
	$this->{localDayTime} = timeOfDayToTime      ($greg{hour}, $greg{min}, $greg{sec});
	$this->{timeZone    } = $greg{tz};

	return $this;
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::DateTime - 日付と時刻

=head1 SYNOPSIS

  my $dt = $TL->newDateTime('2006-02-17 15:18:01');
  $dt->addDay(1);
  $dt->addSecond(-1);
  print $dt->toStr('rfc822'); # Fri, 18 Feb 2006 15:18:00 JST

=head1 DESCRIPTION

日付と時刻を扱うクラス。グレゴリオ歴にのみ対応している。精度は秒。
うるう秒や夏時間を考慮しない。

=head2 METHODS

=over 4

=item C<< $TL->newDateTime >>

  $dt = $TL->newDateTime;         # 現在時刻
  $dt = $TL->newDateTime($str);   # 文字列をパース

Tripletail::DateTime オブジェクトを生成。
二番目の形式では、文字列から日付や時刻をパースする。

存在しない日付が指定された場合は、それが自動的に補正される。
例えば次の 2 行は同じ結果になる。

  $dt = $TL->newDateTime('2000-04-31');
  $dt = $TL->newDateTime('2000-05-01');

但し、次の行はパースに失敗する。

  $dt = $TL->newDateTime('2000-99-99'); # 正しい形式に沿っていない

パースに失敗した場合はdieする。時刻が与えられない場合は 0 時 0 分 0秒
に設定され、タイムゾーンが与えらない場合は localtime と gmtime の差か
ら求めた値が設定される。パースできる形式は次の通り。

=over 8

=item B<< 一般 >>

 YYYY-MM-DD
 YYYY-MM-DD HH:MM
 YYYY-MM-DD HH:MM:SS

ハイフンやコロンは別の記号であっても良く、何も無くても良い。
例:

 YYYY@MM@DD
 YYYY/MM/DD HH.MM.SS
 YYYYMMDD
 YYYYMMDDHHMMSS

また、記号がある場合は次のように月、日、時、分、秒は一桁であっても良い。

 YYYY-M-D
 YYYY/M/D H:M
 YYYY/M/D H:M:S

=item B<< date コマンド >>

 Wdy Mon DD HH:MM:SS TIMEZONE YYYY
 (Fri Feb 17 11:24:41 JST 2006)

=item B<< Apache access_log >>

 DD/Mon/YYYY:HH:MM:SS +TTTT
 (17/Feb/2006:11:24:41 +0900)

=item B<< Apache error_log >>

 Wdy Mon DD HH:MM:SS YYYY
 (Fri Feb 17 11:24:41 2006)

=item B<< Apache directory index >>

 DD-Mon-YYYY HH:MM:SS

=item B<< RFC 822 >>

 Wdy, DD Mon YY HH:MM:SS TIMEZONE
 (Fri, 17 Feb 06 11:24:41 +0900)

 Wdy, DD Mon YYYY HH:MM:SS TIMEZONE
 (Fri, 17 Feb 2006 11:24:41 +0900)

=item B<< RFC 850 >>

 Wdy, DD-Mon-YY HH:MM:SS TIMEZONE
 (Fri, 17-Feb-06 11:24:41 +0900)

 Wdy, DD-Mon-YYYY HH:MM:SS TIMEZONE
 (Fri, 17-Feb-2006 11:24:41 +0900)

RFC 850 で規定される形式は、実際には RFC 733 のものである。

=item B<< W3C Date and Time >>

 YYYY
 YYYY-MM
 YYYY-MM-DD
 YYYY-MM-DDTHH:MMTzd (2006-02-17T11:40+09:00)
 YYYY-MM-DDTHH:MM:SSTzd (2006-02-17T11:40:10+09:00)
 YYYY-MM-DDTHH:MM:SS.sTzd (2006-02-17T11:40:10.45+09:00)

ここで Tzd とはタイムゾーン指定であり、+hh:mm / -hh:mm / 'Z' の何れか
の形式で表される。Z は UTC を表す。例:

 2006-02-17T11:40:10Z

最後の形式の .s は時刻の端数を表すものであるが、このクラスの精度は秒で
あるので、端数はパース後に切り捨てられる。

=back

=item C<< clone >>

  $dt2 = $dt->clone;

DateTimeオブジェクトを複製して返す。

=item C<< set >>

  $dt->set;
  $dt->set($str);

引数はコンストラクタと同じ。

=item C<< setEpoch >>

  $dt->setEpoch($epoch);

エポックからの秒数を設定する。このクラスでエポックとは gmtime(0) の返
す日付と時刻を云う。負の値を与えた場合は、エポック以前の日付/時刻に設
定される。

=item C<< setJulianDay >>

  $dt->setJulianDay($julian);

ユリウス日を設定する。小数で指定された場合は、その値から時刻を求める。

=item C<< setYear >>

  $dt->setYear(2006);

年を設定する。引数は、現在設定されているタイムゾーンでの値として解釈さ
れる。

=item C<< setMonth >>

  $dt->setMonth(1);

月を設定する。負の値 n を与えた場合は、最大値(setMonthの場合は12) + 1
+ n が与えられたものと見なす。例えば setMonth(-1) は setMonth(12) に等
しい。

引数が0または13以上である場合、及び-13以下である場合は die する。

また、月を変更する事により日が存在する範囲から外れた場合は、日が最終日
に設定される。例えば1月31日で setMonth(4) すると4月30日になる。

=item C<< setDay >>

=item C<< setHour >>

=item C<< setMinute >>

=item C<< setSecond >>

setMonth と同様。負の値を与えた場合等の動作も setMonth に準じる。

=item C<< setTimeZone >>

  $dt->setTimeZone();         # localtimeとgmtimeの差から計算
  $dt->setTimeZone(9);        # +09:00 に設定
  $dt->setTimeZone('+0900');  # +09:00 に設定 (RFC 822)
  $dt->setTimeZone('+09:00'); # +09:00 に設定 (W3C)
  $dt->setTimeZone('gmt');    # +00:00 に設定

タイムゾーンを設定する。タイムゾーンを変更すると、絶対時間であるエポッ
ク秒やユリウス日は変化しないが、getSecond等で返される日付や時刻等が変
化する。

=item C<< getEpoch >>

  $epoch = $dt->getEpoch;

エポック秒を返す。エポック以前の日付と時刻では負の値が返る。

=item C<< getJulianDay >>

  $julian = $dt->getJulianDay;

ユリウス日を小数で返す。

=item C<< getYear >>

  $year = $dt->getYear;

年を返す。現在設定されているタイムゾーンでの値が返される。

=item C<< getMonth >>

  $mon = $dt->getMonth;       # 数値 1-12 で返す。

月を返す。

=item C<< getDay >>

=item C<< getHour >>

=item C<< getMinute >>

=item C<< getSecond >>

getYearと同様。

=item C<< getWday >>

  $wday = $dt->getWday;       # 数値 0-6 で返す。0が日曜、1が月曜である。

曜日を返す。数値 0-6 で返す。0が日曜、1が月曜である。

=item C<< getTimeZone >>

  $tz = $dt->getTimeZone();         # 時間で返す

タイムゾーンを時間単位で返す。端数がある場合は小数で返る。

=item C<< getAnimal >>

  $animal = $dt->getAnimal;      # 数値 0-11 を返す

この年の十二支を返す。0: 子, 1: 丑, ... 11: 亥

=item C<< getAllHolidays >>

  $hash = $dt->getAllHolidays;

この年にある日本の祝祭日を返す。返される値は、キーが MM-DD 形式の日付、
値が祝祭日名のハッシュである。

=item C<< isHoliday >>

  $bool = $dt->isHoliday($type);

この日が特定の日であれば 1 を、そうでなければ undef を返す。

特定の日とは以下の通り。

$typeが0の場合、土日及び日本の祝祭日。

$typeが1の場合、日及び日本の祝祭日。

$typeが2の場合、日本の祝祭日。

デフォルトは0。

=item C<< getHolidayName >>

  $str = $dt->getHolidayName;

この日が祝祭日であればその名前を、そうでなければ undef を返す。

=item C<< isLeapYear >>

この年がうるう年であれば 1 を、そうでなければ undef を返す。

=item C<< getCalendar >>

  $array = $dt->getCalendar;

この月の日数分の DateTime オブジェクトが入った配列を返す。

=item C<< getCalendarMatrix >>

  $matrix = $dt->getCalendarMatrix(\$option);

この月のカレンダーを二次元配列で返す。
引数は次の通り:

=over 8

=item C<< type >>

'normal' または 'fixed' の2種類。fixed にすると常に６週分を返す.

=item C<< begin >>

'sun' または 'mon' の2種類。sun なら週が日曜から始まり、mon なら月曜。
デフォルトは sun 。

=back

戻り値はカレンダーの一行分の DateTime オブジェクトの配列を1ヶ月分格納した配列。

=item C<< spanSecond >>

  $seconds = $dt->spanSecond($dt2);
  $seconds = $dt->spanSecond($dt1,$dt2);

引数との秒数の差を計算し、結果を整数で返す。
引数が2つ指定された場合は、引数同士の差を計算する。

spanは、実際の期間を、指定された単位で計算する。
spanDay で1日が返った場合は、2つの日付の間に24時間の間隔があることを示す。

spanMonth / Year の場合、それ以下の日部分の大小や年部分の大小を比較して、マイナス１すべきか判断する。
秒数を平均的な１月の長さや１年の長さで割って求めているわけではない。（年齢計算等に利用できる）

例：spanMonthの場合（2006年1月1日00時00分00秒と2005年12月31日00時00分00秒の場合、0が返る）

引数が DateTime オブジェクトだった場合はそのオブジェクトと比較し、
それ以外の場合は引数をそのまま $TL->newDateTime に渡して生成した
オブジェクトと比較する。

返される値は ($dt) - ($dt2) もしくは、($dt1) - ($dt2)であり、引数が過去ならば結果は正になる。

=item C<< spanMinute >>

=item C<< spanHour >>

=item C<< spanDay >>

=item C<< spanMonth >>

=item C<< spanYear >>

spanSecond と同様。

=item C<< minusSecond >>

  $seconds = $dt->minusSecond($dt2);
  $seconds = $dt->minusSecond($dt1,$dt2);

引数との秒数の差を計算し、結果を整数で返す。
引数が2つ指定された場合は、引数同士の差を計算する。

minusは、指定された単位部分の差を計算する。
minusDayであれば、時・分・秒の部分を無視し、
年月日のみで差を計算し、その差が何日分かを返す。

例：minusMonthの場合（2006年1月1日と2005年12月31日の場合、1が返る）

引数が DateTime オブジェク
トだった場合はそのオブジェクトと比較し、それ以外の場合は引数をそのまま
$TL->newDateTime に渡して生成したオブジェクトと比較する。

返される値は ($dt) - ($dt2) もしくは、($dt1) - ($dt2)であり、引数が過去ならば結果は負になる。

=item C<< minusMinute >>

=item C<< minusHour >>

=item C<< minusDay >>

=item C<< minusMonth >>

=item C<< minusYear >>

minusSecond と同様。

=item C<< addSecond >>

  $dt->addSecond($sec);

$sec 秒後の時刻にする。

=item C<< addMinute >>

=item C<< addHour >>

=item C<< addDay >>

addSecond と同様。

=item C<< addMonth >>

addSecond と同様だが、もし変更前の日が変更後の年/月に存在しないもので
あったら、日はその月の最後の日に変更される。

=item C<< addYear >>

addMonth と同様。

=item C<< addBusinessDay >>

  $dt->addBusinessDay($day,$type);

$day 営業日後にする。
お盆や年末年始などは考慮しない。

例としては、12月31日で、$dayに1を指定した場合、翌年の1月2日になる。
（2日が振替休日の場合、3日になる）

休業日は$typeで決定する。

$typeが0の場合、土日及び日本の祝祭日。

$typeが1の場合、日及び日本の祝祭日。

$typeが2の場合、日本の祝祭日。

を休業日として営業日を判定する。

デフォルトは0。

=item C<< nextDay >>

次の日にする。

=item C<< prevDay >>

前の日にする。

=item C<< firstDay >>

その月の最初の日にする。

=item C<< lastDay >>

その月の最後の日にする。

=item C<< toStr >>

  $str = $dt->toStr('mysql');  # YYYY-MM-DD HH:MM:SS の形式で返す。
  $str = $dt->toStr('rfc822'); # rfc822 形式で返す。
  $str = $dt->toStr('rfc850'); # rfc850 形式で返す。
  $str = $dt->toStr('w3c');    # W3c Date and Time の形式で返す。
  $str = $dt->toStr;           # mysql と同じ。

文字列で表した日付と時刻を返す。

=item C<< strFormat >>

  $str = $dt->strFormat('%Y 年 %m 月 %d 日 (%J) %H 時 %M 分');

指定されたフォーマットに従って文字列化したものを返す。

=over 8

=item C<< %a >>

短縮された曜日の名前 (Sun - Sat)

=item C<< %A >>

完全な曜日の名前 (Sunday - Saturday)

=item C<< %J >>

日本語での曜日の名前 (日 - 土)

=item C<< %b >>

短縮された月の名前 (Jan - Dec)

=item C<< %B >>

完全な月の名前 (January - December)

=item C<< %_B >>

日本語での月の名前 (睦月 - 師走)

=item C<< %d >>

日を2桁で表現 (01 - 31)

=item C<< %_d >>

日 (1 - 31)

=item C<< %m >>

月を2桁で表現 (01-12)

=item C<< %_m >>

月 (1-12)

=item C<< %w >>

曜日を10進数で表現。0 - 6 で、日曜が 0 、月曜が 1 。

=item C<< %y >>

年を下2桁で表現 (00 - 99)

=item C<< %Y >>

年を4桁で表現

=item C<< %_Y >>

年を和暦で表現。 (平成11年 等)

和暦の定義されていない範囲では空文字列。

=item C<< %H >>

時を24時間表記で2桁で表現 (00-23)

=item C<< %_H >>

時を24時間表記で表現 (0-23)

=item C<< %I >>

時を12時間表記で2桁で表現 (00-11)

=item C<< %_I >>

時を12時間表記で表現 (0-11)

=item C<< %P >>

時刻が午前なら 'a.m.', 午後なら 'p.m.' に置換する。
24時間表記での0時0分は午前とし、12時0分は午後とする。

このパターンが parseFormat で使われる時は、大文字と小文字は無視され、
ピリオドの有無も無視される。例えば 'AM', 'A.M.', 'a.M' はいずれも午前
としてパースされる。

=item C<< %_P >>

時刻が午前なら '午前', 午後なら '午後' に置換する。

=item C<< %M >>

分を2桁で表現 (00-59)

=item C<< %_M >>

分 (0-59)

=item C<< %S >>

秒を2桁で表現 (00-59)

=item C<< %_S >>

秒 (0-59)

=item C<< %E >>

十二支を表す文字 (子 - 亥)

=item C<< %z >>

RFC 822 形式に於けるタイムゾーン。JSTの場合は '+0900' になる。

=item C<< %_z >>

W3C Date and Time 形式に於けるタイムゾーン。JSTの場合は '+09:00' になる。

=item C<< %Z >>

タイムゾーンを表す名称。存在しない場合は空文字列になる。

=item C<< %T >>

'%H:%M:%S' のフォーマットで返される文字列

=item C<< %% >>

'%' という文字

=back

=item C<< parseFormat >>

  $dt->parseFormat('%Y %d %m', '2006 01 13');

指定されたフォーマットを用いて日付と時刻の文字列をパースする。フォーマッ
ト文字は strFormat のものと同一。フォーマット文字列から年を得
る事が出来ない場合や、パースに失敗した場合は、die する。

また、常に空白または0による桁揃えの有無、全角半角は無視して解析する。

12時間表記の時間である %I と %_I と、午前または午後を表す %P と %_P は、
用いられる際には必ず両方用いられなければならない。いずれか片方だけでは
正確な時刻が判らない為。

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
