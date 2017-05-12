use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'neverbounce',
    AUTHOR           => q{Manu Mathew <whitewind@cpan.org>},
    VERSION_FROM     => 'lib/neverbounce.pm',
    ABSTRACT_FROM    => 'lib/neverbounce.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM => {
        'Test::Manifest'        =>  '0.9',
        'Test::More'            =>  0,
		'Data::Dumper'	        =>	0,
		'Convert::Base64'	    =>	0,
		'HTTP::Request::Common' =>	0,
		'LWP::UserAgent'	    =>	0,
		'JSON'	                =>	0,
		'LWP::Protocol::https'	=>	0
    },
    clean => { FILES => 'neverbounce-*' },
);
