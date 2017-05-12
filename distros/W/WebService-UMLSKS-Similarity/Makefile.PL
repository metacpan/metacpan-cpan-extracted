use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::UMLSKS::Similarity',
    AUTHOR              => q{Mugdha Choudhari <choudhary.mugdha@gmail.com> , Ted Pedersen <tpederse@d.umn.edu>},
    VERSION_FROM        => 'lib/WebService/UMLSKS/Similarity.pm',
    ABSTRACT_FROM       => 'lib/WebService/UMLSKS/Similarity.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {'SOAP::Lite' => 0.710,
        'Test::More' => 0,
	'Crypt::SSLeay' => 0,
    },
    EXE_FILES           => [("bin/ws-getUMLSInfo.pl", "bin/ws-getAllowablePath.pl", "bin/ws-sample.pl","bin/ws-test.pl")],	
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-UMLSKS-Similarity-*' },
);
