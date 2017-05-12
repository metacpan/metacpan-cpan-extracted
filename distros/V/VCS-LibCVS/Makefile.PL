#!/usr/bin/perl
#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

use strict;
use ExtUtils::MakeMaker;

WriteMakefile( ABSTRACT_FROM => "VCS/LibCVS.pm",
               AUTHOR => 'Alexander Taler <dissent@cpan.org>',
               NAME => "VCS::LibCVS",
               VERSION_FROM => "VCS/LibCVS.pm",
               EXE_FILES => [ "examples/lcvs-logsummary",
                              "examples/lcvs-st",
                              "examples/lcvs-tagbase",
                              "examples/lcvs-version" ],
               depend => { Makefile => '$(VERSION_FROM)' },
               dist => { DIST_DEFAULT => 'MANIFEST permissions tardist' },
             );

sub MY::postamble {
  '
.FORCE:

MANIFEST: .FORCE
	find . -type f \
		-and \! -path \'*/CVS/*\' \
		-and \! -name \'.cvsignore\' \
		-and \! -name Makefile | sed s#^./## > MANIFEST

# I don\'t have access to the repository to fix the permissions on these files
executables = Makefile.PL examples/Makefile.PL VCS/Makefile.PL \
              examples/lcvs-example examples/lcvs-st examples/lcvs-version \
              examples/lcvs-logsummary examples/lcvs-get \
              examples/t/lcvs-st.t examples/t/lcvs-st.t-setup.sh

permissions: .FORCE
	chmod +x $(executables)

# An official distribution includes a ChangeLog generated from CVS.
official: ChangeLog dist .FORCE

# Make a ChangeLog with the differences from this release to the previous.
ChangeLog: .FORCE
	# Generate the ChangeLog in Perl.  Sorry, comments can\'t be embedded
	# since it\'s all on one line :(.
	cat VCS/LibCVS.pm | perl -e \'           \
		while (<>) {                         \
			if (m/^\$$VERSION = (\d)\.(\d\d)(\d\d)_0;$$/) { \
				$$major = $$1; $$minor = $$2; $$rel = $$3; \
				if ($$rel == 0) { \
					print "\n*** No predecessor to release $$release\n\n"; \
					exit(1);\
				} \
				$$rel_tag = "Release-$$major-$$minor-$$rel"; \
				$$pre = $$rel - 1; $$pre = "0$$pre" if ($$pre < 10); \
				$$pre_tag = "Release-$$major-$$minor-$$pre"; \
				system "./examples/lcvs-logsummary \
					-t $$pre_tag -t $$rel_tag \
					libcvs-perl > ChangeLog-$$major-$$minor-$$rel"; \
				exit(0); \
			}    \
		} \
		print "\n*** Version not found in VCS/LibCVS.pm\n\n"; \
		exit(1);\
	\'                        \


';
}
