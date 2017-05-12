use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WebService::30Boxes::API',
    VERSION_FROM => 'lib/WebService/30Boxes/API.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Perl interface to the 30 Boxes API',
    PREREQ_PM    => {
                     'HTTP::Request' => 0,
                     'HTTP::Response' => 0,
                     'LWP::UserAgent' => 0,
                     'Test::Simple' => 0.44,
                     'URI' => 0,
                     'XML::Simple' => 0,
                    },
);
