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

# Clean environment first.
foreach my $var (keys %ENV) {
    if ('LC_' eq substr $var, 0, 3) {
        Locale::Messages::nl_putenv ("$var");
    }
}

Locale::Messages::nl_putenv ("LANGUAGE=de_AT");
Locale::Messages::nl_putenv ("LC_ALL=de_AT");
Locale::Messages::nl_putenv ("LANG=de_AT");
Locale::Messages::nl_putenv ("LC_MESSAGES=de_AT");
# Actually both de_AT and de are required.  We assume here that
# de will be installed, too, if de_AT is.  This test does not
# use Locale::Util::set_locale() for setting the locale, and 
# that is on purpose.
my $missing_locale = Locale::Messages::setlocale (POSIX::LC_ALL() => '') ?
    '' : 'locale de_AT missing';
Locale::Messages::setlocale (POSIX::LC_ALL() => 'C');

my $locale_dir = $0;
$locale_dir =~ s,[^\\/]+$,, or $locale_dir = '.';
$locale_dir .= '/LocaleData';

my $textdomain = 'existing';
Locale::Messages::nl_putenv ("LANG=whatever");
Locale::Messages::nl_putenv ("LC_ALL=de_DE");
Locale::Messages::nl_putenv ("LC_MESSAGES=whatever");
Locale::Messages::nl_putenv ("LANGUAGE=ab_CD:ef_GH:de_AT:de");
Locale::Messages::nl_putenv ("OUTPUT_CHARSET=iso-8859-1");
Locale::Messages::setlocale (POSIX::LC_ALL(), '');

my $bound_dir = bindtextdomain $textdomain => $locale_dir;

ok defined $bound_dir;
ok (File::Spec->catdir ($bound_dir), File::Spec->catdir ($locale_dir));

my $bound_domain = textdomain $textdomain;

ok defined $bound_domain;
ok $bound_domain, $textdomain;

# Austrian German has precedence.
skip $missing_locale, gettext ('January'), 'Jänner';
my $translation = gettext ('January');

Locale::Messages::nl_putenv ("LANGUAGE=ab_CD:ef_GH:de:de_AT");
skip $missing_locale, gettext ('February'), 'Februar'; # not 'Feber'!

# Check that LC_ALL works.
Locale::Messages::nl_putenv ("LANGUAGE");
Locale::Messages::nl_putenv ("LC_ALL=de_DE.utf-8");
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('February'), 'Februar';

# But LANGUAGE has precedence.
Locale::Messages::nl_putenv ("LANGUAGE=de_AT.utf-8");
Locale::Messages::nl_putenv ("LC_ALL=de_DE.utf-8");
Locale::Messages::setlocale (POSIX::LC_ALL(), '');
skip $missing_locale, gettext ('February'), 'Feber';

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
