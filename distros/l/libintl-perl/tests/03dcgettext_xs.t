#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 11;

use Locale::Messages qw (bindtextdomain dcgettext LC_MESSAGES);
require POSIX;
require File::Spec;

BEGIN {
	my $package;
	if ($0 =~ /_pp\.t$/) {
		$package = 'gettext_pp';
	} else {
		$package = 'gettext_xs';
	}
		
	my $selected = Locale::Messages->select_package ($package);
	if ($selected ne $package && 'gettext_xs' eq $package) {
		print "1..0 # Skip: Locale::$package not available here.\n";
		exit 0;
	}
	plan tests => NUM_TESTS;
}

my $locale_dir = $0;
$locale_dir =~ s,[^\\/]+$,, or $locale_dir = '.';
$locale_dir .= '/LocaleData';

Locale::Messages::nl_putenv ("LANGUAGE=de_AT");
Locale::Messages::nl_putenv ("LC_ALL=de_AT");
Locale::Messages::nl_putenv ("LANG=de_AT");
Locale::Messages::nl_putenv ("LC_MESSAGES=de_AT");
Locale::Messages::nl_putenv ("OUTPUT_CHARSET=iso-8859-1");

my $missing_locale = 'locale de_AT missing';
my $setlocale = Locale::Messages::setlocale (POSIX::LC_ALL() => '');
if ($setlocale && $setlocale =~ /(?:austria|at)/i) {
	$missing_locale = '';
} else {
	require Locale::Util;
	
	$setlocale = Locale::Util::set_locale (POSIX::LC_ALL(), 'de', 'AT');
	if ($setlocale && $setlocale =~ /(?:austria|at)/i) {
		$missing_locale = '';
	}
}

my $bound_dir = bindtextdomain existing => $locale_dir;
ok defined $bound_dir;
ok (File::Spec->catdir ($bound_dir), File::Spec->catdir ($locale_dir));

$bound_dir = bindtextdomain additional => $locale_dir;
ok defined $bound_dir;
ok (File::Spec->catdir ($bound_dir), File::Spec->catdir ($locale_dir));

skip $missing_locale, 'Dezember', dcgettext (existing => 'December', LC_MESSAGES);
ok 'September', dcgettext (existing => 'September', LC_MESSAGES);
ok 'Not translated', dcgettext (existing => 'Not translated', LC_MESSAGES);
skip $missing_locale, 'Jänner', dcgettext (existing => 'January', LC_MESSAGES);

skip $missing_locale, 'Montag', dcgettext (additional => 'Monday', LC_MESSAGES);
ok 'Not translated', dcgettext (additional => 'Not translated', LC_MESSAGES);
skip $missing_locale, 
	dcgettext (additional => 'Saturday', LC_MESSAGES), 'Sonnabend';

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
