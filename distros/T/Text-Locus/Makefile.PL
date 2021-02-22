use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME              => 'Text::Locus',
    VERSION_FROM      => 'lib/Text/Locus.pm',
    ABSTRACT_FROM     => 'lib/Text/Locus.pm',
    LICENSE           => 'gpl_3',
    AUTHOR            => 'Sergey Poznyakoff <gray@gnu.org>',
    MIN_PERL_VERSION  => 5.006,
    PREREQ_PM         => {
	'Carp'            => 0,
	'Clone'           => 0,
        'Scalar::Util'    => 0,
    },
    META_MERGE        => {
	'meta-spec' => { version => 2 },
        resources => {
	    repository => {
		type => 'git',
                url => 'git://git.gnu.org.ua/text-locus.git',
		web => 'http://git.gnu.org.ua/cgit/text-locus.git/',
	    },
	    bugtracker => {
	        web => 'https://puszcza.gnu.org.ua/bugs/?group=text-locus',
		mailto => 'gray+text-locus@gnu.org.ua'
	    }
	},
	provides => Module::Metadata->provides(version => '1.4',
					       dir => 'lib')
    }    
);

    
    
