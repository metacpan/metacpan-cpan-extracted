use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'WWW::Scrape::FindaGrave',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/WWW/Scrape/FindaGrave.pm',
    ABSTRACT_FROM       => 'lib/WWW/Scrape/FindaGrave.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::URI' => 0,
	# 'Test::Kwalitee' => 0,
    },
    PREREQ_PM => {
	'WWW::Mechanize::GZip' => 0,
	'LWP::UserAgent' => 0,
	'HTML::SimpleLinkExtor' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'WWW-Scrape-FindaGrave-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/WWW-Scrape-FindaGrave.git',
			web => 'https://github.com/nigelhorne/WWW-Scrape-FindaGrave',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
