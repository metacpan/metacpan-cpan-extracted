#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 85;

use Locale::Messages qw (nl_putenv bindtextdomain textdomain gettext);
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

# Clean environment first.
foreach my $var (keys %ENV) {
    if ('LC_' eq substr $var, 0, 3) {
        nl_putenv "$var";
    }
}

nl_putenv "LC_ALL=de_DE";
nl_putenv "LC_MESSAGES=de_DE";
my $missing_locale = Locale::Messages::setlocale (POSIX::LC_ALL() => '') ?
    '' : 'locale de_DE missing';
if (!$missing_locale && $0 =~ /_xs\.t$/) {
    $missing_locale = $ENV{GNU_GETTEXT_COMPATIBILITY} ?
         '' : 'compatibility tests not activated';
}
Locale::Messages::setlocale (POSIX::LC_ALL() => 'C');

my $locale_dir = $0;
$locale_dir =~ s,[^\\/]+$,, or $locale_dir = '.';
$locale_dir .= '/LocaleData';

my $textdomain = 'existing';
my $bound_dir = bindtextdomain $textdomain => $locale_dir;

ok defined $bound_dir;
ok (File::Spec->catdir ($bound_dir), File::Spec->catdir ($locale_dir));

my $bound_domain = textdomain $textdomain;

ok defined $bound_domain;
ok $bound_domain, $textdomain;

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=C';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=C';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=C';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=C';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'May';

nl_putenv 'LANGUAGE=de_DE';
nl_putenv 'LANG=de_DE';
nl_putenv 'LC_MESSAGES=de_DE';
nl_putenv 'LC_ALL=de_DE';
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('May'), 'Mai';

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
