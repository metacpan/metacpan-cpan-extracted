use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VR-API',
    VERSION_FROM      => 'lib/VR/API.pm',
    PREREQ_PM         => {
        'SOAP::Lite' => 0.60,
        'Crypt::SSLeay' => 0.51,
    },
    ABSTRACT => 'A perl client for the VerticalResponse.com API (http://www.verticalresponse.com/api)',
    AUTHOR => 'Nick Marden <nick@verticalresponse.com>',
);
