use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Phanfare::API',
    AUTHOR              => q{Soren Dossing <netcom@sauber.net>},
    VERSION_FROM        => 'lib/WWW/Phanfare/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/Phanfare/API.pm',
    ($ExtUtils::MakeMaker::VERSION gt 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::HomeDir' => 0,
        'Config::General' => 0,
        'REST::Client' => 0,
        'Digest::MD5' => 0,
        'XML::Simple' => 0,
        'URI::Escape' => 0,
        'File::Slurp' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Phanfare-API-*' },
);
