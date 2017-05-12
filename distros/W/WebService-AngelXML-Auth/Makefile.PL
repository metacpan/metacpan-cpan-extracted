use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'WebService::AngelXML::Auth',
    VERSION_FROM => 'lib/WebService/AngelXML/Auth.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Interface to the AngleXML authentication WebService',
    PREREQ_PM    => {
                     'Test::More'   => 0,
                     'Test::XML'    => 0,
                     'strict'       => 0,
                     'XML::Writer'  => 0,
                     'CGI'          => 0,
                    },
);
