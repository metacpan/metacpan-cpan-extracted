
=head1 Name

qbit::Array - Functions to manipulate dates.

=cut

package qbit::Date;
$qbit::Date::VERSION = '2.4';
use strict;
use warnings;
use utf8;

use base qw(Exporter);

use POSIX qw(strftime);
use Time::Local;
use Date::Calc qw(Add_Delta_YMDHMS Add_Delta_YM Monday_of_Week Week_of_Year Delta_YMDHMS Delta_Days Days_in_Month);

use qbit::Exceptions;
use qbit::Array;
use qbit::GetText;

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      trdate curdate date_add date_sub name2date name2dates
      dates2array dates_delta dates_delta_days compare_dates
      check_date format_date is_date_in_future is_date_in_past
      );
    @EXPORT_OK = @EXPORT;
}

our %TR_HS = (
    norm => {
        '>' => sub {[@{$_[0]}]},
        '<' => sub {[@{$_[0]}]},
    },
    db => {
        '>' => sub {sprintf('%04d-%02d-%02d', @{$_[0]}[0 .. 2])},
        '<' => sub {
            shift =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
              ? [$1, $2, $3, 0, 0, 0]
              : [0, 0, 0, 0, 0, 0];
        },
    },
    db_time => {
        '>' => sub {
            sprintf("%04d-%02d-%02d %02d:%02d:%02d", @{$_[0]});
        },
        '<' => sub {
            shift =~ /\A(\d{4})-(\d{2})-(\d{2})(?:(?:\s+|T)(\d{1,2}):(\d{1,2}):(\d{1,2}))?\z/
              ? [$1, $2, $3, $4 // 0, $5 // 0, $6 // 0]
              : [0, 0, 0, 0, 0, 0];
        },
    },
    sec => {
        '>' => sub {
            $_[0]->[1] < 1
              ? 0
              : timelocal($_[0]->[5] || 0, $_[0]->[4] || 0, $_[0]->[3] || 0, $_[0]->[2], ($_[0]->[1] - 1), $_[0]->[0]);
        },
        '<' => sub {
            my @dt = localtime(shift);
            [$dt[5] + 1900, $dt[4] + 1, $dt[3], $dt[2], $dt[1], $dt[0]];
        },
    },
    days_in_month => {
        '>' => sub {
            Days_in_Month($_[0]->[0], $_[0]->[1]);
        },
    },
);

=head1 Functions

=head2 trdate

B<Arguments:>

=over

=item

B<$iformat> - string, input format;

=item

B<$oformat> - string, output format. One of:

=over

=item

B<norm> - array ref, ['year', 'month (1-12)', 'day (1-31)', 'hour (0-23)', 'minute (0-59)', 'second (0-59)'];

=item

B<db_time> - string, 'YYYY-MM-DD hh:mm:ss';

=item

B<sec> - number, seconds like in C<localtime>;

=item

B<days_in_month> - number, days in month. Cannot convert from this type to other.

=back

=item

B<$date> - scalar, date in input format.

=back

B<Return value:> scalar, date in output format. C<undef> if conversion has errors.

Convert date from C<iformat> to C<oformat>.

 trdate(db => sec => '2000-01-01');

=cut

sub trdate {
    my ($iformat, $oformat, $date) = @_;

    throw gettext('Unknown iformat "%s"', $iformat) unless exists($TR_HS{$iformat});
    throw gettext('Unknown oformat "%s"', $oformat) unless exists($TR_HS{$oformat});
    throw gettext('Cannott convert from format "%s"', $iformat)
      unless exists($TR_HS{$iformat}->{'<'});

    my $norm_date = $TR_HS{$iformat}->{'<'}($date);
    return undef if @$norm_date == 6 && !grep {$_ != 0} @$norm_date;
    $_ = int($_) foreach @$norm_date;
    return $TR_HS{$oformat}->{'>'}($norm_date);
}

=head2 curdate

B<Arguments as hash:>

=over

=item

B<oformat> - string, output format, see L</trdate>.

=back

B<Return value:> scalar, current date in output format.

 curdate(oformat => 'db');

=cut

sub curdate {
    my (%opts) = @_;

    my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime(time());
    $year += 1900;
    $month++;

    my $res = [$year, $month, $day, $hour, $min, $sec];

    return exists($opts{'oformat'}) ? trdate(norm => $opts{'oformat'} => $res) : $res;
}

=head2 date_add

B<Arguments:>

=over

=item

B<$date> - scalar, date;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat> - string, input format, default - 'norm';

=item

B<oformat> - string, output format, default - 'norm';

=item

B<second> - number, quantity of seconds to add;

=item

B<minute> - number, quantity of minutes to add;

=item

B<hour> - number, quantity of hours to add;

=item

B<day> - number, quantity of days to add;

=item

B<week> - number, quantity of weeks to add;

=item

B<month> - number, quantity of months to add;

=item

B<year> - number, quantity of years to add;

=back

=back

B<Return value:> scalar, date in output format.

 date_add('2000-01-01', day => 12, hour => 5, iformat => 'db', oformat => 'db');

=cut

sub date_add {
    my ($date, %opts) = @_;

    $date = trdate(($opts{'iformat'} || 'norm') => 'norm' => $date);

    $opts{'day'} += $opts{'week'} * 7 if exists($opts{'week'});
    my @res = ();
    if ($opts{month} || $opts{year}) {

        # do not warp into next month (year)
        @res = (Add_Delta_YM(@$date[0, 1, 2], $opts{year} // 0, $opts{month} // 0), 0, 0, 0);
        @res = Add_Delta_YMDHMS(@res, 0, 0, map {$opts{$_} || 0} qw(day hour minute second));
    } else {
        @res = Add_Delta_YMDHMS(@$date, map {$opts{$_} || 0} qw(year month day hour minute second));
    }

    return exists($opts{'oformat'}) ? trdate(norm => $opts{'oformat'} => \@res) : \@res;
}

=head2 date_sub

See L</date_add>

=cut

sub date_sub {
    my ($date, %opts) = @_;

    $opts{$_} = -($opts{$_} || 0) foreach qw(year month week day hour minute second);

    return date_add($date, %opts);
}

=head2 name2date

B<Arguments:>

=over

=item

B<$name> - string, date caption. Available values:

=over

lastyesterday

lasttoday

daybeforeyesterday

yesterday

today or day

tomorrow

dayaftertomorrow;

=back

=item

B<%opts> - hash, additional arguments:

=over

=item

B<oformat>: string, output format, default - 'norm'.

=back

=back

B<Return value:> scalar, date in output format. C<undef> unless known name.

 name2date('yesterday', oformat => 'db');

=cut

sub name2date {
    my ($name, %opts) = @_;

    my $res =
        $name eq 'lastyesterday'      ? date_sub(curdate(), day => 8)
      : $name eq 'lasttoday'          ? date_sub(curdate(), day => 7)
      : $name eq 'daybeforeyesterday' ? date_sub(curdate(), day => 2)
      : $name eq 'yesterday'          ? date_sub(curdate(), day => 1)
      : $name eq 'today'              ? curdate()
      : $name eq 'day'                ? curdate()
      : $name eq 'tomorrow'         ? date_add(curdate(), day => 1)
      : $name eq 'dayaftertomorrow' ? date_add(curdate(), day => 2)
      :                               return;

    return exists($opts{'oformat'}) ? trdate(norm => $opts{'oformat'} => $res) : $res;
}

=head2 name2dates

B<Arguments:>

=over

=item

B<$name> - string, period caption. One of:

=over

=item

Any from L</name2date>;

=item

B<week, sevendays, last7days>: last 7 days, including today;

=item

B<thisweek>: current week, from Monday to today;

=item

B<lastweek, pastweek>: past week, from Monday to Sunday;

=item

B<tendays>: last 10 days, including today;

=item

B<lastmonth, pastmonth>: past month, from 1th to (28|29|30|31)th;

=item

B<month>: current month, from 1th to (28|29|30|31)th;

=item

B<thismonth>: current month, from 1th to today;

=item

B<year, thisyear>: current year, from January 1th to December 31th;

=item

B<{N}days>: last {N} days, including today, {N} - numer, quantity of days;

=item

B<pastpastweek>: week before past week, from Monday to Sunday;

=item

B<past{N}days>: last {N} days before {N} days, {N} - number of days;

=item

B<pastpastmonth>: month before past month, from 1th to (28|29|30|31)th;

=item

B<pastyear>: past year, from January 1th to December 31th;

=item

B<twoyearsago>: year before past year, from January 1th to December 31th;

=back

=item

B<$fd> - scalar, start date. Return if unknown period name;

=item

B<$td> - scalar, end date. Return if unknown period name;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat>: string, input format for C<$fd> and C<$td>, default - 'norm';

=item

B<oformat>: string, output format, default - 'norm'.

=back

=back

B<Return value>: array, (start_date, end_date).

 ($fd, $td) = name2date('pastyear', [], [], oformat => 'db'); # ('2012-01-01', '2012-12-31')
 ($fd, $td) = name2date('other', '2000-01-01', '2000-01-03', iformat => 'db', oformat => 'db'); # ('2000-01-01', '2000-01-03')

=cut

sub name2dates {
    my ($name, $fd, $td, %opts) = @_;

    $fd = trdate(($opts{'iformat'} || 'norm') => 'norm' => $fd);
    $td = trdate(($opts{'iformat'} || 'norm') => 'norm' => $td);

    if (my $date_by_name = name2date($name)) {
        $fd = [@$date_by_name];
        $td = [@$date_by_name];
    } elsif (in_array($name, [qw(week sevendays last7days)])) {
        $td = curdate();
        $fd = date_sub($td, day => 6);
    } elsif ($name eq 'thisweek') {
        $fd          = curdate();
        $td          = curdate();
        @$fd[0 .. 2] = Monday_of_Week(Week_of_Year(@$fd[0 .. 2]));
    } elsif (in_array($name, [qw(lastweek pastweek)])) {
        $fd = date_sub(curdate(), week => 1);
        @$fd[0 .. 2] = Monday_of_Week(Week_of_Year(@$fd[0 .. 2]));
        $td = date_add($fd, day => 6);
    } elsif ($name eq 'tendays') {
        $td = curdate();
        $fd = date_sub($td, day => 9);
    } elsif (in_array($name, [qw(lastmonth pastmonth)])) {
        $fd      = date_sub(curdate(), month => 1);
        $td      = [@$fd];
        $fd->[2] = 1;
        $td->[2] = trdate(norm => days_in_month => $td);
    } elsif ($name eq 'month') {
        $fd      = curdate();
        $td      = curdate();
        $fd->[2] = 1;
        $td->[2] = trdate(norm => days_in_month => $td);
    } elsif ($name eq 'thismonth') {
        $fd      = curdate();
        $td      = curdate();
        $fd->[2] = 1;
    } elsif ($name eq 'last30days') {
        $td = curdate();
        $fd = date_sub($td, day => 30);
    } elsif (in_array($name, [qw(year thisyear)])) {
        $fd = curdate();
        $td = curdate();
        $fd->[1] = $fd->[2] = 1;
        ($td->[1], $td->[2]) = (12, 31);
    } elsif ($name =~ /^(\d+)days$/) {
        $td = curdate();
        $fd = date_sub($td, day => $1 - 1);
    } elsif ($name eq 'pastpastweek') {
        $fd = date_sub(curdate(), week => 2);
        @$fd[0 .. 2] = Monday_of_Week(Week_of_Year(@$fd[0 .. 2]));
        $td = date_add($fd, day => 6);
    } elsif ($name =~ /^past(\d+)days$/) {
        $fd = date_sub(curdate(), day => $1 * 2 - 1);
        $td = date_sub(curdate(), day => $1);
    } elsif ($name eq 'pastpastmonth') {
        $fd      = date_sub(curdate(), month => 2);
        $td      = [@$fd];
        $fd->[2] = 1;
        $td->[2] = trdate(norm => days_in_month => $td);
    } elsif ($name eq 'pastyear') {
        $fd = date_sub(curdate(), year => 1);
        $td = [@$fd];
        $fd->[1] = $fd->[2] = 1;
        ($td->[1], $td->[2]) = (12, 31);
    } elsif ($name eq 'twoyearsago') {
        $fd = date_sub(curdate(), year => 2);
        $td = [@$fd];
        $fd->[1] = $fd->[2] = 1;
        ($td->[1], $td->[2]) = (12, 31);
    }

    $fd->[3] = $fd->[4] = $fd->[5] = 0;
    ($td->[3], $td->[4], $td->[5]) = (23, 59, 59);

    $fd = trdate(norm => $opts{'oformat'} => $fd) if exists($opts{'oformat'});
    $td = trdate(norm => $opts{'oformat'} => $td) if exists($opts{'oformat'});
    return ($fd, $td);
}

=head2 dates2array

B<Arguments:>

=over

=item

B<$fd> - scalar, start date;

=item

B<$td> - scalar, end date;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat>: string, input format, default - 'norm';

=item

B<oformat>: string, output format, default - 'norm';

=item

B<interval>: string, step size: day, week, month, year. Default day.

=back

=back

B<Return value>: array of scalars.

 my @dates = dates2array('2001-01-01', '2001-01-04', iformat => 'db', oformat => 'db');

=cut

sub dates2array {
    my ($fd, $td, %opts) = @_;

    $opts{'interval'} = 'day' unless $opts{'interval'} && in_array($opts{'interval'}, [qw(day week month year)]);

    my $start_dt = trdate(($opts{'iformat'} || 'norm') => db_time => $fd);
    my $end_dt   = trdate(($opts{'iformat'} || 'norm') => db_time => $td);

    my @res = ();
    while ($start_dt le $end_dt) {
        push(@res, trdate(db_time => ($opts{'oformat'} || 'norm') => $start_dt));
        $start_dt = date_add($start_dt, iformat => 'db_time', oformat => 'db_time', $opts{'interval'} => 1);
    }

    return @res;
}

=head2 dates_delta

B<Arguments:>

=over

=item

B<$fd> - scalar, start date;

=item

B<$td> - scalar, end date;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat>: string, input format, default - 'norm'.

=back

=back

B<Return value:> array ref, [years, months, days, hours, minutes, seconds].

=cut

sub dates_delta {
    my ($fd, $td, %opts) = @_;

    $fd = trdate(($opts{'iformat'} || 'norm') => 'norm' => $fd);
    $td = trdate(($opts{'iformat'} || 'norm') => 'norm' => $td);

    return [Delta_YMDHMS(@$fd, @$td)];
}

=head2 dates_delta_days

B<Arguments:> See L</dates_delta>

B<Return value:> number, days from C<$fd> to C<$td>.

=cut

sub dates_delta_days {
    my ($fd, $td, %opts) = @_;

    $fd = trdate(($opts{'iformat'} || 'norm') => 'norm' => $fd);
    $td = trdate(($opts{'iformat'} || 'norm') => 'norm' => $td);

    return Delta_Days(@$fd[0 .. 2], @$td[0 .. 2]);
}

=head2 compare_dates

B<Arguments:>

=over

=item

B<$dt1> - scalar, first date;

=item

B<$dt2> - scalar, second date;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat1>: string, input format for first date, default - 'norm'.

=item

B<iformat2>: string, input format for second date, default - 'norm'.

=back

=back

B<Return value:>

=over

=item

B<-1>: C<$dt1 < $dt2>;

=item

B<0>: C<$dt1 = $dt2>;

=item

B<1>: C<< $dt1 > $dt2 >>.

=back

 compare_dates($dt1, $dt2, iformat1 => 'db', iformat2 => 'norm')

=cut

sub compare_dates {
    my ($dt1, $dt2, %opts) = @_;

    return trdate($opts{'iformat1'} || 'norm', "sec", $dt1) <=> trdate($opts{'iformat2'} || 'norm', "sec", $dt2);

}

=head2 format_date

B<Arguments:>

=over

=item

B<$date> - scalar, date;

=item

B<$format> - string, output format;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat>: string, input format for date, default - 'norm'.

=back

=back

B<Formaters:>

    %a  Abbreviated weekday name                                                Thu
    %A  Full weekday name                                                       Thursday
    %b  Abbreviated month name                                                  Aug
    %B  Full month name                                                         August
    %c  Date and time representation                                            Thu Aug 23 14:55:02 2001
    %d  Day of the month (01-31)                                                23
    %H  Hour in 24h format (00-23)                                              14
    %I  Hour in 12h format (01-12)                                              02
    %j  Day of the year (001-366)                                               235
    %m  Month as a decimal number (01-12)                                       08
    %M  Minute (00-59)                                                          55
    %p  AM or PM designation                                                    PM
    %S  Second (00-61)                                                          02
    %U  Week number with the first Sunday as the first day of week one (00-53)  33
    %w  Weekday as a decimal number with Sunday as 0 (0-6)                      4
    %W  Week number with the first Monday as the first day of week one (00-53)  34
    %x  Date representation                                                     08/23/01
    %X  Time representation                                                     14:55:02
    %y  Year, last two digits (00-99)                                           01
    %Y  Year                                                                    2001
    %Z  Timezone name or abbreviation                                           CDT
    %%  A % sign    %

B<Return value:> string

 format_date('2001-01-01', '%Y %B', iformat => 'db');

=cut

sub format_date {
    my ($date, $format, %opts) = @_;

    my $fdate = strftime($format, localtime(trdate($opts{'iformat'} || 'norm', "sec", $date)));

    utf8::decode($fdate);

    return $fdate;
}

=head2 is_date_in_future

B<Arguments:>

=over

=item

B<$date> - scalar, date;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<iformat>: string, input format for date, default - 'norm'.

=back

=back

B<Return value:> boolean.

 is_date_in_future($date, iformat => 'db')

=cut

sub is_date_in_future {
    my ($date, %opts) = @_;

    return compare_dates(
        $date,
        curdate(oformat => 'sec'),
        iformat1 => $opts{iformat} ? $opts{iformat} : 'norm',
        iformat2 => 'sec',
    ) == 1;

}

=head2 is_date_in_past

See L</is_date_in_future>

=cut

sub is_date_in_past {
    my ($date, %opts) = @_;

    return compare_dates(
        $date,
        curdate(oformat => 'sec'),
        iformat1 => $opts{iformat} ? $opts{iformat} : 'norm',
        iformat2 => 'sec',
    ) == -1;

}

=head2 check_date

B<Arguments:>

=over

=item

B<$date> - scalar, date;

=item

B<%opts> - hash, additional arguments:

=over

=item B<iformat>: string, input format for date, default - 'norm'.

=back

=back

B<Return value:> boolean.

 check_date($date, iformat => 'db');

=cut

sub check_date {
    my ($date, %opts) = @_;

    $opts{iformat} ||= "norm";

    my $result;
    my @d;

    eval {
        @d = @{trdate($opts{iformat} => norm => $date)};
        if (Date::Calc::check_date(@d[0 .. 2]) && Date::Calc::check_time(@d[3 .. 5])) {
            $result = 1;
        }
    };

    if ($result) {
        return 1;
    } else {
        return '';
    }
}

1;

=head2 Extending trdate

 local $qbit::Date::TR_HS{'new_type'} = {
     '>' => sub {my $dt_norm = shift;     ...Convert $dt_norm to new_type code...},
     '<' => sub {my $dt_new_type = shift; ...Convert $dt_new_type to norm code...};
 };
