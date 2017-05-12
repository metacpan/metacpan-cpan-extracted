#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 8;

use Locale::Messages qw (bindtextdomain textdomain gettext);
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

my $textdomain = 'existing';
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

my $bound_dir = bindtextdomain $textdomain => $locale_dir;

ok defined $bound_dir;
ok (File::Spec->catdir ($bound_dir), File::Spec->catdir ($bound_dir));

my $bound_domain = textdomain $textdomain;

ok defined $bound_domain;
ok $bound_domain, $textdomain;

# Default case.
skip $missing_locale, gettext ('December'), 'Dezember';

# msgid eq msgstr.
ok gettext ('September'), 'September';

# Unknown.
ok gettext ('Not translated'), 'Not translated';

# Special translation for Austrian German.
skip $missing_locale, gettext ('January'), 'Jänner';

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
