# $Id: Makefile.PL 251926 2009-01-20 15:24:15Z pixel $

use strict;
use ExtUtils::MakeMaker;

my $rpmtools_version = "7.11";

# where to find the rpm utility

sub MY::postamble {
    <<MAKEMAKEFILE;
cleanc:
	rm -rf *.cz test

MAKEMAKEFILE
}

WriteMakefile(
    NAME	    => 'rpmtools',
    ABSTRACT	    => 'Generates hdlist and synthesis files + compatibility wrapper around the new MDV::Packdrakeng',
    VERSION	    => $rpmtools_version,
    LICENSE		=> 'gpl_2',
    macro => {
        RPMTOOLSVERSION => $rpmtools_version,
    },
    depend => {
        clean_subdirs => 'cleanc',
    },
    PM => {
        'packdrake.pm' => '$(INST_LIBDIR)/packdrake.pm',
        'rpmtools.pm'  => '$(INST_LIBDIR)/rpmtools.pm',
    },
    EXE_FILES	    => [ qw(gendistrib genhdlist2 packdrake dumpdistribconf) ],
    C		    => [],
    OBJECT	    => '',
    CCFLAGS	    => '-Wall',
    INC		    => '',
    LIBS	    => [ '' ],
    PREREQ_PM		=> {
	'ExtUtils::MakeMaker'	=> '0',
	'Getopt::Long'		=> '0',
	'List::Util'		=> '1.33',
	'MDV::Distribconf'	=> '4.100',
	'MDV::Packdrakeng'	=> '1.13',
	'Pod::Usage'		=> '0',
	'Term::ReadLine'	=> '0',
	'Text::ParseWords'	=> '0',
	'URPM'			=> '5.16',
    },
    'TEST_REQUIRES' => {
	'Digest::MD5'		=> '0',
	'Test::More'		=> '0',
    },
    MAN1PODS	    => {
	dumpdistribconf	=> '$(INST_MAN1DIR)/dumpdistribconf.1',
	gendistrib	=> '$(INST_MAN1DIR)/gendistrib.1',
	genhdlist2	=> '$(INST_MAN1DIR)/genhdlist2.1',
	packdrake	=> '$(INST_MAN1DIR)/packdrake.1',
    },
    MAN3PODS	    => {},
    dist	    => {
        COMPRESS => 'xz -f --best --text',
        SUFFIX => '.xz',
    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
	  "meta-spec" => { version => 2 },
            resources => {
                repository  => {
		    type => 'git',
		    url => 'git://git.mageia.org/software/rpm/rpmtools/',
		    web =>  'http://gitweb.mageia.org/software/rpm/rpmtools/',
		},
            },
	    release_status => 'stable',
	    # For proper CPAN indexation:
	    provides => {
		'rpmtools' => {
		    file => 'packdrake.pm',
		    version => $rpmtools_version,
		},
	    },
        } ) : ()
    ),
);
