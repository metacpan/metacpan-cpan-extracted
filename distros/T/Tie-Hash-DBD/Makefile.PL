#!/usr/bin/perl

# Copyright 2010-2021 H.Merijn Brand

require 5.008003;
use strict;

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "Tie::Hash::DBD",
    DISTNAME     => "Tie-Hash-DBD",
    ABSTRACT     => "Tie a hash to a database",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    LICENSE	 => "perl",
    VERSION_FROM => "lib/Tie/Hash/DBD.pm",
    PREREQ_PM	 => { "Carp"		=> 0,
		      "Test::More"	=> 0.90,
		      "DBI"		=> 1.613,
		      "Storable"	=> 0,
		      },
    macro        => { TARFLAGS => "--format=ustar -c -v -f",
		      },
    );

my $rv = WriteMakefile (%wm);

if ($rv && -s "Makefile") {
    open my $mf, "<", "Makefile" or die "Cannot read Makefile: $!\n";
    my @MF = <$mf>;
    close $mf;
    s/\bPERL_DL_NONLAZY=\d+\s+// for @MF;
    open  $mf, ">", "Makefile"   or die "Cannot modify Makefile: $!\n";
    print $mf @MF;
    close $mf;
    }

1;

package MY;

sub postamble {
    my $make_sep = $^O eq "VMS" ? "," : "";
    my $min_vsn = ($] >= 5.010 && -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover $make_sep test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'leaktest:',
	q{	sandbox/leaktest $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:	doc',
	'	pod-spell-check --aspell --ispell',
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
	'doc docs::		doc/Tie-Hash-DBD.md doc/Tie-Hash-DBD.html doc/Tie-Hash-DBD.man doc/Tie-Array-DBD.md doc/Tie-Array-DBD.html doc/Tie-Array-DBD.man',
	'	-@rm -f pod2html.tmp',
	'doc/Tie-Hash-DBD.md:		lib/Tie/Hash/DBD.pm',
	'	pod2markdown  < $? > $@',
	'doc/Tie-Array-DBD.md:		lib/Tie/Array/DBD.pm',
	'	pod2markdown  < $? > $@',
	'doc/Tie-Hash-DBD.html:		lib/Tie/Hash/DBD.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/Tie-Array-DBD.html:	lib/Tie/Array/DBD.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/Tie-Hash-DBD.3:		lib/Tie/Hash/DBD.pm',
	'	pod2man       < $? > $@',
	'doc/Tie-Array-DBD.3:		lib/Tie/Array/DBD.pm',
	'	pod2man       < $? > $@',
	'doc/Tie-Hash-DBD.man:	doc/Tie-Hash-DBD.3',
	'	nroff -mandoc < $? > $@',
	'doc/Tie-Array-DBD.man:	doc/Tie-Array-DBD.3',
	'	nroff -mandoc < $? > $@',
	'',
	$min_vsn;
    } # postamble
