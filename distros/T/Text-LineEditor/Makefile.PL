#!/usr/bin/perl
#
# Last updated by gossamer on Wed Aug 12 20:32:21 EST 1998
#

# Check for modules we need.
$| = 1;
my $missing_modules = 0;

print "Checking for Term::ReadLine ...";
eval {
    require Term::ReadLine;
};
if ($@) {
    print " missing!\n";
    $missing_modules++;
    print "$@\n";
    sleep(2);  # Don't hurry too much
} else {
    print " got it\n";
}

print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN - you'll need them to
complete the installation.  

Visit <URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::LineEditor',
    'VERSION_FROM' => 'LineEditor.pm', # finds $VERSION
    'dist'         => {
                         COMPRESS => 'gzip -9f',
                         SUFFIX => 'gz',
                      },
);

sub MY::postamble {
   package MY;

   '

WEBDIR = /home/gossamer/websrc/docs/code
WEB_FILELIST = $(WEBDIR)/file-list

webdist: dist
	@$(MKPATH) $(WEBDIR)/$(DISTNAME)/
	cp $(DISTVNAME).tar.$(SUFFIX) $(WEBDIR)/$(DISTNAME)/
	cp README $(WEBDIR)/$(DISTNAME)/$(DISTVNAME).README

'
}

