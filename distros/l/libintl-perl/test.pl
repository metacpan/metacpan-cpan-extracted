#! /usr/local/bin/perl -w

# vim: tabstop=4

# Portable character conversion for Perl.
# Copyright (C) 2002-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This is a safe wrapper for systems that lack a POSIX shell or have
# a too low limit on the length of the command line.

use strict;
use File::Basename;
use Test::Harness;
use File::Spec;

sub test_harness;

my $here = dirname ($0);
my $test_dir = $here . '/tests';
my @lib_dirs = ($here . '/blib/lib', $here . '/blib/arch');
local *DIR;
opendir DIR, $test_dir or die "cannot open test directory '$test_dir': $!";
@ARGV = sort map $test_dir . '/' . $_, grep /\.t$/, readdir DIR;
closedir DIR;

eval {
	require Encode;
};

unless ($@) {
    print "# Encode revision used is $Encode::VERSION.\n";
}

test_harness ($ENV{TEST_HARNESS} || 0, @lib_dirs);

sub test_harness
{
    $Test::Harness::verbose = shift;
	
    local @INC = @INC;
    unshift @INC, map { File::Spec->rel2abs($_) } @_;
	my $name = $0;
	$name =~ s,test\.pl$,xs_disabled,;
	local *HANDLE;
	open HANDLE, "<$name" or die "cannot open '$name': $!";
	my $xs_disabled = <HANDLE>;
	close HANDLE;

        eval {
                require POSIX;
                POSIX::setlocale(POSIX::LC_ALL());
        };
        my $has_locales = !$@;
        if (!$has_locales) {
                $xs_disabled = 1;
                print <<EOF;
The translation features of libintl-perl cannot be tested on your system
because it lacks locale support.
EOF
        }

        if (!$xs_disabled && !$ENV{TEST_LIBINTL_PERL_XS_VERSION}) {
                $xs_disabled = 1;
                print <<EOF;
The XS version of libintl-perl will normally not be tested extensively
because it depends on local configurations not under control of the module 
installation.  You can enable them by setting the environment variable
"TEST_LIBINTL_PERL_XS_VERSION" to a Perl truth variable.
EOF
        }

	if (!$xs_disabled && $has_locales) {
		# It is pointless to test the XS extension, if no German
		# locales are installed on the system.  The results
		# vary in almost arbitrary ways.
		# FIXME: Do not rely on the de, resp. de_AT locales only.
		#        We can simply try other combinations (fr_CA,
		#        en_GB, pt_BR, and so on), since the actual
		#        translations are not meaningful in our case.
		#        We could therefore just test here for certain
		#        combinations, and then create the mo files on
		#        the fly by copying.
		require POSIX;
		require Locale::Messages;
		Locale::Messages::nl_putenv ("LANGUAGE=de_AT");
		Locale::Messages::nl_putenv ("LC_ALL=de_AT");
		Locale::Messages::nl_putenv ("LANG=de_AT");
		Locale::Messages::nl_putenv ("LC_MESSAGES=de_AT");
		Locale::Messages::nl_putenv ("OUTPUT_CHARSET=iso-8859-1");

		my $has_de_locale = POSIX::setlocale (POSIX::LC_ALL() => '');
		unless ($has_de_locale) {
			require Locale::Util;

			$has_de_locale = 
				Locale::Util::set_locale (POSIX::LC_ALL(), 
				                          'de');
			undef $has_de_locale
				unless ($has_de_locale 
				        && $has_de_locale =~ /(?:germany|de)/i);
		}
		unless ($has_de_locale) {
			$xs_disabled = 1;
			print <<EOF;
The translation features of libintl-perl cannot be tested on your
system because the locale definitions for German do not exist.
EOF
		}
		$xs_disabled = !$has_de_locale;
	}

        if (!$has_locales) {
		Test::Harness::runtests (grep { ! /0[34][a-z_]+_(?:pp|xs)\.t$/ } sort 
			{lc $a cmp lc $b } @ARGV);
        } elsif ($xs_disabled) {
		Test::Harness::runtests (grep { ! /0[34][a-z_]+_xs\.t$/ } sort 
			{lc $a cmp lc $b } @ARGV);
	} else {
		Test::Harness::runtests (sort {lc $a cmp lc $b } @ARGV);
	}
}

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

