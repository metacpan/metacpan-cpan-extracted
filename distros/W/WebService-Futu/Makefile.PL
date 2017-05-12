use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Futu',
    AUTHOR              => q{Vaclav Dovrtel <vaclav.dovrtel@gmail.com>},
    VERSION_FROM        => 'lib/WebService/Futu.pm',
    ABSTRACT_FROM       => 'lib/WebService/Futu.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'LWP::UserAgent' => 0,
		'JSON::XS' => 0,
		'HTTP::Status' => 0,
		'HTTP::Cookies' => 0,
		'Data::Dumper' => 0
		
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Futu-*' },
);
