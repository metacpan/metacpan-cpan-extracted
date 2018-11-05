#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 2;

use Locale::Messages;
use POSIX;

BEGIN {
	plan tests => NUM_TESTS;
}

# Jan Kratochvil described the following bug: When using any functions
# from Locale::TextDomain with a locale setting for a language that
# has no message catalog installed, __find_domain() from Locale::TextDomain
# will never look into the directories "LocaleData" again.  It
# tries to bindtextdomain() to all search directories, and when it
# fails to find a translation for the emtpy string (should always be
# present), it will assume that this directory is not the one holding
# the mo files.
#
# This can actually only happen, when you switch languages behind the
# user's back. Fixed by checking for the presence of _any_ (g)mo file
# in the relevant directories. 
BEGIN {
	# Force language that is not supported.
	Locale::Messages::nl_putenv ("LANGUAGE=en_US");
	Locale::Messages::nl_putenv ("LC_ALL=en_US");
	Locale::Messages::nl_putenv ("LANG=en_US");
	Locale::Messages::nl_putenv ("LC_MESSAGES=en_US");
	Locale::Messages::nl_putenv ("OUTPUT_CHARSET=iso-8859-1");

	Locale::Messages::setlocale (POSIX::LC_ALL() => '');
    Locale::Messages->select_package ('gettext_pp');
}

# Make sure that LocaleData/ can befound.
BEGIN {
    unshift @INC, $1 if $0 =~ m#(.*)[\\\/]#;
}
use Locale::TextDomain ('existing');

ok "February" eq __"February";

Locale::Messages::nl_putenv ("LANGUAGE=de_AT");
Locale::Messages::nl_putenv ("LC_ALL=de_AT");
Locale::Messages::nl_putenv ("LANG=de_AT");
Locale::Messages::nl_putenv ("LC_MESSAGES=de_AT");

my $missing_locale = Locale::Messages::setlocale (POSIX::LC_ALL() => '') ?
    '' : 'locale de_AT missing';

my $locale = Locale::Messages::setlocale (POSIX::LC_ALL() => '');
my $translation = Locale::TextDomain::__("February");
skip $missing_locale, "Feber" eq $translation;

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
