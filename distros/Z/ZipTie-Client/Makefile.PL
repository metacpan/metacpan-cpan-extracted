use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZipTie::Client',
    DISTNAME            => 'ZipTie-Client',
    AUTHOR              => 'Leo Bayer <lbayer@ziptie.org>',
    VERSION_FROM        => 'lib/ZipTie/Client.pm',
    ABSTRACT_FROM       => 'lib/ZipTie/Client.pm',
    PREREQ_PM           => {
                             'Carp' => '0',
                             'HTTP::Cookies' => '0',
                             'SOAP::Lite' => '0.69', 
                           },
);
