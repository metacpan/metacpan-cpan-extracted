use 5.010000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::WWW::WebKit::Catalyst',
    VERSION_FROM      => 'lib/Test/WWW/WebKit/Catalyst.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::WWW::WebKit'      => 0.03,
        'Test::More'             => 0,
        'IO::Socket::INET'       => 0,
        'Catalyst::EngineLoader' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/WWW/WebKit/Catalyst.pm', # retrieve abstract from module
       AUTHOR         => 'Stefan Seifert <nine@cpan.org>') : ()),
);
