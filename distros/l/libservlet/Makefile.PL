# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME         => 'libservlet',
              VERSION_FROM => 'lib/Servlet.pm',
              PREREQ_PM    => { 'Exception::Class' => 0,
                                'IO::Handle' => 0 },
             );

package MY;

sub MY::postamble {
    q(

POD2HTML=pod2html

doc/api/%.html : lib/%.pm
	@(echo generating $@; \
	slashes=`$(FULLPERL) -e 'print "../" x ((split /\//, $$ARGV[0])-1)' $<`; \
	$(POD2HTML) --htmlroot=$${slashes}api \
	            --css=$${slashes}libservlet.css \
	            --infile=$< \
	            --outfile=$@)

LIBSERVLET_HTML_1=$(subst .pm,.html,$(TO_INST_PM))
LIBSERVLET_HTML=$(subst lib/,doc/api/,$(LIBSERVLET_HTML_1))

html: pm_to_blib $(LIBSERVLET_HTML)
);
}
