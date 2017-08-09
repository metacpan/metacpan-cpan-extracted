#!/usr/bin/env perl
# $Id: config.pl,v 1.38 2016/09/12 20:33:41 pfeiffer Exp $
#
# Configure this package.
#

package Mpp;

#
# First make sure this version of Perl is recent enough:
#
BEGIN { eval { require 5.008 } or warn <<EOS and exit 1 } # avoid BEGIN/die diagnostic
I need Perl version 5.8 or newer.  If you have it installed somewhere
already, run this installation procedure with that perl binary, e.g.:

	perl5.16.3 install.pl ...

If you don't have a recent version of Perl installed (what kind of system are
you on?), get the latest from www.perl.org and install it.
EOS

BEGIN {
#
# Find the location of our data directory that contains the auxiliary files.
# This is normally built into the program by install.pl, but if makepp hasn't
# been installed, then we look in the directory we were run from.
#
  my $datadir = $0;		# Assume it's running from the same place that
				# we're running from.
  unless ($datadir =~ s@/[^/]+$@@) { # No path specified?
				# See if we can find ourselves in the path.
    foreach( split(/:/, $ENV{'PATH'}), '.' ) {
				# Add '.' to the path in case the user is
				# running it with "perl config.pl" even if
				# . is not in his path.
      if( -d "$_/Mpp" ) {	# Found something we need?
	$datadir = $_;
	last;
      }
    }
  }
  $datadir or die "config.pl: can't find library files\n";

  $datadir = eval "use Cwd; cwd . '/$datadir'"
    if $datadir =~ /^\./;	# Make it absolute, if it's a relative path.
  unshift @INC, $datadir;
}

use strict;
use Mpp::Utils;
use Mpp::File ();		# ensure HOME is set

print 'Using perl in ' . PERL . ".\n";
print "If you want another, please set environment variable PERL to it & reconfigure.\n"
  unless $ENV{PERL};

#
# Parse the arguments:
#
my $prefix;
my $findbin = 'none';
my $makefile = '.';
my( $bindir, $datadir, $mandir, $htmldir );

$Mpp::Text::pod = 'makepp_faq';	# for help

Mpp::Text::getopts
  [qw(p prefix), \$prefix, 1],
  [qw(b bindir), \$bindir, 1],
  [qw(h htmldir), \$htmldir, 1],
  [qw(m mandir), \$mandir, 1],
  [qw(d datadir), \$datadir, 1],
  [qw(f findbin), \$findbin, 1],
  [undef, 'makefile', \$makefile, 1],
  splice @Mpp::Text::common_opts;


$makefile .= '/Makefile' if -d $makefile;
if( !$bindir ) {
  $prefix ||= '/usr/local';
  $bindir = "$prefix/bin";
} elsif( !$prefix ) {
  $bindir =~ m@^(.*)/bin@ and $prefix = $1;
  $prefix ||= '/usr/local';
}
$datadir ||= "$prefix/share/makepp";
$htmldir ||= do { my $d = "$prefix/share/doc"; -d $d ? "$d/makepp" : "$datadir/html" };
$mandir ||= do { my $d = "$prefix/share/man"; -d $d ? $d : "$prefix/man" };

foreach ($bindir, $datadir, $htmldir) {
  s@~/@$ENV{HOME}/@;
}

#
# Write out a makefile for this.  This makefile ought to work with any version
# of bozo make, so it has to be extremely generic.
#
open MAKEFILE, '>', $makefile or die "$0: can't write $makefile--$!\n";
my $perl = PERL;

s/\$/\$\$/g for $perl, $bindir, $datadir, $findbin, $mandir, $htmldir;
$Mpp::Text::VERSION =~ s/:.*//;

print MAKEFILE "PERL = $perl
BINDIR = $bindir
DATADIR = $datadir
FINDBIN = $findbin
MANDIR = $mandir
HTMLDIR = $htmldir
VERSION = makepp-$Mpp::Text::VERSION
PASS_PERL =",
(Mpp::is_windows < 1 ? ' PERL=$(PERL)' : ''), # unknown syntax, not needed, coz we generate a .bat
q[

FILES = makepp makeppbuiltin makeppclean makeppgraph makeppinfo makepplog makeppreplay makepp_build_cache_control recursive_makepp \
	*.pm Mpp/*.pm \
	Mpp/BuildCheck/*.pm Mpp/CommandParser/*.pm Mpp/Fixer/*.pm Mpp/Scanner/*.pm Mpp/Signature/*.pm \
	*.mk

all:
	@echo 'No need to build anything.  Useful targets are: test or testall and install'

check: $(FILES)
	@echo ok

test: .test_done

.test_done: $(FILES) t/*.test t/run_all.t t/run_tests.pl
	cd t && $(PASS_PERL) $(PERL) run_all.t *.test
	@touch $@

testall: .testall_done

.testall_done: .test_done t/*/*.test
	cd t && $(PASS_PERL) $(PERL) run_all.t */*.test
	@touch $@

distribution: $(VERSION).tar.gz

$(VERSION).tar.gz: README INSTALL LICENSE ChangeLog \
	pod/*.pod $(FILES) \
	t/*.test t/*/*.test t/run_all.t t/run_tests.pl \
	config.pl configure configure.bat install.pl
	rm -rf $(VERSION)
	./configure         # Reset Makefile.
	mkdir $(VERSION) $(VERSION)/pod $(VERSION)/t \
	   $(VERSION)/Mpp $(VERSION)/Mpp/ActionParser $(VERSION)/Mpp/BuildCheck $(VERSION)/Mpp/CommandParser \
	   $(VERSION)/Mpp/Fixer $(VERSION)/Mpp/Scanner $(VERSION)/Mpp/Signature
	for file in $^; do cp $$file $(VERSION)/$$file; done
	GZIP=-9 tar --create --gzip --file $@ $(VERSION)
	cd $(VERSION) && make test    # Make sure it all runs.
	rm -rf $(VERSION)

install:
	$(PASS_PERL) $(PERL) install.pl $(BINDIR) $(DATADIR) $(MANDIR) $(HTMLDIR) $(FINDBIN) $(DESTDIR)

clean:
	rm -rf .test*_done t/*.log t/*.failed t/*.tdir .makepp pod/pod2htm?.tmp

distclean: clean
	rm -f Makefile

.PHONY: all check distribution install test testall clean distclean
];

__DATA__
[option]
       configure [option]
