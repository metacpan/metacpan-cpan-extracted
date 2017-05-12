use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Salesforce::Report',
    AUTHOR              => q{Pedro Paixao <paixaop@gmail.com>},
    VERSION_FROM        => 'lib/WWW/Salesforce/Report.pm',
    ABSTRACT_FROM       => 'lib/WWW/Salesforce/Report.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'HTTP::Cookies'         => 0,
        'HTTP::Headers'         => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent'        => 0,
        'Digest::MD5'           => 0,
        'IO::Compress::Zip'     => 0,
        'DBI'                   => 0,
        'Carp'                  => 0,
        'File::Spec'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Salesforce-Report-*' },
);
