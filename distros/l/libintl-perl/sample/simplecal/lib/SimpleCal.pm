#! /bin/false
# vim: tabstop=4

package SimpleCal;

use strict;

# The text domain (identifier) of our package is 'com.cantanea.simplecal',
# following the advice in the pod of Locale::TextDomain.
use Locale::TextDomain qw (com.cantanea.simplecal);

use base qw (Exporter);
use vars qw (@EXPORT);

@EXPORT = qw (month_name abbr_week_day is_leap_year);

sub month_name ($)
{
	my $month = shift;
	$month = 0 unless $month;
	$month %= 12;

	# This is of course stupid but explains things best.  See the
	# function abbr_week_day() for a smarter approach.
	if ($month == 0) {
		return __"January";
	} elsif  ($month == 1) {
		return __"February";
	} elsif  ($month == 2) {
		return __"March";
	} elsif  ($month == 3) {
		return __"April";
	} elsif  ($month == 4) {
		return __"May";
	} elsif  ($month == 5) {
		return __"June";
	} elsif  ($month == 6) {
		return __"July";
	} elsif  ($month == 7) {
		return __"August";
	} elsif  ($month == 8) {
		return __"September";
	} elsif  ($month == 9) {
		return __"October";
	} elsif  ($month == 10) {
		return __"November";
	} else {
		return __"December";
	}
}

# This is smarter.  We initialize an array with the English names first.
# The function N__() is exported by Locale::TextDomain and returns
# its argument unmodified.  Its sole purpose is to mark the string as
# being translatable, so that it will make it into the pot file for
# our package.
#
# It is dangerous to use __() here! Why? Then the array will be translated
# only once, at compile time.  It is very likely that the locale settings
# have not yet been initialized to the user preferences at this point
# of time, and since the array is already created, the translation
# will not produce the correct results.
#
# This should become clearer if you imagine that our library would be
# part of a daemon that is running for days or even years.  The array
# would be initialized with the language that was set at program startup
# and would then never change again, because you actually cache the
# translations.
my @abbr_week_days = (
	N__"Sun",
	N__"Mon",
	N__"Tue",
	N__"Wed",
	N__"Thu",
	N__"Fri",
	N__"Sat",
);

sub abbr_week_day ($)
{
	my $wday = shift;
	$wday = 0 unless $wday;
	$wday %= 7;

	# The argument to __() is simply a string, not necessarily a string
	# constant.  The following line will look up the English name in the
	# array, and then translates that string on the fly into the current
	# user language.
	return __($abbr_week_days[$wday]);
	# This can still be suboptimal because it translates the string again
	# and again.  In situations where you are absolutely sure that the
	# user language will not change again, you may prefer to cache the
	# translations despite of the above hints, especially if you 
	# call the function very many times.  In a library you can usually
	# not be sure whether the user language can change or not and you
	# should avoid that.  The message lookup is quite fast.

	# Instead of the above return directive we could also have written:
	#
	#   return $__{$abbr_week_days[$wday]};
    #
    # resp.
    #
    #   return $__->{$abbr_week_days[$wday]};
    #
    # It is basically a matter of taste whether you prefer the tied
	# hash lookup or the function call.
}

# Check whether the argument is a leap year.
sub is_leap_year
{
	my $year = shift;
	$year = 0 unless $year;

	return 1 if $year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0);

	return;
}

1;

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
