#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2006-2022 H.Merijn Brand

require 5.008;
use strict;

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "Text::OutputFilter",
    DISTNAME     => "Text-OutputFilter",
    ABSTRACT     => "Filter and modify output",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    LICENSE	 => "perl",
    VERSION_FROM => "OutputFilter.pm",
    PREREQ_PM	 => { "Carp"			=> 0,
		      "Test::More"		=> 0,
		      "Test::NoWarnings"	=> 0,
		      },
    macro        => { TARFLAGS => "--format=ustar -c -v -f",
		      },
    );

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble {
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e"
		    "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"
		    $(TEST_FILES) 3>valgrind.log
		    );
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -5 valgrind.log',
	'',
	'leaktest:',
	q{	sandbox/leaktest $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:	doc',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/OutputFilter.md doc/OutputFilter.html doc/OutputFilter.man',
	'	-@rm -f pod2html.tmp',
	'doc/OutputFilter.md:	OutputFilter.pm',
	'	pod2markdown  < $? > $@',
	'doc/OutputFilter.html:	OutputFilter.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/OutputFilter.3:	OutputFilter.pm',
	'	pod2man       < $? > $@',
	'doc/OutputFilter.man:	doc/OutputFilter.3',
	'	nroff -mandoc < $? > $@',
	'';
    } # postamble
