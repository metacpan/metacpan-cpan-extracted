#!/usr/bin/perl

use 5.014000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME           => "V",
    VERSION_FROM   => "lib/V.pm",
    ABSTRACT_FROM  => "lib/V.pm",
    AUTHOR         => 'H.Merijn Brand <hmbrand@cpan.org>',

    TEST_REQUIRES => {
	"Test::Simple"   => 0.88,
	"Test::Fatal"    => 0,
	"Test::Warnings" => 0,
	},
    PREREQ_PM => {
	version          => 0.77,
	},
    macro => {
	TARFLAGS => "--format=ustar -c -v -f",
	},

    MIN_PERL_VERSION     => "5.010001",
    LICENSE              => "perl_5",
    META_ADD             => {
	"meta-spec"      => {
	    version      => 2,
	    },
	"resources"      => {
	    homepage     => "https://github.com/Tux/V",
	    repository   => {
		type     => "git",
		url      => "https://github.com/Tux/V.git",
		},
	    bugtracker   => {
		web      => "https://github.com/Tux/V/issues",
		},
	    x_IRC        => 'irc://irc.perl.org/#csv',
	    },
	},
    );

1;

package MY;

sub postamble {
    my $do_xt = (-d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    '	-perl doc/make-doc.pl',
	    ''
	: "";
    join "\n" =>
	'cover $make_sep test_cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	'	cover -report html_basic',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
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
	'	-@echo "Consider running sandbox/used-by.pl now"',
	'',
	'test_used:	test',
	'	prove -vwb sandbox/used-by.pl',
	'',
	'doc docs:',
	'	perl doc/make-doc.pl',
	'',
	$do_xt;
    } # postamble
