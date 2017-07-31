#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
    NAME              => 'Text::Names::GB',
    VERSION_FROM      => 'lib/Text/Names/GB.pm', # finds $VERSION
    PL_FILES            => {},
    TEST_REQUIRES => {
        'Test::More' => 0.96
    },
    PREREQ_PM         => {
        'Text::Capitalize' => 1.1,
        'Text::LevenshteinXS' => 0.03,
        'Text::Names' => 0,
    }, # e.g., Module::Name => 1.1
    LICENSE => 'perl_5',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Names/GB.pm', # retrieve abstract from module
       AUTHOR         => 'Nigel Horne <njh@bandsman.co.uk>') : ()),
    ($ExtUtils::MakeMaker::VERSION < 6.46
      ? ()
      : ( META_MERGE  => {
              resources => {
                  repository => 'https://github.com/nigelhorne/Text-Names-GB',
              },
          },
        )
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Names-GB-* t/online.enabled' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Text-Names-GB.git',
			web => 'https://github.com/nigelhorne/Text-Names-GB',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.0'	# Probably would work, but never tested on earlier versions than this
);
