use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::Tagzania::API',
    VERSION_FROM => 'lib/WebService/Tagzania/API.pm', 
    AUTHOR       => 'Spiros Denaxas (s [dot] denaxas [@] gmail [dot]com)',
    ABSTRACT     => 'Tagzania API Interface',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
										 'LWP::UserAgent'  => 2.033,
										 'HTTP::Request'   => 1.40,
										 'URI'             => 1.35,
 										 'HTTP::Response'  => 1.53,
 										 'Test::Exception' => 0.24,
                    },
);
