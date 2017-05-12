#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 1999-2016 H.Merijn Brand

require 5.006;

use strict;

# Be kind to testers, not verbose
if (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING}) {
    $ENV{DISPLAY} or exit 0;
    }

use ExtUtils::MakeMaker;

my %wm = (
    NAME	  =>   "Tk::Clock",
    DISTNAME	  =>   "Tk-Clock",
    AUTHOR        =>   "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM  =>   "Clock.pm",
    ABSTRACT_FROM =>   "Clock.pm",

    PREREQ_PM	  => { "Tk"			=> "402.000",
		       "Tk::Canvas"		=> 0,
		       "Tk::Derived"		=> 0,
		       "Tk::Widget"		=> 0,
		       "Carp"			=> 0,
		       "Test::More"		=> 0.88,
		       "Test::NoWarnings"	=> 0,
		       "Encode"			=> 0,
		       "POSIX"			=> 0,
		       },

    dist	  => { COMPRESS	=> "gzip -9f",
		       SUFFIX	=> ".gz",
		       },
    macro         => { TARFLAGS => "--format=ustar -c -v -f",
		       },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble
{
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

    my $min_vsn = ($] >= 5.010 && -d "xt" && -d "sandbox" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
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
	'spellcheck:',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'	ls -l */META.yml',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	$min_vsn;
    } # postamble

1;
