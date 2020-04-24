#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2007-2020 H.Merijn Brand

require 5.006;

use ExtUtils::MakeMaker;

sub link_or_copy {
    my ($source, $dest) = @_;

    link ($source, $dest) or copy ($source, $dest);
    } # link_or_copy

my @exe;
unless (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING} == 1) {
    -f "examples/sccs2git" or link_or_copy "examples/sccs2git-r", "examples/sccs2git";
    prompt ("Do you want to install sccs2git ?", "y") =~ m/[Yy]/ and
	push @exe, "examples/sccs2git";
    }

my %wm = (
    NAME	  =>   "VCS::SCCS",
    DISTNAME	  =>   "VCS-SCCS",
    AUTHOR        =>   "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM  =>   "SCCS.pm",
    ABSTRACT_FROM =>   "SCCS.pm",
    EXE_FILES     => [ @exe ],
    PREREQ_PM     => { "Test::More"		=> 0,
		       "Carp"			=> 0,
		       "File::Spec"		=> 0,
		       "POSIX"			=> 0,
		       "Test::NoWarnings"	=> 0,
		       },
#   dist	  => { DIST_DEFAULT => "tgzdist" }, # I hate .tar.gz
    macro         => { TARFLAGS => "--format=ustar -c -v -f",
		       },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

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
	'tgzdist:	doc checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/VCS-SCCS.md doc/VCS-SCCS.html doc/VCS-SCCS.man',
	'doc/VCS-SCCS.md:	SCCS.pm',
	'	pod2markdown  < $? > $@',
	'doc/VCS-SCCS.html:	SCCS.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/VCS-SCCS.3:	SCCS.pm',
	'	pod2man       < $? > $@',
	'doc/VCS-SCCS.man:	doc/VCS-SCCS.3',
	'	nroff -mandoc < $? > $@',
	'';
    } # postamble

1;
