
# Vigil::Calendar - A Perl module

The purpose of this module is to provide you with the information you need to create an HTML (or other style) calendar.

This document is going to explain how the module derives it's values (for your edification and trust) and how it may be used.

## Info needed to build a calendar

To build a printed calendar, you need multiple pieces of information:

- The year and month the calendar is for.
- How many physical weeks (rows) are in the calendar.
- How many days are in the month?
- What day of the week does the month start on?

*NOTE: In this module, the first day of the week is always a Sunday. That is the traditional display for printed calendars so that is what was adopted.*

### What day of the week does a particular date fall on?

This is the first piece of information that the module needs to create it's information for a calendar. Fortunately, the 
heavy lifting of this calculation is done by: Tomohiko Sakamoto's Algorithm. In the following illustration $DAY_OF_MONTH, 
$MONTH and $YEAR are your inputs.

    my @offset = (0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4);
    $year -= $MONTH < 3; # Jan & Feb are considered part of previous year
	return (($YEAR + int($YEAR / 4) - int($YEAR / 100) + int($YEAR / 400) + $offset[$MONTH - 1] + $DAY_OF_MONTH) % 7);

This returns a zero-based value representing Sunday .. Saturday. 

*NOTE: In the module, we add 1 to this value as our Sunday .. Saturday list is 1-based.*

### How does it find the first Sunday of the month?

The whole process begins by known the date of the first Sunday of the month.

To calculate this first Sunday of the month (all Sundays of the month), we first need
to figure out which day of the week the 1st day of the month falls on. Using a method
that calculates this from the code above, we will get the day of the week for the
first day of the month.

Now that we know the day of the week that the 1st of the month falls on, we can easily
calculate when the first Sunday is. If the 1st day of the month is a Sunday - voila!
We know that the first Sunday is the 1st day of the month.

Otherwise, we subtract that position (Sunday = 0, Monday = 1, etc) from the number 8.
The result is the date of the first Sunday of the month. How does this work?

If the 1st day of the month is a Monday, then the first Sunday must be the 7th:

	Monday 1st, Tuesday 2nd, Wednesday 3rd, Thursday 4th, Friday 5th, Saturday 6th, Sunday 7th.
	
Therefore, 8 - 1 = 7

If the 1st day of the month were on a Wednesday (4th day, position 3 in a zero-based list), then
we would have 8 - 3 = 5 (Wednesday 1st, Thursday 2nd, Friday 3rd, Saturday 4th, Sunday 5th ...)

### How many physical weeks are there in a calendar?

In saying physical weeks, I mean how many rows are there on the printed calendar. It's an important
distinction for this module.

	28 days in a month
	S   M   T   W   Th  F   S        S   M   T   W   Th  F   S        S   M   T   W   Th  F   S
	1   2   3   4   5   6   7            1   2   3   4   5   6                                1
	8   9   10  11  12  13  14       7   8   9   10  11  12  13       2   3   4   5   6   7   8
	15  16  17  18  19  20  21       14  15  16  17  18  19  20       9   10  11  12  13  14  15
	22  23  24  25  26  27  28       21  22  23  24  25  26  27       16  17  18  19  20  21  22
	                                 28                               23  24  25  26  27  28
    1st on Sunday                    1st not on Sunday                1st on Friday or Saturday
	4 Sundays + 0 offset =           4 Sundays + 1 offset week =      4 Sundays + 1 offset week =
	4 physical weeks                 5 physical weeks                 5 physical weeks
	
	
	29 days in a month
	S   M   T   W   Th  F   S        S   M   T   W   Th  F   S        S   M   T   W   Th  F   S
	1   2   3   4   5   6   7            1   2   3   4   5   6                                1
	8   9   10  11  12  13  14       7   8   9   10  11  12  13       2   3   4   5   6   7   8
	15  16  17  18  19  20  21       14  15  16  17  18  19  20       9   10  11  12  13  14  15
	22  23  24  25  26  27  28       21  22  23  24  25  26  27       16  17  18  19  20  21  22
	29                               28  29                           23  24  25  26  27  28  29
    1st on Sunday                    1st not on Sunday                1st on Saturday
	5 Sundays + 0 offset weeks =     4 Sundays + 1 offset week =      4 Sundays + 1 offset week =
	5 physical weeks                 5 physical weeks                 5 physical weeks
	
	
	30 days in the month
	S   M   T   W   Th  F   S        S   M   T   W   Th  F   S        S   M   T   W   Th  F   S
	1   2   3   4   5   6   7            1   2   3   4   5   6                                1
	8   9   10  11  12  13  14       7   8   9   10  11  12  13       2   3   4   5   6   7   8
	15  16  17  18  19  20  21       14  15  16  17  18  19  20       9   10  11  12  13  14  15
	22  23  24  25  26  27  28       21  22  23  24  25  26  27       16  17  18  19  20  21  22
	29  30                           28  29  30                       23  24  25  26  27  28  29
	                                                                  30
    1st on Sunday                    1st not on Sunday                1st on Saturday
	5 Sundays + 0 offset weeks =     4 Sundays + 1 offset week =      5 Sundays + 1 offset week =
	5 physical weeks                 5 physical weeks                 6 physical weeks
	
	
	31 days in a month
	S   M   T   W   Th  F   S        S   M   T   W   Th  F   S        S   M   T   W   Th  F   S
	1   2   3   4   5   6   7            1   2   3   4   5   6                            *   1
	8   9   10  11  12  13  14       7   8   9   10  11  12  13       2   3   4   5   6   7   8
	15  16  17  18  19  20  21       14  15  16  17  18  19  20       9   10  11  12  13  14  15
	22  23  24  25  26  27  28       21  22  23  24  25  26  27       16  17  18  19  20  21  22
	29  30  31                       28  29  30  31                   23  24  25  26  27  28  29
	                                                                  30  31
    1st on Sunday                    1st not on Sunday                1st on Friday or Saturday
	5 Sundays + 0 offset weeks =     4 Sundays + 1 offset week =      5 Sundays + 1 offset week =
	5 physical weeks                 5 physical weeks                 6 physical weeks

Even though this appears to be complex, it's not. The module just needs to be able to figure out:

- What day of the week is the 1st day of the month.
- How many days there are in the month.

The module has routines for those two calculations, and then it applies them to the following formula:

	physical weeks in month = int( ( $_[0]->days_in_month - ( 8 - $_[0]->weekday(1) ) + 6 ) / 7);

*NOTE: In the module, we add 1 to this value as our Sunday .. Saturday list is 1-based.*

From these simple calculations, the module is able to extrapolate all of the other information needed to
create a printed (HTML) calendar.

## Building a calendar with this module

Your HTML output from your Perl script uses a loop to populate the month. Please understand my HTML here is simple as we are focussing on the code portion.

### Create whatever container you want to hold the calendar.

For this explanation, I'm using a simple HTML table.

First, make sure you load the module then create the object:

```
use strict;
use warnings;
use Vigil::Calendar;

my $calendar = Vigil::Calendar->new($display_year, $display_month);

```

Now start building your HTML calendar:

```
print qq~
<table>
  <thead>
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
```
The body of the calendar is built by looping through the physical weeks of the calendar, and then looping through the weekdays of each physical week.

The number of physical weeks is found in `$calendar->weeks_in_month` and the dates of each weekday for each month is found in `$calendar->week_definition($a)`

With those two pieces of information, you can now loop through the physical weeks and days to build your HTML calendar:

```
for(my $a = 1; $a <= $calendar->weeks_in_month; $a++) {
    print "<tr>\n";
    my @weekdays = $calendar->week_definition($a);
    for(my $weekday = 0; $weekday <= 6; $weekday++) {
        print "<td>$weekdays[$weekday]</td>\n";
    }
    print "</tr>\n";
}
print qq~
  </tbody>
</table>
~;
```

*NOTE: Look in the examples folder for a script called monthly.cgi to see a working example.

### Display the month name and year on the calendar

```print $calendar->month_name, ", $display_year\n";```


### Linking for previous and next month.

In your program, grab the calendar display year and month from your quertystring or form fields. Then I'll show you below how to build the links to move between contiguous months.

We'll assume your code drops the query string year and month into: `$display_year` and `$display_month`

If you pass `undef` values, the module will default to today UTC.

First, instantiate the object with the supplied year and month:

```my $calendar = Vigil::Calendar->new($YEAR, $MONTH);```

Now build the previous months link:

```
my $previous_month_link = "$ScriptURL?year=" . 
                           $calendar->previous_month_year . 
                           "&month=" . 
                           $calendar->previous_month_number;
```

Now build the next months link:

```
my $next_month_link = "$ScriptURL?year=" . 
                       $calendar->next_month_year . 
                       "&month=" . 
                       $calendar->next_month_number;
```

### Identifying weekdays that are NOT in the current displayed month.

Unless you are looking at February in a non-leap year with the 1st on a Sunday, there will be either blank spaces on the calendar or day numbers from the bordering months.

In the loop, you may want to identify those days to either remove the day number or color the cells differently. Here is the loop again, identifying the days that are from the previous month or following month.

```
for(my $a = 1; $a <= $calendar->weeks_in_month; $a++) {
    print "<tr>\n";
    my @weekdays = $calendar->week_definition($a);
    for(my $weekday = 0; $weekday <= 6; $weekday++) {
        if(($a == 1) && ($weekdays[$weekday] > $weekdays[$#weekdays])) {
            #The month previous to the display month. Change colors or remove the date - you decide.
            print "<td>$weekdays[$weekday]</td>\n";
        }
        elsif(($a == $calendar->weeks_in_month) && ($weekdays[$weekday] < $weekdays[0])) {
            #The month following the display month. Whatever...
            print "<td>$weekdays[$weekday]</td>\n";
        } else {
            #Current/Display month
            print "<td>$weekdays[$weekday]</td>\n";
        }
    }
    print "</tr>\n";
}
```

That's all there is to creating your own calendar month. Apply your own HTML and CSS to generate calendars big, small, fancy-shmancy, plain ... you decide. This module gives you everything you need to take the heavy lifting out of it.

If this module helps you out in your project or you just really like it, then drop me a note to say so. I love hearing from people who use my stuff.

Jim Melanson
jmelanson1965@gmail.com












