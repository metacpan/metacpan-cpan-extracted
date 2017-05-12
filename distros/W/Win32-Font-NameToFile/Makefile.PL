# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#

require 5.006;
use strict;
use ExtUtils::MakeMaker;

die "
#######################################
#	You are attempting to install this
#   Win32 module on a non-Win32 platform.
#######################################
"
	unless ($^O eq 'MSWin32');

print "\nConfiguring Win32::Font::NameToFile ...\n";

my %prereq;

my %opts = (
    'NAME'	=> 'Win32::Font::NameToFile',
    'VERSION_FROM' => 'lib/Win32/Font/NameToFile.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Dean Arnold, Presicient Corp. (darnold@presicient.com)';
    $opts{'ABSTRACT'} = 'Win32 TrueType Font filename locator';
    $opts{'PREREQ_PM'} = \%prereq;
}

print "\nMissing modules are available from CPAN (search.cpan.org)\n\n"
	 unless CheckModule('Win32::TieRegistry');

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereq{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}

