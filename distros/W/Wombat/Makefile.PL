# -*- Mode: Perl; indent-tabs-mode: nil; -*-

require 5.6.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME         => 'Wombat',
              VERSION_FROM => 'lib/Wombat.pm',
              PREREQ_PM    => {
                               'Digest' => 0,
                               'File::Spec' => 0,
                               'HTTP::Date' => 0,
                               'HTTP::Headers' => 0,
                               'MIME::Base64' => 0,
                               'Servlet' => '0.9.2',
                               'URI' => 0,
                               'URI::Escape' => 0,
                               'XML::Parser::PerlSAX' => 0,
                              },
             );

package MY;

sub MY::test {
    q(
run_tests :
	@echo Tests are currently disabled until I fix the test harness.

test :: pure_all run_tests
);
}
#    q(
#run_tests :
#	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) t/TEST
#
#test :: pure_all run_tests
#);
#}

sub MY::postamble {
    q(

POD2HTML=pod2html

docs/api/%.html : lib/%.pm
	@(echo generating $@; \
	$(MKPATH) `dirname $@`; \
	slashes=`$(FULLPERL) -e 'print "../" x ((split /\//, $$ARGV[0])-1)' $<`; \
	$(POD2HTML) --htmlroot=$${slashes}api \
	            --css=$${slashes}wombat.css \
	            --infile=$< \
	            --outfile=$@)

WOMBAT_HTML_1=$(subst .pm,.html,$(TO_INST_PM))
WOMBAT_HTML=$(subst lib/,docs/api/,$(WOMBAT_HTML_1))

html: pm_to_blib $(WOMBAT_HTML)
);
}
