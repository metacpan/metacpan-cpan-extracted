#! /usr/local/bin/perl -w
# vim: tabstop=4

use strict;

# Include our little library.
use SimpleCal;

# For setlocale.
use POSIX qw (setlocale);
use Locale::Messages qw (LC_MESSAGES);

# Our script contains translatable messages.  We have to assign
# it a text domain.  Note that this is only needed here because the 
# script *itself* contains translatable messages from the text domain
# "com.cantanea.simplecal".
use Locale::TextDomain ('com.cantanea.simplecal');

use vars qw ($VERSION);
$VERSION = '1.0';

# Set the locale according to the environment.
setlocale (LC_MESSAGES, "");

# Print a greeting message.  We want to be flexible with the package
# name, and so we will make this a placeholder.
my $package_name = "SimpleCal";
#print __x("Welcome to {package}!\n", package => $package_name);

# Inquire current date and time.
my @now = localtime;
my $year = $now[5] + 1900; # Current year.
my $month = $now[4];    # Current month in the range of 0-11.

# Print the header for our calendar.
my $month_name = SimpleCal::month_name ($month);
print "\t$month_name $year\n";

# And now print the abbreviation for every day of the week.
foreach my $i (0 .. 6) {
	# This makes the (insecure!) assumption that the abbreviated
	# week day is no longer than 5 characters.
	printf "%6s", abbr_week_day ($i);
}
# And a final newline.
print "\n";

# The rest of the program only prints out the day numbers and is not
# particularly interesting.

# We will start at a Sunday where month day <= 0 and suppress negative dates 
# later.
my $first_day = $now[3] - $now[6];
if ($first_day > 0) {
	$first_day %= 7;
	$first_day -= 7;
}

my $last_day;
if ($month == 1) {
	if (SimpleCal::is_leap_year ($year)) {
		$last_day = 29;
	} else {
		$last_day = 28;
	}
} elsif ($month == 3 || $month == 5 || $month == 8 || $month == 10) {
	$last_day = 30;
} else {
	$last_day = 31;
}

my $day_of_week = 0; # Sunday.
foreach my $mday ($first_day .. $last_day) {
	if ($mday <= 0) {
		printf "%6s", ' ';
	} else {
		printf "% 6d", $mday;
	}
	++$day_of_week;
	if ($day_of_week == 7) {
		$day_of_week = 0;
		print "\n";
	}
}

print "\n" if $day_of_week;

# Say good bye.
# TRANSLATORS: This may be a colloquial way of saying good bye to the user.
#print __"Bye.\n";

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
