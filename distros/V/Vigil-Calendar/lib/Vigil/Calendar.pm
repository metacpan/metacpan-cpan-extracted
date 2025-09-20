package Vigil::Calendar;

require 5.010;
use Carp;
use strict;
use warnings;
use Time::Local qw(timegm);
our $VERSION = '2.1.4';

use constant MONTHS => { 1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December' };

use constant BASE_DAYS_IN_MONTH => { 1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31 };

use constant DAYS_IN_A_WEEK => 7;

sub new {
	my ($pkg, $y, $m) = @_;
    #Default to current date if missing
    unless (defined $y && defined $m) {
        my ($sec, $min, $hour, $mday, $mon, $year) = gmtime();
        $y = $year + 1900;
        $m = $mon + 1;
    }
    #Validate inputs
	return unless $y =~ /^\d+$/ && $m =~ /^\d+$/ && $m >= 1 && $m <= 12;
	#Calculate previous and next months/years
    my ($pm, $py) = $m == 1  ? (12, $y - 1) : ($m - 1, $y);
    my ($nm, $ny) = $m == 12 ? (1, $y + 1) : ($m + 1, $y);
	bless {
		_year		           => $y,
		_month		           => $m,
		_previous_month_number => $pm,
		_previous_month_year   => $py,
		_next_month_number     => $nm,
		_next_month_year       => $ny,
	}, $pkg;
}

sub month { return $_[0]->{_month}; }

sub year { return $_[0]->{_year}; }

sub previous_month_number{ return $_[0]->{_previous_month_number}; }

sub previous_month_year{ return $_[0]->{_previous_month_year}; }

sub days_in_previous_month { return $_[0]->days_in_month($_[0]->{_previous_month_year}, $_[0]->{_previous_month_number}); }

sub next_month_number{ return $_[0]->{_next_month_number}; }

sub next_month_year{ return $_[0]->{_next_month_year}; }

sub days_in_next_month { return $_[0]->days_in_month($_[0]->{_next_month_year}, $_[0]->{_next_month_number}); }

sub evaluate {
	#Returns an evaluation of the _month in the following list form:
	#($name_of_month, $days_in_previous_month, $days_in_this_month, $days_in_next_month, $is_a_leap_year,
	#		$name_of_day_of_first_day, $name_of_day_of_last_day, $num_of_sundays)
	my $self = shift;
	my @ret_array;
	$ret_array[0] = $self->month_name($self->{_month});
	$ret_array[1] = $self->days_in_previous_month;
	$ret_array[2] = $self->days_in_month;
	$ret_array[3] = $self->days_in_next_month;
	$ret_array[4] = $self->is_a_leap_year;
	$ret_array[5] = $self->dayname(1);
	$ret_array[6] = $self->dayname($self->days_in_month);
	my @count = $self->_get_sundays;
	$ret_array[7] = $#count + 1;
	return(@ret_array);
}

sub is_a_leap_year {
	#Returns true if the object year is a leap year, false if it isn't.
    my ($self, $test_year) = @_;
    $test_year ||= $self->{_year};
    return 1 if $test_year % 4 == 0 && ($test_year % 100 != 0 || $test_year % 400 == 0);
    return 0;
}

sub dayname {
    my ($self, $dom, $month, $year) = @_;
    my $mo = $month // $self->{_month};
    my $yr = $year // $self->{_year};
	return unless length($yr) == 4;
	return unless $mo >= 1 && $mo <= 12;
	# Zeller's congruence: https://www.geeksforgeeks.org/dsa/zellers-congruence-find-day-date/
    # Zeller's congruence: 0 = Saturday, 1 = Sunday ... 6 = Friday
    my $y = $yr;
    my $m = $mo;
    if ($m == 1) { $m = 13; $y--; }
    elsif ($m == 2) { $m = 14; $y--; }

    my $k = $y % 100;
    my $j = int($y / 100);

    my $f = int($dom + int((13 * ($m + 1)) / 5) + $k + int($k / 4) + int($j / 4) + 5 * $j) % 7;

    # Convert Zeller's (0=Sat) to your system (0=Sun, 6=Sat)
    my $dow = ($f + 6) % 7;
	#This is not reliant on the one-based list of week days, so we use a zero-based list.
    my %days = (
        0 => 'Sunday',
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday',
    );
	return $days{$dow};
}

sub weekday {
	my ($self, $dom, $month, $year) = @_;
	$dom   //= 1;
	$month //= $self->{_month};
	$year  //= $self->{_year};
	return 0 unless $dom =~ /^\d+$/;
	return unless $dom <= $self->days_in_month($year, $month);
	#Tomohiko Sakamoto’s Algorithm - https://www.geeksforgeeks.org/dsa/tomohiko-sakamotos-algorithm-finding-day-week/
    my @offset = (0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4);
    $year -= $month < 3; # Jan & Feb are considered part of previous year
	#We add 1 because this module calculates Sunday as 1, not 0.
    return 1 + (($year + int($year / 4) - int($year / 100) + int($year / 400) + $offset[$month - 1] + $dom) % DAYS_IN_A_WEEK);
}

sub calendar_week {
	#This method takes a day of month as an argument and then returns
	#the calendar week that day is in based on the objects current
	#year and month. Max value for this is 6.
    return int( ($_[1] + $_[0]->weekday(1) - 2) / 7 ) + 1;
}

sub month_name {
	#Convert month number to name
	my ($self, $num, $short) = @_;
	$num //= $self->{_month};
    return 0 unless $num >= 1 && $num <= 12;
	return $short ? substr(MONTHS->{$num}, 0, 3) : MONTHS->{$num};
}

sub month_number {
	#Convert month name to number
	my $self    = shift;
	my $month = shift;
	$month = lc(substr($month, 0, 3));
	my %hash = (jan => '1', feb => '2', mar => '3', apr => '4', may => '5', jun => '6', jul => '7', aug => '8', sep => '9', oct => '10', nov => '11', dec => '12');
	if($hash{$month}) {
		return($hash{$month});
	} else {
		return(0);
	}
}

sub weeks_in_month { return 1 + int( ($_[0]->days_in_month($_[1], $_[2]) - (9 - $_[0]->weekday(1, $_[2], $_[1])) + 6) / 7 ); }

sub days_in_month {
	my $self = shift;
	my $test_year = shift || $self->{_year};
	my $test_month = shift || $self->{_month};
	my %days = %{ BASE_DAYS_IN_MONTH() };
	$days{2} = 29 if $test_month == 2 && $self->is_a_leap_year($test_year);
	return($days{$test_month});
}

sub week_definition {
	# NOTE: This module uses 1-based weekdays (Sunday = 1, Monday = 2, …, Saturday = 7)
	# instead of the more common 0-based system (Sunday = 0). 
	# This was originally done to simplify the calculations in week_definition, 
	# which constructs calendar weeks including spillover from previous/next months.
	#
    #No matter what year or month, the maximum number of possible calendar weeks
    #in any give month is six. Therefore, this method will return the dates, in
    #order, of any calendar week within a month where '1' is the first week and
    #'6' is the last possible week. If the week is not a valid week for that
    #month, then a null value is returned.
    my $self = shift;
    my $week = shift;
	return if $week > $self->weeks_in_month;

	my @sunday = $self->_get_sundays;

	#Initialize and localize the array that will return the results.
	my @evaluated_week;

	#The first week is a special week no day of the week except the last
	#day of the week is guaranteed to be a valid date. Therefore we have
	#to find the position in the week for the start of the month.
	my $position = $self->weekday(1);

	if($week == 1) {
		#if the position is equal to '1', then the first of the month is on
		#a sunday and we can proceed as normal, otherwise, we have to muck
		#about with the calculations and return the dates of the previous
		#month for the calendar month preceeding the objects month.
		if($position == 1) {
			my $a;
			for($a = 0; $a <= 6; $a++) {
				#Please see this methods outer 'else' conditional for notes
				#on what we are doing in this for-loop. No test for being
				#over the number of days for the month is required as this
				#is the first calendar week in the month.
				my $this_day = 1 + $a;
				push(@evaluated_week, $this_day);
			}
		} else {
			#Since the first weeks sunday is not on the first calenday day of the week
			#we have to determine what that first days date would be for the previous
			#month that shows up in this months first calendar week. The formula for
			# this is the date of the day of the month that is $a numbers subtracted
			#from the maximum number of days in the month.
			my $dipm = $self->days_in_previous_month;
			my $a;
			for($a = ($position - 2); $a >= 0; $a--) {
				push(@evaluated_week, $dipm - $a);
			}

			#Now that we have determined the dates for the portion of the week prior
			#to the first of the month, we will determine the dates for the days of
			#the calendar week that follow the first day of the month.
			my $day = 1;
			for($a = $position; $a <= DAYS_IN_A_WEEK; $a++) {
				push(@evaluated_week, $day);
				$day++;
			}
		}
	} else {
		#We are not in the first week, therefore everything can go along tickety-boo
		#until we reach the final calendar week for the month.
		#Since we are accepting a real number as the argument but the first sunday
		#dates are stored as an array, we have to decrement the real number to match
		#the position in the array of sundays.

		if($position == 1) {
			#1st on a Sunday
			$week -= 1;
		} else {
			#1st NOT on a Sunday
			$week -= 2;
		}

		#Now, step through seven days and build the array.
		my $a;
		my $next_month_day = 0;
		for($a = 0; $a <= 6; $a++) {
			#Date of the first day of the calendar week plus the day of the position
			#in the week (minus one cause were in an array).
			my $this_day = $sunday[$week] + $a;

			#If this day of the calendar week has a date that is greater than the
			#number of days in the month, then we will instead add in the date of
			#that calendar week position for the following month. The program calling
			#this will have to test the output based on previous output if it wants
			#to make any colouring differences based on the date of that day in the
			#calendar week.
			if($this_day > $self->days_in_month) {
				$this_day = ++$next_month_day;
			}
			push(@evaluated_week, $this_day);
		}
	}
	return(@evaluated_week);
}

sub ordinal {
    my ($self, $dom) = @_;
    return 'th' if $dom =~ /11$|12$|13$/;   # special case teens
    return 'st' if $dom % 10 == 1;
    return 'nd' if $dom % 10 == 2;
    return 'rd' if $dom % 10 == 3;
    return 'th';
}

sub sse_from_ymd {
	my ($self, $y, $m, $d) = @_;
	return unless $y && $m && $d;
	return timegm(0, 0, 0, $d, $m - 1, $y - 1900);
}

sub _first_sunday {
	# NOTE: This module uses 1-based weekdays (Sunday = 1, Monday = 2, …, Saturday = 7)
	# instead of the more common 0-based system (Sunday = 0). 
	# This was originally done to simplify the calculations in week_definition, 
	# which constructs calendar weeks including spillover from previous/next months.
    my $self = shift;
    #return $self->{firstsunday} if exists $self->{firstsunday};
    my $pos = $self->weekday(1);
    $self->{firstsunday} = ($pos == 1 ? 1 : 9 - $pos);
    return $self->{firstsunday};
}

sub _get_sundays {
    my $self = shift;
    my $fs = $self->_first_sunday;
    my $dim = $self->days_in_month;
    my @sundays;
    push @sundays, $fs + DAYS_IN_A_WEEK * $_ for 0..5;
    @sundays = grep { $_ <= $dim } @sundays;
    return @sundays;
}

1;


__END__


=head1 NAME

Vigil::Calendar - Provides a way to describe a calendar _month so that you can easily build HTML calendars or populate your flavour of web calendar.

=head1 SYNOPSIS

=over 4

Here's how you might render a calendar _month using the module:

    my ($CURRENT_month, $CURRENT_DAY_OF_month) = do { my @t = localtime; ($t[4] + 1, $t[3]) };
	
    #Create the calendar object
    my $calendar = new MongerCalendar($year, $month);

    #Now that we know what we are looking at, establish the fore and next _months links
    $previous_month_link = "$ScriptURL?_year=$calendar->{_previous_month_year}&_month=$calendar->{_previous_month_number}";
    $next_month_link     = "$ScriptURL?_year=$calendar->{_next_month_year}&_month=$calendar->{_next_month_number}";

    print qq~
    <table border="1" width="100%">
      <thead>
      <tr>
        <td colspan="7" style="text-align:center;">
          <span style="font-weight: bold;">~, $calendar->_month_name, qq~, $year</span><br>
          <a href="$previous_month_link">&lt;&lt; Previous _month</a>
          &nbsp;&nbsp;&nbsp;
          <a href="$next_month_link">Next _month &gt;&gt;</a>
        </td>
      </tr>
      <tr>
        <th>Sun</th>
        <th>Mon</th>
        <th>Tue</th>
        <th>Wed</th>
        <th>Thu</th>
        <th>Fri</th>
        <th>Sat</th>
      </tr>
      </thead>
      <tbody>
    ~;
    for(my $a = 1; $a <= $calendar->weeks_in_month; $a++) {
        my $bgcolor = ($a % 2 == 1) ? "#F5F5F5" : "#DCDCDC";
        print qq~<tr style="height:40px;">~;
        my @weekdays = $calendar->week_definition($a);
        for(my $weekday = 0; $weekday <= 6; $weekday++) {
            if(($a == 1) && ($weekdays[$weekday] > $weekdays[$#weekdays])) {
                $bgcolor = "#C0C0C0";
            }
            elsif(($a == $calendar->weeks_in_month) && ($weekdays[$weekday] < $weekdays[0])) {
                $bgcolor = "#C0C0C0";
            }
            print qq~
    <td style="background-color: $bgcolor; vertical-align: top; font-weight: bold;">
            ~;
            if(($weekdays[$weekday] == $CURRENT_DAY_OF_month) && ($month == $CURRENT_month)) {
                print qq~<span style="color:#ff0000;">$weekdays[$weekday]</span>~;
            } else {
                print $weekdays[$weekday];
            }
            print qq~
    </td>
            ~;
        }
        print qq~
       </tr>
        ~;
    }
    print qq~
      </tbody>
    </table>
    ~;

=back

=head1 DESCRIPTION

This module is based upon a calendar week. Look at your calendar hanging on the wall.
Look at any row of seven days across, where the first day in the row is Sunday. That
is a calendar week. Here is a visual reference:

Definition of a Calendar Week:

	------------------------------------------------------------------------
	| Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|    1   |    2   |    3    |      4    |     5    |    6   |     7    |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------

The basis of most functions in this module is the date, which consists of a _year, a _month
and a day of the _month. In most of the methods in this module, all calcualations are based
upon a mathematical equation of constants which will always return the day of the week
from a given date. The constants must change slightly for each century, however, this
script is written to support any date between January 1st, 1800 and December 31st, 2099.
It is also important to note that this module also allows for leap _years in all it's
calculations.

You can use this module to populate HTML calendars (both calendar weeks and full _months).
The ZIP file that this module was distributed in contains two small scripts that demonstrate
how this is done. Note that the montly.cgi will also print out a table showing the evaluation
of the object plus what is contained in the original object creation variables.

Additionally, this script will provide lots of useful information about _months and _years.
As you read on about the various methods you will see how much information you can extract
from a simple date.

=head2 CLASS METHODS

=over 4

=item my $calendar = Vigil::Calendar->new($year, $month);

The year and month are optional. If you do not provide them, the object will default to the current year and month UTC.

=back

=head2 OBJECT METHODS

=over 4

=item my @information = $obj->evaluate;

Having created the object, calling the evaluate method will return a list of
values particular to the year and month of the object. Here are the values
returned by this method:

$information[0] contains the name of the month

$information[1] contains the number of days in the previous calendar month

$information[2] contains the number of days in the month referenced by this object

$information[3] contains the number of days in the month following the objects month

$information[4] returns '1' if the object year is a leap year, otherwise returns '0'

$information[5] contains the name of the day (Sunday, Monday, etc.) of the first day of the objects month
		
$information[6] contains the name of the day of the last day of the month

$information[7] returns the number of sundays in the objects month


=item $obj->is_a_leap_year;

	  my $truth = $obj->is_a_leap_year;

--or--

	  if($obj->is_a_leap_year) {
		....do stuff here....
	  }

This method returns a '1' or '0' (true or false) if the current objects year is a leap year.

=item my $value = $obj->dayname($day_of_month, BOOLEAN);

	my $name_of_day       = $obj->dayname($dayof_month);
	my $short_name_of_day = $obj->dayname($dayof_month, 1);

This method will return the actual name of the day for any day of the current
objects month. There are three arguments to be passed but only one is
required. The first argument MUST be a day of the month (number from 1-31 depending
on the month). The method does not test for the day of the month so make sure
you pass it. The dayname that is returned will be in the long format (i.e.:
Sunday, Wednesday, etc.).

If you would like to get the name of the day in it's three character abbreviated
format, then pass a true value as the second argument.

=item my $position = $obj->weekday($day_of_month);

This method accepts a day of the month for the current objects year and month and
returns that days position within a calendar week. For example, if the current
objects year was 2001 and the month was 4 (April), then passing this method the
day of month 26 would return a value of 5 since the 26th of April, 2001 is a
Thursday which is the fifth day of the calendar week. Here is the list of values
returned for each day of the calendar week:

	Sunday	=> 1		Wednesday => 4		Saturday => 7
	Monday	=> 2		Thursday  => 5
	Tuesday => 3		Friday	  => 6

=item my $value = $obj->calendar_week($day_of_month);

This method accepts a day of month as an argument for the current objects year and
month and then returns which calendar week that day is in. For example, if we look
at April for 2001, there are five calendar weeks:

	------------------------------------------------------------------------
	| Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|    1   |    2   |     3   |      4    |     5    |    6   |     7    |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|    8   |    9   |    10   |     11    |     12   |    13  |     14   |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|   15   |    16  |    17   |     18    |     19   |    20  |     21   |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|    22  |   23   |    24   |     25    |     26   |    27  |     28   |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------
	|        |        |         |           |          |        |          |
	|    29  |   30   |         |           |          |        |          |
	|        |        |         |           |          |        |          |
	------------------------------------------------------------------------

If you flip through your calendar, you will see that the maximum possible
number of calendar weeks in any given _month is six.

With the calendar above:

$obj->calendar_week(20)  would return a value of '3' since the 20th is in the third calendar week of the month.

$obj->calendar_week(30) would return 5, $obj->calendar week(4) would return 1, etc.

=item my $value = $obj->_month_name;

	my $name = $obj->_month_name;
	my $name = $obj->_month_name(4);

This method will return the name of the current objects month if called without
any arguments. Otherwise, passing the method an argument that is a digit between
'1' and '12', the method will return the name of that month.

=item my $value = $obj->_month_number;

	my $number = $obj->_month_number;
	my $number = $obj->_month_number('Apr');
	my $number = $obj->_month_number('April');
	my $number = $obj->_month_number($month_name);

This method takes the name of a month in letters, and returns the number of that
month (between '1' and '12'). The method will even take a three letter
abbreviation for the month. Without an argument it 	returns the number of the month
in the object.

=item my $value = $obj->weeks_in_month;

This method will return the number of calendar weeks in the current objects year and month.

=item my $value = $obj->days_in_month;

This method returns the number of days in the current objects year and month.

=item my $value = $obj->days_in_previous_month;

This method returns the number of days in the _month prior to the current objects month.

=item my $value = $obj->days_in_next_month;

This method returns the number of days in the month following the current objects month.

=item my @week_dates = $obj->week_definition($calendar_week);

Sample call;
my @week_dates = $obj->week_definition($calendar_week);
my @week_dates = $obj->week_definition(3);

This method requires one argument and that is the number of a calendar week
within the current objects year and month. This value can only be between
'1' and '6'. Note, if you supply a number higher than six, the method will
return a null value. If you supply zero or a number less than zero, the method
will return some very interesting results, none of which will be accurate.

For example, if you created an object for April, 2030 then passed this method
the number for the third calendar week:   $obj->week_definition(3);
Then here is the list that would be returned:

	(14, 15, 16, 17, 18, 19, 20)

=item my $year = $obj->year;

This will always contain the year that was specified when the object
was created.

=item my $month = $obj->month;

This will always contain the month that was specified when the object
was created.

=item my $prev_month = $obj->previous_month_number;

This will always contain the number of the month previous to the objects
current month.

=item my $prev_month_year = $obj->previous_month_year;

If the previous months number is 12, that means you went back a year. So
instead of forcing you to calculate it, this has been done for you and
placed in the above variable.

=item my $next_month = $obj->next_month_number;

Op. Cit. but the other direction.

=item my $next_month_year = $obj->next_month_year;

Op. Cit. but the other direction.

=back

=head2 Local Installation

If your host does not allow you to install from CPAN, then you can install this module locally two ways:

=over 4

=item * Same Directory

In the same directory as your script, create a subdirectory called "Vigil". Then add these two lines, in this order, to your script:

	use lib '.';           # Add current directory to @INC
	use Vigil::Calendar;      # Now Perl can find the module in the same dir
	
	#Then call it as normal:
	my $calendar = Vigil::Calendar->new;

=item * In a different directory

First, create a subdirectory called "Vigil" then add it to C<@INC> array through a C<BEGIN{}> block in your script:

	#!/usr/bin/perl
	BEGIN {
	    push(@INC, '/path/on/server/to/Vigil');
	}
	
	use Vigil::Calendar;
	
	#Then call it as normal:
	my $loop = Vigil::Calendar->new;

=back

=head1 AUTHOR

Jim Melanson (jmelanson1965@gmail.com).

Created March, 2001.

Last Updated August, 2025.

=head1 LICENSE

This module is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut
