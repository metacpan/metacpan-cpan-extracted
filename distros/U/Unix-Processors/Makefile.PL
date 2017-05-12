# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 1998-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
    q{
README: readme.texi
	-$(RM_RF) $@
	makeinfo $< --output $@ --no-headers --no-validate

## Maintainer use:
preexist:
	svnorcvs nexists $(DISTNAME)_$(VERSION_SYM)
	test -s README

tag:
	svnorcvs tag  $(DISTNAME)_$(VERSION_SYM)

maintainer-diff:
	svnorcvs diff $(DISTNAME)_$(VERSION_SYM)

maintainer-dist: preexist dist tag
	svnorcvs release $(DISTVNAME).tar.gz

maintainer-clean: distclean
	-$(RM_RF) README Makefile

dist: distcheck README
};
}

# Check for AIX libraries and headers required to support this package
# System calls: perfstat_cpu_total,
#              /usr/include/libperfstat.h
#              /usr/lib/libperfstat.a

my $ARCH = `uname`;
chomp($ARCH);

my $libs;
my $defs;
my $incs;

if ($ARCH eq "AIX") {
    print "\nChecking for required AIX components...\n";
    my $has_perfstat;
    if (-f "/usr/include/libperfstat.h") {
	print "  - libperfstat.a appears to be installed\n";
	$libs = "-lperfstat";
	$defs = "-DHAS_PERFSTAT";
	$has_perfstat = 1;
    } else {
	print "  - libperfstat.a is not installed\n";
    }
    print "\n";
}

WriteMakefile(
	      NAME => "Unix::Processors",
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT_FROM => 'Processors.pm',
	      VERSION_FROM  => 'Processors.pm',
	      NO_META	=> 1,
	      DISTNAME  => 'Unix-Processors',
	      LIBS      => $libs,
	      DEFINE    => $defs,
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz',
			    DIST_DEFAULT => 'README all tardist',
			},
	      );
