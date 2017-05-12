=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Time::Normalize - Convert time and date values into standardized components.

=head1 VERSION

This is version 0.09 of Time::Normalize, April 23, 2014.

=cut

use strict;
package Time::Normalize;
$Time::Normalize::VERSION = '0.09';
use Carp;

use Exporter;
use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;
@ISA       = qw/Exporter/;
@EXPORT    = qw/normalize_hms normalize_time normalize_ymd normalize_gmtime
                normalize_month normalize_year normalize_ym
                normalize_ymd3 normalize_ym3
                normalize_ymdhms  normalize_rct
               /;
@EXPORT_OK = (@EXPORT, qw(mon_name mon_abbr day_name day_abbr days_in is_leap));
%EXPORT_TAGS = (all => \@EXPORT_OK);

# Is POSIX available?
eval {require POSIX };
my $have_posix = $@? 0 : 1;

# Delay loading Carp until needed
sub _croak
{
    require Carp;
    goto &Carp::croak;
}

# Most error messages in this module look very similar.
# This standardizes them:
sub _bad
{
    my ($what, $value) = @_;
    $value = '(undefined)' if !defined $value;
    _croak qq{Time::Normalize: Invalid $what: "$value"};
}

# Current locale.
my $locale;

# Month names; Month names abbrs, Weekday names, Weekday name abbrs.
#  *All Mixed-Case!*
our (@Mon_Name, @Mon_Abbr, @Day_Name, @Day_Abbr);
# Lookup: string-month => numeric-month (also string-day => numeric-day)
our %number_of;
# We need english-only names to parse R::C::t's 'mail' format.
my  $mail_month_number;
our $use_mail_months;

# Current year and century.  Used for guessing century of two-digit years.
my $current_year = (localtime)[5] + 1900;
my ($current_century, $current_yy) = $current_year =~ /(\d\d)(\d\d)/;

# Number of days in each (1-based) month (except February).
my @num_days_in = qw(0 31 29 31 30 31 30 31 31 30 31 30 31);

sub days_in
{
    _croak "Too few arguments to days_in"  if @_ < 2;
    _croak "Too many arguments to days_in" if @_ > 2;
    my ($m,$y) = @_;
    _croak qq{Non-integer month "$m" for days_in}  if $m !~ /\A\s* \d+ \s*\z/x;
    _bad('month', $m) if $m < 1  ||  $m > 12;
    return $num_days_in[$m] if $m != 2;

    # February
    return is_leap($y)? 29 : 28;
}

# Is a leap year?
sub is_leap
{
    _croak "Too few arguments to is_leap"  if @_ < 1;
    _croak "Too many arguments to is_leap" if @_ > 1;
    my $year = shift;
    return !($year%4) && ( ($year%100) || !($year%400) );
}

# Quickie function to pad a number with a leading 0.
sub _lead0 { $_[0] > 9? $_[0]+0 : '0'.($_[0]+0)}

# Compute day of week, using Zeller's congruence
sub _dow
{
    my ($Y, $M, $D) = @_;

    $M -= 2;
    if ($M < 1)
    {
        $M += 12;
        $Y--;
    }
    my $C = int($Y/100);
    $Y %= 100;

    return (int((26*$M - 2)/10) + $D + $Y + int($Y/4) + int($C/4) - 2*$C) % 7;
}


# Internal function to initialize locale info.
sub _setup_locale
{
    # Do nothing if locale has not changed since %names was set up.
    my $locale_in_use;
    $locale_in_use = $have_posix? POSIX::setlocale(POSIX::LC_TIME()) : 'no posix; use defaults';
    $locale_in_use = q{} if  !defined $locale_in_use;

    # No changes needed
    return if defined $locale  &&  $locale eq $locale_in_use;

    $locale = $locale_in_use;

    eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import ('langinfo');
        @Mon_Name  = map langinfo($_), (
                                        I18N::Langinfo::MON_1(),
                                        I18N::Langinfo::MON_2(),
                                        I18N::Langinfo::MON_3(),
                                        I18N::Langinfo::MON_4(),
                                        I18N::Langinfo::MON_5(),
                                        I18N::Langinfo::MON_6(),
                                        I18N::Langinfo::MON_7(),
                                        I18N::Langinfo::MON_8(),
                                        I18N::Langinfo::MON_9(),
                                        I18N::Langinfo::MON_10(),
                                        I18N::Langinfo::MON_11(),
                                        I18N::Langinfo::MON_12(),
                                       );
        @Mon_Abbr  = map langinfo($_), (
                                        I18N::Langinfo::ABMON_1(),
                                        I18N::Langinfo::ABMON_2(),
                                        I18N::Langinfo::ABMON_3(),
                                        I18N::Langinfo::ABMON_4(),
                                        I18N::Langinfo::ABMON_5(),
                                        I18N::Langinfo::ABMON_6(),
                                        I18N::Langinfo::ABMON_7(),
                                        I18N::Langinfo::ABMON_8(),
                                        I18N::Langinfo::ABMON_9(),
                                        I18N::Langinfo::ABMON_10(),
                                        I18N::Langinfo::ABMON_11(),
                                        I18N::Langinfo::ABMON_12(),
                                       );
        @Day_Name  = map langinfo($_), (
                                        I18N::Langinfo::DAY_1(),
                                        I18N::Langinfo::DAY_2(),
                                        I18N::Langinfo::DAY_3(),
                                        I18N::Langinfo::DAY_4(),
                                        I18N::Langinfo::DAY_5(),
                                        I18N::Langinfo::DAY_6(),
                                        I18N::Langinfo::DAY_7(),
                                       );
        @Day_Abbr  = map langinfo($_), (
                                        I18N::Langinfo::ABDAY_1(),
                                        I18N::Langinfo::ABDAY_2(),
                                        I18N::Langinfo::ABDAY_3(),
                                        I18N::Langinfo::ABDAY_4(),
                                        I18N::Langinfo::ABDAY_5(),
                                        I18N::Langinfo::ABDAY_6(),
                                        I18N::Langinfo::ABDAY_7(),
                                       );
        # make the month arrays 1-based:
        for (\@Mon_Name, \@Mon_Abbr)
        {
            unshift @$_, 'n/a';
        }
    };
    if ($@)    # If internationalization didn't work for some reason, go with English.
    {
        @Mon_Name = qw(n/a January February March April May June July August September October November December);
        @Mon_Abbr = map substr($_,0,3), @Mon_Name;
        @Day_Name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
        @Day_Abbr = map substr($_,0,3), @Day_Name;
    }

    %number_of = ();
    for (1..12)
    {
        $number_of{uc $Mon_Name[$_]} = $number_of{uc $Mon_Abbr[$_]} = $_;
    }
    # This module doesn't use reverse DOW lookups, but someone might want it.
    for (0..6)
    {
        $number_of{uc $Day_Name[$_]} = $number_of{uc $Day_Abbr[$_]} = $_;
    }
}

sub _init_mail_months
{
    my @abbrs  = qw(n/a Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    %$mail_month_number = ();
    for (1..12)
    {
        $mail_month_number->{uc $abbrs[$_]} = $_;
    }
}

my %ap_from_ampm = (a => 'a', am => 'a', 'a.m.' => 'a', p => 'p', pm => 'p', 'p.m.' => 'p');
sub normalize_hms
{
    _croak "Too few arguments to normalize_hms"  if @_ < 2;
    _croak "Too many arguments to normalize_hms" if @_ > 4;
    my ($inh, $inm, $ins, $ampm) = @_;
    my ($hour24, $hour12, $minute, $second);
    my $ap;

    # First, normalize am/pm indicator
    if (defined $ampm  &&  length $ampm)
    {
        $ap = $ap_from_ampm{lc $ampm};
        _bad ('am/pm indicator', $ampm)  if !defined $ap;
    }

    # Check that the hour is in bounds
    _bad('hour', $inh) if $inh !~ /\A\s*  \d+  \s*\z/x;
    if (defined $ap)
    {
        # Range is from 1 to 12
        _bad('hour', $inh)  if $inh < 1  ||  $inh > 12;
        $hour12 = 0 + $inh;
        $hour24 = $hour12 == 12?  0 : $hour12;
        $hour24 += 12 if $ap eq 'p';
    }
    else
    {
        # Range is from 0 to 23
        _bad('hour', $inh)  if $inh < 0  ||  $inh > 23;
        $hour24 = $inh;
        $hour12 = $hour24 > 12?  $hour24 - 12 : $hour24 == 0? 12 : 0 + $hour24;
        $ap = $hour24 < 12? 'a' : 'p';
    }
    $hour24 = _lead0($hour24);

    # Minute check:  Numeric, range 0 to 59.
    _bad('minute', $inm)  if $inm !~ /\A\s*  \d+  \s*\z/x ||  $inm < 0  ||  $inm > 59;
    $minute = _lead0($inm);

    # Second check: Numeric, range 0 to 59.
    if (defined $ins  &&  length $ins)    # second is optional!
    {
        _bad('second', $ins)  if $ins !~ /\A\s*  \d+  \s*\z/x  ||  $ins < 0  ||  $ins > 59;
        $second = $ins;
    }
    else
    {
        $second = 0;
    }
    $second = _lead0($second);

    my $sec_since_midnight = $second + 60 * ($minute + 60 * $hour24);
    return wantarray? ($hour24, $minute, $second, $hour12, $ap, $sec_since_midnight)
        : {
            h12  => $hour12,
            h24  => $hour24,
            hour => $hour24,
            min  => $minute,
            sec  => $second,
            ampm => $ap,
            since_midnight => $sec_since_midnight,
        };
}

sub normalize_ymd
{
    _croak "Too few arguments to normalize_ymd"  if @_ < 3;
    _croak "Too many arguments to normalize_ymd" if @_ > 3;
    my ($iny, $inm, $ind) = @_;
    my ($year, $month, $day);

    _setup_locale();

    # First, check year.
    $year = normalize_year($iny);

    # Decode the month.
    $month = normalize_month($inm);

    # Day: Numeric and within range for the given month/year
    _bad('day', $ind)
        if $ind !~ /\A\s*  \d+  \s*\z/x  ||  $ind < 1  ||  $ind > days_in($month, $year);
    $day = _lead0($ind);

    my $dow = _dow($year, $month, $day);

    return ($year, $month, $day,
            $dow, $Day_Name[$dow], $Day_Abbr[$dow],
            $Mon_Name[$month], $Mon_Abbr[$month])
        if wantarray;

    return
        {
          year => $year, mon => $month, day => $day,
          dow  => $dow,
          dow_name => $Day_Name[$dow],
          dow_abbr => $Day_Abbr[$dow],
          mon_name => $Mon_Name[$month],
          mon_abbr => $Mon_Abbr[$month],
        };
}

sub normalize_ymdhms
{
    _croak "Too few arguments to normalize_ymdhms"  if @_ < 5;
    _croak "Too many arguments to normalize_ymdhms" if @_ > 7;
    my ($iny, $inmon, $ind, $inhr, $inmin, $insec, $inampm) = @_;

    my $date = normalize_ymd($iny, $inmon, $ind);
    my $time = normalize_hms($inhr, $inmin, $insec, $inampm);

    return ($date->{year}, $date->{mon}, $date->{day},
            $time->{hour}, $time->{min}, $time->{sec})
        if wantarray;

    return { %$date, %$time };
}

# Normalize values returned from Regexp::Common::time
sub normalize_rct
{
    my ($type, @values) = @_;
    $type =~ tr/24//d;
    $type = lc $type;

    # First element is "whole match", which is useless here.
    shift @values;

    my ($yr, $mo, $dy, $hr, $mn, $sc, $tz, $am);

    # How we proceed depends on which pattern captured the values.
    if ($type eq 'iso')
    {
        ($yr, $mo, $dy, $hr, $mn, $sc) = @values;
        return normalize_ymdhms($yr, $mo, $dy, $hr, $mn, $sc);
    }
    elsif ($type eq 'mail')
    {
        ($dy, $mo, $yr, $hr, $mn, $sc) = @values;
        local $use_mail_months = 1;
        return normalize_ymdhms($yr, $mo, $dy, $hr, $mn, $sc);
    }
    elsif ($type eq 'american')
    {
        ($mo, $dy, $yr) = @values;
        $yr =~ s/\A'//;    # "american" year might have leading apostrophe
        return normalize_ymd($yr, $mo, $dy);
    }
    elsif ($type eq 'ymd')
    {
        ($yr, $mo, $dy) = @values;
        return normalize_ymd($yr, $mo, $dy);
    }
    elsif ($type eq 'mdy')
    {
        ($mo, $dy, $yr) = @values;
        return normalize_ymd($yr, $mo, $dy);
    }
    elsif ($type eq 'dmy')
    {
        ($dy, $mo, $yr) = @values;
        return normalize_ymd($yr, $mo, $dy);
    }
    elsif ($type eq 'hms')
    {
        ($hr, $mn, $sc, $am) = @values;
        return normalize_hms($hr, $mn, $sc, $am);
    }
    else
    {
        _croak qq{Unknown Regexp::Common::time pattern: "$type"};
    }
}

# Like normalize_ymd, but only returns the Y, M, and D values.
# So you can do: $date = join '/' => normalize_ymd3 ($input_yr, $input_mo, $input_dy);
sub normalize_ymd3
{
    _croak "Too few arguments to normalize_ymd3"  if @_ < 3;
    _croak "Too many arguments to normalize_ymd3" if @_ > 3;
    my @ymd = normalize_ymd(@_);
    return @ymd[0,1,2];
}

# Like normalize_ym, but only returns the Y, M, and D values.
# So you can do: $date = join '/' => normalize_ym3 ($input_yr, $input_mo);
sub normalize_ym3
{
    _croak "Too few arguments to normalize_ym3"  if @_ < 3;
    _croak "Too many arguments to normalize_ym3" if @_ > 3;
    my @ymd = normalize_ym(@_);
    return @ymd[0,1,2];
}

# Like normalize_hms, but only returns the H, M, and S values.
# So you can do: $time = join ':' => normalize_hms3 ($input_hr, $input_min, $input_sec);
sub normalize_hms3
{
    _croak "Too few arguments to normalize_hms3"  if @_ < 2;
    _croak "Too many arguments to normalize_hms3" if @_ > 4;
    my @hms = normalize_hms(@_);
    return @hms[0,1,2];
}

sub normalize_month
{
    _croak "Too few arguments to normalize_month"  if @_ < 1;
    _croak "Too many arguments to normalize_month" if @_ > 1;
    _setup_locale;
    my $inm = shift;
    my $month;

    _bad('month', $inm) if !defined $inm;

    # Decode the month.
    if ($inm =~ /\A\s*  \d+  \s*\z/x)
    {
        # Numeric.  Simple 1-12 check.
        _bad('month', $inm)  if $inm < 1  ||  $inm > 12;
        $month = $inm;
    }
    else
    {
        # Might be a character month name
        if ($use_mail_months)
        {
            _init_mail_months  if !defined $mail_month_number;
            $month = $mail_month_number->{uc $inm};
        }
        else
        {
            $month = $number_of{uc $inm};
        }
        _bad('month', $inm)  if !defined $month;
    }
    return _lead0($month);
}

sub normalize_year
{
    _croak "Too few arguments to normalize_year"  if @_ < 1;
    _croak "Too many arguments to normalize_year" if @_ > 1;
    my $iny = shift;

    if ($iny =~ /\A\s*  \d{4}  \s*\z/x)
    {
        # Four-digit year.  Good.
        return sprintf '%04d', $iny+0;
    }

    if ($iny =~ /\A\s*  \d{2}  \s*\z/x)
    {
        # Two-digit year.  Guess the century.

        # If curr yy is <= 50, current century numbers are 0 - yy+50
        if ($current_yy <= 50)
        {
            return $iny + 100 * ($iny <= $current_yy+50?  $current_century : $current_century-1);
        }
        # If curr yy is > 50, current century numbers are yy-50 - 99
        else
        {
            return $iny + 100 * ($iny <= $current_yy-50?  $current_century+1 : $current_century);
        }
    }

    _bad('year', $iny);
}

sub normalize_ym
{
    _croak "Too few arguments to normalize_ym"  if @_ < 2;
    _croak "Too many arguments to normalize_ym" if @_ > 2;
    my ($iny, $inm) = @_;

    my ($year, $month) = (normalize_year($iny), normalize_month($inm));
    my $day = days_in ($month, $year);
    return normalize_ymd($year, $month, $day);
}


sub normalize_time
{
    _croak "Too many arguments to normalize_time" if @_ > 1;
    _bad ('time', $_[0])  if @_ == 1  &&  $_[0] !~ /\A\s*  \d+  \s*\z/x;
    my @t = @_?  localtime($_[0]) : localtime;
    return _normalize_gm_and_local_times(@t);
}

sub normalize_gmtime
{
    _croak "Too many arguments to normalize_gmtime" if @_ > 1;
    _bad ('time', $_[0])  if @_ == 1  &&  $_[0] !~ /\A\s*  \d+  \s*\z/x;
    my @t = @_?  gmtime($_[0]) : gmtime;
    return _normalize_gm_and_local_times(@t);
}

sub _normalize_gm_and_local_times
{
    my @t = @_;

    _setup_locale();

    if (wantarray)
    {
        my ($h24, $min, $sec, $h12, $ap, $ssm) = normalize_hms ($t[2], $t[1], $t[0]);
        my ($y4, $mon, $day, $dow, $dow_name, $dow_abbr, $mon_name, $mon_abbr)
            = normalize_ymd ($t[5] + 1900, $t[4] + 1, $t[3]);

        return ($sec, $min, $h24,
                $day, $mon, $y4,
                $dow, $t[7], $t[8],
                $h12, $ap, $ssm,
                $dow_name, $dow_abbr,
                $mon_name, $mon_abbr);
    }

    # Scalar.  Return hashref.
    my $hms_href = normalize_hms ($t[2], $t[1], $t[0]);
    my $ymd_href = normalize_ymd ($t[5] + 1900, $t[4] + 1, $t[3]);
    return { %$hms_href, %$ymd_href, yday => $t[7], isdst => $t[8] };
}

sub mon_name
{
    _croak "Too many arguments to mon_name" if @_ > 1;
    _croak "Too few arguments to mon_name"  if @_ < 1;
    my $mon = shift;
    _croak qq{Non-integer month "$mon" for mon_name}  if $mon !~ /\A\s* \d+ \s*\z/x;
    _bad('month', $mon) if $mon < 1  ||  $mon > 12;

    _setup_locale;
    return $Mon_Name[$mon];
}

sub mon_abbr
{
    _croak "Too many arguments to mon_abbr" if @_ > 1;
    _croak "Too few arguments to mon_abbr"  if @_ < 1;
    my $mon = shift;
    _croak qq{Non-integer month "$mon" for mon_abbr}  if $mon !~ /\A\s* \d+ \s*\z/x;
    _bad('month', $mon) if $mon < 1  ||  $mon > 12;

    _setup_locale;
    return $Mon_Abbr[$mon];
}

sub day_name
{
    _croak "Too many arguments to day_name" if @_ > 1;
    _croak "Too few arguments to day_name"  if @_ < 1;
    my $day = shift;
    _croak qq{Non-integer weekday "$day" for day_name}  if $day !~ /\A\s* \d+ \s*\z/x;
    _bad('weekday-number', $day) if $day < 0  ||  $day > 6;

    _setup_locale;
    return $Day_Name[$day];
}

sub day_abbr
{
    _croak "Too many arguments to day_abbr" if @_ > 1;
    _croak "Too few arguments to day_abbr"  if @_ < 1;
    my $day = shift;
    _croak qq{Non-integer weekday "$day" for day_abbr}  if $day !~ /\A\s* \d+ \s*\z/x;
    _bad('weekday-number', $day) if $day < 0  ||  $day > 6;

    _setup_locale;
    return $Day_Abbr[$day];
}

1;
__END__

=head1 SYNOPSIS

 use Time::Normalize;

 # Normalize year, month, day values
 $hashref = normalize_ymd ($in_yr, $in_mo, $in_d);
 ($year, $mon, $day,
  $dow, $dow_name, $dow_abbr,
  $mon_name, $mon_abbr) = normalize_ymd ($in_yr, $in_mo, $in_dy);

 # Normalize year, month values (day gets set to last day of month)
 $hashref = normalize_ym ($in_yr, $in_mo);
 @same_values_as_for_normalize_ymd = normalize_ym ($in_yr, $in_mo);

 # Normalize just a year value
 $year  = normalize_year($input_year);

 # Normalize just a month
 $month = normalize_month($input_month);

 # Normalize hour, minute, second values
 $hashref = normalize_hms ($in_h, $in_m, $in_s, $in_ampm);
 ($hour, $min, $sec,
  $h12, $ampm, $since_midnight)
          = normalize_hms ($in_h, $in_m, $in_s, $in_ampm);

 # Normalize year, month, day, hour, minute, second all at once
 $hashref = normalize_ymdhms ($in_yr, $in_mo, $in_dy, $in_h, $in_m, $in_s);
 ($year, $month, $day, $hour, $minute, $second)
          = normalize_ymdhms ($in_yr, $in_mo, $in_dy, $in_h, $in_m, $in_s);

 # Normalize values matched from Regexp::Common::time
 $hashref = normalize_rct ($pattern, @match_values);
 @values  = normalize_rct ($pattern, @match_values);

 # Normalize values from epoch time
 $hashref = normalize_time ($time_epoch);
 ($sec, $min, $hour,
  $day, $mon, $year,
  $dow, $yday, $isdst,
  $h12, $ampm, $since_midnight,
  $dow_name, $dow_abbr,
  $mon_name, $mon_abbr) = normalize_time ($time_epoch);

 # Normalize values from gmtime
 $hashref = normalize_gmtime ($time_epoch);
 @same_values_as_for_normalize_time = normalize_gmtime ($time_epoch);

Utility functions (not exported by default):

 use Time::Normalize qw(mon_name  mon_abbr  day_name  day_abbr
                        days_in   is_leap);

 $name = mon_name($month_number);    # input: 1 to 12
 $abbr = mon_abbr($month_number);    # input: 1 to 12
 $name = day_name($weekday_number);  # input: 0(Sunday) to 6
 $abbr = day_abbr($weekday_number);  # input: 0(Sunday) to 6
 $num  = days_in($month, $year);
 $bool = is_leap($year);

=head1 DESCRIPTION

Splitting a date into its component pieces is just the beginning.

Human date conventions are quirky (and I'm not just talking about the
dates I<I've> had!)  Despite the Y2K near-disaster, some people
continue to use two-digit year numbers.  Months are sometimes
specified as a number from 1-12, sometimes as a spelled-out name,
sometimes as a abbreviation.  Some months have more days than others.
Humans sometimes use a 12-hour clock, and sometimes a 24-hour clock.

This module performs simple but tedious (and error-prone) checks on
its inputs, and returns the time and/or date components in a
sanitized, standardized manner, suitable for use in the remainder of
your program.

Even when you get your values from a time-tested library function,
such as C<localtime> or C<gmtime>, you need to do routine
transformations on the returned values.  The year returned is off by
1900 (for historical reasons); the month is in the range 0-11; you may
want the month name or day of week name instead of numbers.  The
L</normalize_time> function decodes C<localtime>'s values into
commonly-needed formats.

=head1 FUNCTIONS

=over

=item normalize_ymd

 $hashref = normalize_ymd ($in_yr, $in_mo, $in_d);

 ($year, $mon, $day,
  $dow, $dow_name, $dow_abbr,
  $mon_name, $mon_abbr) = normalize_ymd ($in_yr, $in_mo, $in_dy);

Takes an arbitrary year, month, and day as input, and returns various
data elements in a standard, consistent format.  The output may be a
hash reference or a list of values.  If a hash reference is desired,
the keys of that hash will be the same as the variable names given in
the above synopsis; that is, C<day>, C<dow>, C<dow_abbr>, C<dow_name>,
C<mon>, C<mon_abbr>, C<mon_name>, and C<year>.

I<Input:>

The input year may be either two digits or four digits.  If two
digits, the century is chosen so that the resulting four-digit year is
closest to the current calendar year (i.e., within 50 years).

The input month may either be a number from 1 to 12, or a full month
name as defined by the current locale, or a month abbreviation as
defined by the current locale.  If it's a name or abbreviation, case
is not significant.

The input day must be a number from 1 to the number of days in the
specified month and year.

If any of the input values do not meet the above criteria, an
exception will be thrown. See L</DIAGNOSTICS>.

I<Output:>

C<  year     -> will always be four digits.

C<  month    -> will always be two digits, 01-12.

C<  day      -> will always be two digits 01-31.

C<  dow      -> will be a number from 0 (Sunday) to 6 (Saturday).

C<  dow_name -> will be the name of the day of the week, as defined
by the current locale, in the locale's preferred case.

C<  dow_abbr -> will be the standard weekday name abbreviation, as
defined by the current locale, in the locale's preferred case.

C<  mon_name -> will be the month name, as defined by the current
locale, in the locale's preferred case.

C<  mon_abbr -> will be the standard month name abbreviation, as
defined by the current locale, in the locale's preferred case.

=item normalize_ym

 $hashref = normalize_ym ($in_yr, $in_mo);

 ($year, $mon, $day,
  $dow, $dow_name, $dow_abbr,
  $mon_name, $mon_abbr) = normalize_ym ($in_yr, $in_mo);

Works exactly like L<normalize_ymd>, except that it does not take an
input day.  Instead, it computes the last day of the specified year
and month, and returns the values associated with that date.

This is equivalent to the following sequence:

 normalize_ymd ($in_yr, $in_mo, days_in ($in_mo, $in_yr));

=item normalize_year

 $year = normalize_year ($in_yr);

This takes a two-digit or four-digit year, and returns the four-digit
year.

=item normalize_month

 $month = normalize_month ($in_mo);

This takes a numeric month (1-12), alphabetic spelled-out month, or
alphabetic month abbreviation, and returns the two-digit month number
(01-12).

=item normalize_hms

 $hashref = normalize_hms ($in_h, $in_m, $in_s, $in_ampm);

 ($hour, $min, $sec,
  $h12, $ampm, $since_midnight)
          = normalize_hms ($in_h, $in_m, $in_s, $in_ampm);

Like L</normalize_ymd>, C<normalize_hms> takes a variety of possible
inputs and returns standardized values.  As above, the output may be a
hash reference or a list of values.  If a hash reference is desired,
the keys of that hash will be the same as the variable names given in
the above synopsis; that is, C<ampm>, C<h12>, C<hour>, C<min>, C<sec>,
and C<since_midnight>.  Also, a C<h24> key is provided as a synonym
for C<hour>.

I<Input:>

The input hour may either be a 12-hour or a 24-hour time value.  If
C<$in_ampm> is specified, C<$in_h> is assumed to be on a 12-hour
clock, and if C<$in_ampm> is absent, C<$in_h> is assumed to be on a
24-hour clock.

The input minute must be numeric, and must be in the range 0 to 59.

The input second C<$in_s> is optional.  If omitted, it defaults to 0.
If specified, it must be in the range 0 to 59.

The AM/PM indicator C<$in_ampm> is optional.  If specified, it may be
any of the following:

   a   am   a.m.  p   pm   p.m.  A   AM   A.M.  P   PM   P.M.

If any of the input values do not meet the above criteria, an
exception will be thrown. See L</DIAGNOSTICS>.

I<Output:>

C<  hour  -> The first output hour will always be on a 24-hour
clock, and will always be two digits, 00-23.

C<  min  -> will always be two digits, 00-59.

C<  sec  -> will always be two digits, 00-59.

C<  h12  -> is the 12-hour clock equivalent of C<$hour>.  It is
I<not> zero-padded.

C<  ampm -> will always be either a lowercase 'a' or a lowercase 'p',
no matter what format the input AM/PM indicator was, or even if it was
omitted.

C<  since_midnight -> is the number of seconds since midnight
represented by this time.

C<  h24  -> is a key created if you request a hashref as the
output; it's a synonym for C<hour>.

=item normalize_ymdhms

 $hashref = normalize_ymdhms ($in_y, $in_mon, $in_d,
                              $in_h, $in_min, $in_s, $in_ampm);

 ($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms ($in_y, $in_mon, $in_d,
                              $in_h, $in_min, $in_s, $in_ampm);

This is a convenience function that combines the capabilities of
L</normalize_ymd> and L</normalize_hms>.  As input, it takes a year,
month, and day (like normalize_ymd); and an hour, minute, optional
second, and optional am/pm indicator (like normalize_hms).

In list context, it returns the year, month, day, hour, minute,
and second.  (It does I<not> return all the extra values that
normalize_ymd and normalize_hms return in list context).

In scalar context, it returns a reference to a hash that contains
I<all> of the normalized values that normalize_ymd and normalize_hms
return.

=item normalize_rct

 $hashref = normalize_rct ($type, @values);

 @list = normalize_rct ($type, @values);

This function normalizes the result of a pattern match from the
L<Regexp::Common::time> module.

Regexp::Common::time contains several stock regular expression
patterns for matching common date and/or time formats.  This function
completes the process of parsing the matched date/time values.

The C<$type> parameter indicates which Regexp::Common::time pattern
was matched, and the C<@values> are the strings that were captured via
the C<-keep> parameter.  Supported patterns are: C<iso>, C<mail>,
C<MAIL>, C<american>, C<ymd>, C<mdy>, C<dmy>, C<hms>, and variants
such as C<y4m2d2>, etc.

For the C<iso>, C<mail>, and C<MAIL> patterns, normalize_rct returns
the same values as the L</normalize_ymdhms> function.

For the C<american>, C<ymd>, C<dmy> and other date-only patterns,
normalize_rct returns the same values as the L</normalize_ymd>
function.

For the C<hms> pattern, normalize_rct returns the same values as
L</normalize_hms>.

I<Example:>

 $input = 'Fri, 23 May 2008 23:02:04 +0500';
 @vals = $input =~ $RE{time}{mail} or die 'Bad input';
 $norm = normalize_rct ('mail', @vals);
 print "$norm->{dow_name} at $norm->{h12} $norm->{ampm}";
 # prints "Friday at 11 pm"

See L</EXAMPLES WITH Regexp::Common::time> for more examples.

=item normalize_time

 $hashref = normalize_time($time_epoch);

 ($sec, $min, $hour,
  $day, $mon, $year,
  $dow, $yday, $isdst,
  $h12, $ampm, $since_midnight,
  $dow_name, $dow_abbr,
  $mon_name, $mon_abbr) = normalize_time($time_epoch);

Takes a number in the usual perl epoch, passes it to
L<localtime|perlfunc/localtime>, and transforms the results.  If
C<$time_epoch> is omitted, the current time is used instead.

The output values (or hash values) are exactly as for
L</normalize_ymd> and L</normalize_hms>, above.

=item normalize_gmtime

Exactly the same as L<normalize_time>, but uses L<gmtime|perlfunc/gmtime>
internally instead of L<localtime|perlfunc/localtime>.

=item mon_name

 $name = mon_name($m);

Returns the full name of the specified month C<$m>; C<$m> ranges from
1 (January) to 12 (December).  The name is returned in the language
and case appropriate for the current locale.

=item mon_abbr

 $abbr = mon_abbr($m);

Returns the abbreviated name of the specified month C<$m>; C<$m>
ranges from 1 (Jan) to 12 (Dec).  The name is returned in the language
and case appropriate for the current locale.

=item day_name

 $name = day_name($d);

Returns the full name of the specified day of the week C<$d>; C<$d>
ranges from 0 (Sunday) to 6 (Saturday).  The name is returned in the
language and case appropriate for the current locale.

=item day_abbr

 $abbr = day_abbr($d);

Returns the abbreviated name of the specified day of the week C<$d>;
C<$d> ranges from 0 (Sun) to 6 (Sat).  The name is returned in the
language and case appropriate for the current locale.

=item days_in

 $num = days_in ($month, $year);

Returns the number of days in the specified month and year.  If the
month is not 2 (February), C<$year> isn't even examined.

=item is_leap

 $boolean = is_leap ($year);

Returns C<true> if the given year is a leap year, according to the
usual Gregorian rules.

=back

=head1 DIAGNOSTICS

The functions in this module throw exceptions (that is, they C<croak>)
whenever invalid arguments are passed to them.  Therefore, it is
generally a Good Idea to trap these exceptions with an C<eval> block.

The error messages are meant to be easy to parse, if you need to.
There are two kinds of errors thrown: data errors, and programming
errors.

Data errors are caused by invalid data values; that is, values that do
not conform to the expectations listed above.  These messages all look
like:

C<   Time::Normalize: Invalid> I<thing>C<: ">I<value>C<">

Programming errors are caused by you--passing the wrong number or type
of parameters to a function.  These messages look like one of the
following::

C<1.   Too> I<{many|few}>C< arguments to> I<function_name>

C<2.   Non-integer month ">I<month>C<" for mon_name>

C<3.   Unknown Regexp::Common::time pattern: ">I<type>C<">

#1 can be thrown by almost any of the functions.  #2 can only be
thrown by the L</days_in> function.  #3 can only be thrown by the
L</normalize_rct> function.

=head1 EXAMPLES

 $h = normalize_ymd (2005, 'january', 4);
 #
 # Returns:
 #         $h->{day}        "04"
 #         $h->{dow}        2
 #         $h->{dow_abbr}   "Tue"
 #         $h->{dow_name}   "Tuesday"
 #         $h->{mon}        "01"
 #         $h->{mon_abbr}   "Jan"
 #         $h->{mon_name}   "January"
 #         $h->{year}       2005
 # ------------------------------------------------

 $h = normalize_ymd ('05', 12, 31);
 #
 # Returns:
 #         $h->{day}        31
 #         $h->{dow}        6
 #         $h->{dow_abbr}   "Sat"
 #         $h->{dow_name}   "Saturday"
 #         $h->{mon}        12
 #         $h->{mon_abbr}   "Dec"
 #         $h->{mon_name}   "December"
 #         $h->{year}       2005
 # ------------------------------------------------

 $h = normalize_ymd (2005, 2, 29);
 #
 # Throws an exception:
 #         Time::Normalize: Invalid day: "29"
 # ------------------------------------------------

 $h = normalize_hms (9, 10, 0, 'AM');
 #
 # Returns:
 #         $h->{ampm}       "a"
 #         $h->{h12}        9
 #         $h->{h24}        "09"
 #         $h->{hour}       "09"
 #         $h->{min}        10
 #         $h->{sec}        "00"
 #         $h->{since_midnight}    33000
 # ------------------------------------------------

 $h = normalize_hms (9, 10, undef, 'p.m.');
 #
 # Returns:
 #         $h->{ampm}       "p"
 #         $h->{h12}        9
 #         $h->{h24}        21
 #         $h->{hour}       21
 #         $h->{min}        10
 #         $h->{sec}        "00"
 #         $h->{since_midnight}    76200
 # ------------------------------------------------

 $h = normalize_hms (1, 10);
 #
 # Returns:
 #         $h->{ampm}       "a"
 #         $h->{h12}        1
 #         $h->{h24}        "01"
 #         $h->{hour}       "01"
 #         $h->{min}        10
 #         $h->{sec}        "00"
 #         $h->{since_midnight}    4200
 # ------------------------------------------------

 $h = normalize_hms (13, 10);
 #
 # Returns:
 #         $h->{ampm}       "p"
 #         $h->{h12}        1
 #         $h->{h24}        13
 #         $h->{hour}       13
 #         $h->{min}        10
 #         $h->{sec}        "00"
 #         $h->{since_midnight}    47400
 # ------------------------------------------------

 $h = normalize_hms (13, 10, undef, 'pm');
 #
 # Throws an exception:
 #         Time::Normalize: Invalid hour: "13"
 # ------------------------------------------------

 $h = normalize_gmtime(1131725587);
 #
 # Returns:
 #         $h->{ampm}       "p"
 #         $h->{sec}        "07",
 #         $h->{min}        13,
 #         $h->{hour}       16,
 #         $h->{day}        11,
 #         $h->{mon}        11,
 #         $h->{year}       2005,
 #         $h->{dow}        5,
 #         $h->{yday}       314,
 #         $h->{isdst}      0,
 #         $h->{h12}        4
 #         $h->{ampm}       "p"
 #         $h->{since_midnight}        58_387,
 #         $h->{dow_name}   "Friday",
 #         $h->{dow_abbr}   "Fri",
 #         $h->{mon_name}   "November",
 #         $h->{mon_abbr}   "Nov",
 # ------------------------------------------------

=head1 EXAMPLES WITH Regexp::Common::time

This module plus L<Regexp::Common::time> is a powerful combination for
parsing date and time input.

 use Regexp::Common qw(time);
 use Time::Normalize;

 # Informal American-style dates
 $input = "January 7, '08";
 @vals = $input =~ $RE{time}{american}{-keep};
 $d = normalize_rct('american', @vals);
 print "$d->{year}/$d->{mon}/$d->{day} was a $d->{dow_name}";
 # Prints: 2008/01/07 was a Monday
 #
 $input = "Jan 7, 2008";
 @vals = $input =~ $RE{time}{american}{-keep};
 $d = normalize_rct('american', @vals);
 print "$d->{year}/$d->{mon}/$d->{day} was a $d->{dow_name}";
 # Prints: 2008/01/07 was a Monday

 # European-style day/month/year dates
 $input = '7 March 2007';
 @vals = $input =~ $RE{time}{dmy}{-keep};
 $d = normalize_rct('dmy', @vals);
 print "$d->{year}/$d->{mon}/$d->{day} was a $d->{dow_name}";
 # Prints: 2007/03/07 was a Friday
 #
 $input = '07.03.07';
 @vals = $input =~ $RE{time}{dmy}{-keep};
 $d = normalize_rct('dmy', @vals);
 print "$d->{year}/$d->{mon}/$d->{day} was a $d->{dow_name}";
 # Prints: 2007/03/07 was a Friday

 # Time parsing:
 $input = '13:24';
 @vals = $input =~ $RE{time}{hms}{-keep};
 $t = normalize_rct('hms', @vals);
 print "$t->{hour}:$t->{min}:$t->{sec}";    # 13:24:00
 #
 $input = '1.24.00 P.M.';
 @vals = $input =~ $RE{time}{hms}{-keep};
 $t = normalize_rct('hms', @vals);
 print "$t->{hour}:$t->{min}:$t->{sec}";    # 13:24:00

=head1 EXPORTS

This module exports the following symbols into the caller's namespace:

 normalize_ymd
 normalize_ymd3
 normalize_hms
 normalize_ymdhms
 normalize_time
 normalize_gmtime
 normalize_month
 normalize_year
 normalize_ym
 normalize_ym3
 normalize_rct

The following symbols are available for export:

 mon_name
 mon_abbr
 day_name
 day_abbr
 is_leap
 days_in

You may use the export tag "all" to get all of the above symbols:

 use Time::Normalize ':all';

=head1 REQUIREMENTS

If L<POSIX> and L<I18N::Langinfo> is available, this module will use
them; otherwise, it will use hardcoded English values for month and
weekday names.

L<Test::More> is required for the test suite.

=head1 SEE ALSO

See L<Regexp::Common::time> for a L<Regexp::Common> plugin that
matches nearly any date format imaginable.

=head1 BUGS

=over

=item *

Uses Gregorian rules for computing whether a year is a leap year, no
matter how long ago the year was.

=back

=head1 NOT A BUG

=over

=item *

By convention, noon is 12:00 pm; midnight is 12:00 am.

=back

=head1 AUTHOR / COPYRIGHT

Copyright © 2005–2014 by Eric J. Roode, ROODE I<-at-> cpan I<-dot-> org

All rights reserved.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

This module is copyrighted only to ensure proper attribution of
authorship and to ensure that it remains available to all.  This
module is free, open-source software.  This module may be freely used
for any purpose, commercial, public, or private, provided that proper
credit is given, and that no more-restrictive license is applied to
derivative (not dependent) works.

Substantial efforts have been made to ensure that this software meets
high quality standards; however, no guarantee can be made that there
are no undiscovered bugs, and no warranty is made as to suitability to
any given use, including merchantability.  Should this module cause
your house to burn down, your dog to collapse, your heart-lung machine
to fail, your spouse to desert you, or George Bush to be re-elected, I
can offer only my sincere sympathy and apologies, and promise to
endeavor to improve the software.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2.0.21 (MingW32)

iEYEARECAAYFAlNX4w8ACgkQwoSYc5qQVqoLMQCffdGYkRCvZPFLpLZ3quHifjji
U5MAnil5mEb46mgKbfZ6lsNLNLT3Qh8O
=RW4m
-----END PGP SIGNATURE-----

=end gpg
