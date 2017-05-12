use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::ClinicalTrialsdotGov',
    AUTHOR              => 'Spiros Denaxas <s.denaxas@gmail.com>',
    VERSION_FROM        => 'lib/WebService/ClinicalTrialsdotGov.pm',
    ABSTRACT_FROM       => 'lib/WebService/ClinicalTrialsdotGov.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'Test::More'      => 0,
        'XML::Simple'     => 0,
        'Carp'            => 0,
        'LWP::UserAgent'  => 0,
        'URI'             => 0,
        'HTTP::Request'   => 0,
        'Clone'           => 0        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-ClinicalTrialsdotGov-*' },
);
