use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WebService::Geograph::API',
    VERSION_FROM => 'lib/WebService/Geograph/API.pm', # finds \$VERSION
    AUTHOR       => 'Spiros Denaxas (s [dot] denaxas [@] gmail [dot]com)',
    ABSTRACT     => 'Perl interface to the Geograph.co.uk API',
    PREREQ_PM    => {
                     'Test::Simple'   => 0.44,
										 'LWP::UserAgent' => 2.033,
										 'HTTP::Request'  => 1.40,
										 'Date::Simple'   => 3.02,
										 'URI'            => 1.35,
										 'HTTP::Response' => 1.53,
 										 
                    },
);
